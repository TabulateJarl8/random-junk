// This utility scans all of your local git projects to find the largest commit
// you've ever made. Don't just the code because it's mostly cobbled together
// from various LLMs since I was too lazy to write this myself
//
// gcc -o find_largest_commit find-largest-commit.c -lgit2 -lpthread

#include <dirent.h>
#include <getopt.h>
#include <git2.h>
#include <git2/commit.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX_PATH 4096
#define DEFAULT_NUM_WORKERS 12
#define DEFAULT_TOP_N 3
#define MAX_FILTERS 100
#define MAX_EXCLUSIONS 1000

typedef struct {
  char repo_path[MAX_PATH];
  char commit_hash[41];
  int additions;
} CommitInfo;

typedef struct RepoNode {
  char path[MAX_PATH];
  struct RepoNode *next;
} RepoNode;

typedef struct {
  RepoNode *head;
  pthread_mutex_t lock;
} RepoQueue;

typedef struct {
  char **email_filters;
  int email_filter_count;
  char **excluded_hashes;
  int excluded_hash_count;
  char *base_path;
  int num_workers;
  int top_n;
} Config;

RepoQueue queue = {NULL, PTHREAD_MUTEX_INITIALIZER};
CommitInfo *global_biggest = NULL;
pthread_mutex_t global_lock = PTHREAD_MUTEX_INITIALIZER;
volatile char **current_repo = NULL;
Config config = {NULL, 0, NULL, 0, NULL, DEFAULT_NUM_WORKERS, DEFAULT_TOP_N};

volatile int repos_done = 0;
int repos_total = 0;
pthread_mutex_t print_lock = PTHREAD_MUTEX_INITIALIZER;

void print_usage(const char *program_name) {
  printf("Usage: %s [OPTIONS]\n", program_name);
  printf("Options:\n");
  printf("  -e, --email EMAIL     Email filter (can be used multiple times)\n");
  printf("  -x, --exclude HASH    Exclude commit hash (can be used multiple "
         "times)\n");
  printf("  -p, --path PATH       Base path to search (default: ~/src)\n");
  printf("  -w, --workers NUM     Number of worker threads (default: %d)\n",
         DEFAULT_NUM_WORKERS);
  printf(
      "  -n, --top NUM         Number of top commits to show (default: %d)\n",
      DEFAULT_TOP_N);
  printf("  -h, --help           Show this help message\n");
  printf("\nExample:\n");
  printf("  %s -e user1@example.com -e user2@example.com -x abc123 -x def456 "
         "-w 8 -n 5\n",
         program_name);
}

int is_hash_excluded(const char *hash) {
  for (int i = 0; i < config.excluded_hash_count; i++) {
    if (strncmp(hash, config.excluded_hashes[i],
                strlen(config.excluded_hashes[i])) == 0) {
      return 1;
    }
  }
  return 0;
}

void add_email_filter(const char *email) {
  config.email_filters = realloc(
      config.email_filters, (config.email_filter_count + 1) * sizeof(char *));
  config.email_filters[config.email_filter_count] = strdup(email);
  config.email_filter_count++;
}

void add_excluded_hash(const char *hash) {
  config.excluded_hashes =
      realloc(config.excluded_hashes,
              (config.excluded_hash_count + 1) * sizeof(char *));
  config.excluded_hashes[config.excluded_hash_count] = strdup(hash);
  config.excluded_hash_count++;
}

void parse_args(int argc, char **argv) {
  int opt;
  static struct option long_options[] = {{"email", required_argument, 0, 'e'},
                                         {"exclude", required_argument, 0, 'x'},
                                         {"path", required_argument, 0, 'p'},
                                         {"workers", required_argument, 0, 'w'},
                                         {"top", required_argument, 0, 'n'},
                                         {"help", no_argument, 0, 'h'},
                                         {0, 0, 0, 0}};

  while ((opt = getopt_long(argc, argv, "e:x:p:w:n:h", long_options, NULL)) !=
         -1) {
    switch (opt) {
    case 'e':
      add_email_filter(optarg);
      break;
    case 'x':
      add_excluded_hash(optarg);
      break;
    case 'p':
      config.base_path = strdup(optarg);
      break;
    case 'w':
      config.num_workers = atoi(optarg);
      if (config.num_workers <= 0) {
        fprintf(stderr, "Error: Number of workers must be positive\n");
        exit(1);
      }
      break;
    case 'n':
      config.top_n = atoi(optarg);
      if (config.top_n <= 0) {
        fprintf(stderr, "Error: Number of top commits must be positive\n");
        exit(1);
      }
      break;
    case 'h':
      print_usage(argv[0]);
      exit(0);
    default:
      print_usage(argv[0]);
      exit(1);
    }
  }

  // Set default email filters if none provided
  if (config.email_filter_count == 0) {
    add_email_filter("tabulatejarl8@gmail.com");
    add_email_filter("samplejc@dukes.jmu.edu");
  }

  // Set default base path if none provided
  if (!config.base_path) {
    const char *home = getenv("HOME");
    if (!home) {
      fprintf(stderr, "HOME not set and no path provided\n");
      exit(1);
    }
    char default_path[MAX_PATH];
    snprintf(default_path, sizeof(default_path), "%s/src", home);
    config.base_path = strdup(default_path);
  }
}

void cleanup_config() {
  for (int i = 0; i < config.email_filter_count; i++) {
    free(config.email_filters[i]);
  }
  free(config.email_filters);

  for (int i = 0; i < config.excluded_hash_count; i++) {
    free(config.excluded_hashes[i]);
  }
  free(config.excluded_hashes);

  free(config.base_path);

  if (global_biggest) {
    free(global_biggest);
  }

  if (current_repo) {
    for (int i = 0; i < config.num_workers; i++) {
      free((void *)current_repo[i]);
    }
    free(current_repo);
  }
}

void enqueue_repo(const char *path) {
  RepoNode *node = malloc(sizeof(RepoNode));
  strncpy(node->path, path, MAX_PATH);
  node->next = NULL;

  pthread_mutex_lock(&queue.lock);
  node->next = queue.head;
  queue.head = node;
  repos_total++;
  pthread_mutex_unlock(&queue.lock);
}

int dequeue_repo(char *out) {
  pthread_mutex_lock(&queue.lock);
  if (!queue.head) {
    pthread_mutex_unlock(&queue.lock);
    return 0; // empty
  }
  RepoNode *node = queue.head;
  queue.head = node->next;
  pthread_mutex_unlock(&queue.lock);

  strncpy(out, node->path, MAX_PATH);
  free(node);
  return 1;
}

void *spinner(void *arg) {
  const char spin_chars[] = "|/-\\";
  int spin_idx = 0;

  while (1) {
    pthread_mutex_lock(&print_lock);

    printf("\033[H"); // move cursor to top-left (if using multi-line)
    printf("\033[J"); // clear screen below

    printf("[%c] Progress: %d / %d\n", spin_chars[spin_idx], repos_done,
           repos_total);

    for (int i = 0; i < config.num_workers; i++) {
      if (current_repo[i][0] != '\0') {
        printf("  Thread %d: Processing %-60s\n", i, current_repo[i]);
      } else {
        printf("  Thread %d: Idle\n", i);
      }
    }

    fflush(stdout);
    pthread_mutex_unlock(&print_lock);

    if (repos_done >= repos_total)
      break;

    spin_idx = (spin_idx + 1) % 4;
    usleep(100000); // 100ms
  }

  pthread_mutex_lock(&print_lock);
  printf("\033[32m[✔] All done! Processed %d repos.\033[0m\n", repos_total);
  fflush(stdout);
  pthread_mutex_unlock(&print_lock);

  return NULL;
}

void find_git_repos(const char *base) {
  DIR *dir = opendir(base);
  if (!dir)
    return;

  struct dirent *entry;
  while ((entry = readdir(dir))) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
      continue;

    char path[MAX_PATH];
    snprintf(path, sizeof(path), "%s/%s", base, entry->d_name);

    struct stat st;
    if (stat(path, &st) == -1)
      continue;

    if (S_ISDIR(st.st_mode)) {
      char git_dir[MAX_PATH];
      snprintf(git_dir, sizeof(git_dir), "%s/.git", path);
      if (stat(git_dir, &st) == 0) {
        enqueue_repo(path);
      } else {
        find_git_repos(path);
      }
    }
  }

  closedir(dir);
}

int is_merge_commit(git_commit *commit) {
  return git_commit_parentcount(commit) > 1;
}

int is_initial_commit(git_commit *commit) {
  return git_commit_parentcount(commit) == 0;
}

int count_additions(git_repository *repo, git_commit *commit) {
  if (is_initial_commit(commit))
    return 0;

  git_diff *diff = NULL;
  git_tree *parent_tree = NULL, *this_tree = NULL;
  git_commit *parent_commit = NULL;

  int error = 0;

  error = git_commit_tree(&this_tree, commit);
  if (error < 0)
    goto cleanup;

  error = git_commit_parent(&parent_commit, commit, 0);
  if (error < 0)
    goto cleanup;

  error = git_commit_tree(&parent_tree, parent_commit);
  if (error < 0)
    goto cleanup;

  error = git_diff_tree_to_tree(&diff, repo, parent_tree, this_tree, NULL);
  if (error < 0)
    goto cleanup;

  int additions = 0;
  git_diff_stats *stats;
  if (git_diff_get_stats(&stats, diff) == 0) {
    additions = git_diff_stats_insertions(stats);
    git_diff_stats_free(stats);
  }

cleanup:
  if (parent_commit)
    git_commit_free(parent_commit);
  if (parent_tree)
    git_tree_free(parent_tree);
  if (this_tree)
    git_tree_free(this_tree);
  if (diff)
    git_diff_free(diff);

  return error < 0 ? 0 : additions;
}

void update_top_commits(CommitInfo *local_biggest) {
  if (local_biggest->additions == 0)
    return;

  pthread_mutex_lock(&global_lock);

  // Find the position to insert
  int insert_pos = -1;
  for (int i = 0; i < config.top_n; i++) {
    if (local_biggest->additions > global_biggest[i].additions) {
      insert_pos = i;
      break;
    }
  }

  if (insert_pos != -1) {
    // Shift commits down
    for (int i = config.top_n - 1; i > insert_pos; i--) {
      global_biggest[i] = global_biggest[i - 1];
    }
    // Insert new commit
    global_biggest[insert_pos] = *local_biggest;
  }

  pthread_mutex_unlock(&global_lock);
}

void scan_repo(const char *repo_path) {
  git_repository *repo = NULL;
  if (git_repository_open(&repo, repo_path) < 0)
    return;

  git_revwalk *walker = NULL;
  git_revwalk_new(&walker, repo);
  git_revwalk_push_head(walker);
  git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL | GIT_SORT_TIME);

  CommitInfo local_biggest = {"", "", 0};

  git_oid oid;
  while (!git_revwalk_next(&oid, walker)) {
    git_commit *commit = NULL;
    if (git_commit_lookup(&commit, repo, &oid) < 0)
      continue;

    if (is_merge_commit(commit) || is_initial_commit(commit)) {
      git_commit_free(commit);
      continue;
    }

    // Check if commit hash is excluded
    const char *commit_hash = git_oid_tostr_s(&oid);
    if (is_hash_excluded(commit_hash)) {
      git_commit_free(commit);
      continue;
    }

    // filter by author
    const git_signature *author = git_commit_author(commit);
    if (!author) {
      git_commit_free(commit);
      continue;
    }

    int matched = 0;
    for (int i = 0; i < config.email_filter_count; i++) {
      if (strstr(author->email, config.email_filters[i]) != NULL) {
        matched = 1;
        break;
      }
    }

    if (!matched) {
      git_commit_free(commit);
      continue;
    }

    int added = count_additions(repo, commit);
    if (added > local_biggest.additions) {
      snprintf(local_biggest.repo_path, MAX_PATH, "%s", repo_path);
      snprintf(local_biggest.commit_hash, 41, "%s", commit_hash);
      local_biggest.additions = added;
    }

    git_commit_free(commit);
  }

  git_revwalk_free(walker);
  git_repository_free(repo);

  // update global top commits
  update_top_commits(&local_biggest);
}

void *worker(void *arg) {
  int thread_id = *(int *)arg;
  char repo[MAX_PATH];
  while (dequeue_repo(repo)) {
    pthread_mutex_lock(&print_lock);
    snprintf((char *)current_repo[thread_id], MAX_PATH, "%s", repo);
    pthread_mutex_unlock(&print_lock);

    scan_repo(repo);

    pthread_mutex_lock(&print_lock);
    current_repo[thread_id][0] = '\0'; // clear when done
    repos_done++;
    pthread_mutex_unlock(&print_lock);
  }
  return NULL;
}

int main(int argc, char **argv) {
  parse_args(argc, argv);

  // Initialize dynamic arrays based on configuration
  global_biggest = calloc(config.top_n, sizeof(CommitInfo));
  current_repo = malloc(config.num_workers * sizeof(char *));
  for (int i = 0; i < config.num_workers; i++) {
    current_repo[i] = calloc(MAX_PATH, sizeof(char));
  }

  git_libgit2_init();

  printf("Configuration:\n");
  printf("  Base path: %s\n", config.base_path);
  printf("  Workers: %d\n", config.num_workers);
  printf("  Top commits: %d\n", config.top_n);
  printf("  Email filters: ");
  for (int i = 0; i < config.email_filter_count; i++) {
    printf("%s%s", config.email_filters[i],
           i < config.email_filter_count - 1 ? ", " : "");
  }
  printf("\n");

  if (config.excluded_hash_count > 0) {
    printf("  Excluded hashes: ");
    for (int i = 0; i < config.excluded_hash_count; i++) {
      printf("%s%s", config.excluded_hashes[i],
             i < config.excluded_hash_count - 1 ? ", " : "");
    }
    printf("\n");
  }
  printf("\n");

  find_git_repos(config.base_path);

  if (repos_total == 0) {
    printf("No git repositories found in %s\n", config.base_path);
    cleanup_config();
    git_libgit2_shutdown();
    return 0;
  }

  pthread_t spinner_thread;
  pthread_create(&spinner_thread, NULL, spinner, NULL);

  pthread_t *threads = malloc(config.num_workers * sizeof(pthread_t));
  int *ids = malloc(config.num_workers * sizeof(int));
  for (int i = 0; i < config.num_workers; i++) {
    ids[i] = i;
    pthread_create(&threads[i], NULL, worker, &ids[i]);
  }

  for (int i = 0; i < config.num_workers; i++) {
    pthread_join(threads[i], NULL);
  }

  pthread_join(spinner_thread, NULL);

  printf("\nTop %d biggest commits:\n", config.top_n);
  for (int i = 0; i < config.top_n; i++) {
    if (global_biggest[i].additions > 0) {
      printf("%d. Repo: %s\n", i + 1, global_biggest[i].repo_path);
      printf("   Commit: %s\n", global_biggest[i].commit_hash);
      printf("   Additions: %d\n\n", global_biggest[i].additions);
    }
  }

  free(threads);
  free(ids);
  cleanup_config();
  git_libgit2_shutdown();
  return 0;
}
