/* Implementation of a max heap */
#include "max_heap.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int *init_array() { return (int *)calloc(ARR_SIZE, sizeof(int)); }

bool in_bounds(int pos) { return pos >= 0 && pos < ARR_SIZE; }

int parent_index(int pos) {
  return pos != 0 && in_bounds(pos) ? (int)(pos - 1) / 2 : -1;
}

int left_child_index(int pos) {
  int val = 2 * pos + 1;
  return val < ARR_SIZE && in_bounds(pos) ? val : -1;
}

int right_child_index(int pos) {
  int val = 2 * pos + 2;
  return val < ARR_SIZE && in_bounds(pos) ? val : -1;
}

int left_sibling_index(int pos) {
  return pos % 2 == 0 && pos != 0 && in_bounds(pos) ? pos - 1 : -1;
}

int right_sibling_index(int pos) {
  return pos % 2 != 0 && pos + 1 < ARR_SIZE && in_bounds(pos) ? pos + 1 : -1;
}

bool is_leaf(int pos, size_t items_in_array) {
  return (int)items_in_array / 2 <= pos && pos < items_in_array;
}

void modify(int *arr, int pos, int new_val, int items_in_arr) {
  arr[pos] = new_val;
  update(arr, pos, items_in_arr);
}

void swap(int *arr, int i, int j) {
  int x = arr[i];
  int y = arr[j];
  arr[i] = y;
  arr[j] = x;
}

void sift_up(int *arr, int pos) {
  while (pos > 0) {
    int parent = parent_index(pos);
    if (arr[parent] > arr[pos]) {
      return;
    }

    swap(arr, pos, parent);
    pos = parent;
  }
}

void sift_down(int *arr, int pos, int items_in_arr) {
  while (!is_leaf(pos, items_in_arr)) {
    int child = left_child_index(pos);
    if ((child + 1 < items_in_arr) && arr[child + 1] > arr[child]) {
      child++;
    }
    if (arr[child] <= arr[pos]) {
      return;
    }
    swap(arr, pos, child);
    pos = child;
  }
}

// insert a value into a minmax heap
void insert_into_heap(int *arr, int *items_in_arr, int val) {
  arr[*items_in_arr] = val;
  sift_up(arr, *items_in_arr);
  ++(*items_in_arr);
}

void build_heap(int *arr, int items_in_arr) {
  for (int i = parent_index(items_in_arr - 1); i >= 0; i--) {
    sift_down(arr, i, items_in_arr);
  }
}

// returns the item at the max index
int remove_max(int *arr, int *items_in_arr) {
  (*items_in_arr)--;
  swap(arr, 0, *items_in_arr);
  sift_down(arr, 0, *items_in_arr);
  return arr[*items_in_arr];
}

void update(int *arr, int pos, int items_in_arr) {
  sift_up(arr, pos);
  sift_down(arr, pos, items_in_arr);
}

int remove_index(int *arr, int pos, int *items_in_arr) {
  (*items_in_arr)--;
  swap(arr, pos, *items_in_arr);
  update(arr, pos, *items_in_arr);
  return arr[*items_in_arr];
}

void pretty_print_tree(int *arr, int items_in_arr) {
  if (items_in_arr == 0) {
    printf("Empty tree\n");
    return;
  }

  // Calculate the maximum height of the tree
  int height = 0;
  int temp = items_in_arr - 1;
  while (temp > 0) {
    temp = parent_index(temp);
    height++;
  }

  // Width of each value (assuming max 2 digits)
  const int value_width = 2;

  // For each level
  for (int level = 0; level <= height; level++) {
    int level_start = (1 << level) - 1;     // First node of current level
    int level_end = (1 << (level + 1)) - 1; // First node of next level

    // Print leading spaces for this level
    int spaces_before = ((1 << (height - level)) - 1) * (value_width + 1);
    for (int i = 0; i < spaces_before; i++) {
      printf(" ");
    }

    // Print nodes at this level
    for (int pos = level_start; pos < level_end && pos < items_in_arr; pos++) {
      printf("%2d", arr[pos]);

      // Print spaces between nodes at this level
      if (pos < level_end - 1 && pos + 1 < items_in_arr) {
        int spaces_between = (1 << (height - level + 1)) - 1;
        for (int i = 0; i < spaces_between * (value_width - 1); i++) {
          printf(" ");
        }
      }
    }
    printf("\n");

    // Don't print branches for the last level
    if (level < height) {
      // Print leading spaces before branches
      for (int i = 0; i < spaces_before - 1; i++) {
        printf(" ");
      }

      // Print branches
      for (int pos = level_start; pos < level_end && pos < items_in_arr;
           pos++) {
        if (left_child_index(pos) < items_in_arr) {
          printf("/");
        }
        printf(" ");
        if (right_child_index(pos) < items_in_arr) {
          printf("\\");
        } else {
          printf(" ");
        }

        // Spaces between sets of branches
        if (pos < level_end - 1 && pos + 1 < items_in_arr) {
          int spaces_between = (1 << (height - level + 1)) - 3;
          for (int i = 0; i < spaces_between; i++) {
            printf(" ");
          }
        }
      }
      printf("\n");
    }
  }
}

int main() {
  int *arr = init_array();

  int items_in_arr = 0; // Start with empty heap

  // First build a known heap to test with
  insert_into_heap(arr, &items_in_arr, 10); // Add some elements
  insert_into_heap(arr, &items_in_arr, 8);
  insert_into_heap(arr, &items_in_arr, 6);
  insert_into_heap(arr, &items_in_arr, 4);
  insert_into_heap(arr, &items_in_arr, 2);

  printf("Initial heap:\n"); // Should be: 10, 8, 6, 4, 2
  pretty_print_tree(arr, items_in_arr);

  // Test 1: remove_max
  printf("\nTest 1: remove_max\n");
  int max = remove_max(arr, &items_in_arr);
  printf("Removed max value: %d\n", max); // Should be 10
  printf("Heap after remove_max:\n");     // Should be: 8, 4, 6, 2
  pretty_print_tree(arr, items_in_arr);

  // Test 2: remove_index (remove a leaf)
  printf("\nTest 2: remove leaf node\n");
  int removed =
      remove_index(arr, 3, &items_in_arr); // Remove leaf node with value 2
  printf("Removed value at index 3: %d\n", removed);
  printf("Heap after removing leaf:\n"); // Should be: 8, 4, 6
  pretty_print_tree(arr, items_in_arr);

  // Test 3: remove_index (remove internal node)
  printf("\nTest 3: remove internal node\n");
  removed = remove_index(arr, 1, &items_in_arr); // Remove node with value 4
  printf("Removed value at index 1: %d\n", removed);
  printf("Heap after removing internal node:\n"); // Should be: 8, 6
  pretty_print_tree(arr, items_in_arr);

  // Reset heap for modification tests
  items_in_arr = 0;
  insert_into_heap(arr, &items_in_arr, 10);
  insert_into_heap(arr, &items_in_arr, 8);
  insert_into_heap(arr, &items_in_arr, 6);
  insert_into_heap(arr, &items_in_arr, 4);
  insert_into_heap(arr, &items_in_arr, 2);

  // Test 4: modify (increase value)
  printf("\nTest 4: modify - increase value\n");
  printf("Before increasing value at index 3:\n"); // Initial: 10, 8, 6, 4, 2
  pretty_print_tree(arr, items_in_arr);
  modify(arr, 3, 9, items_in_arr); // Increase 4 to 9
  printf(
      "After increasing value at index 3 to 9:\n"); // Should be: 10, 9, 6, 8, 2
  pretty_print_tree(arr, items_in_arr);

  // Test 5: modify (decrease value)
  printf("\nTest 5: modify - decrease value\n");
  modify(arr, 0, 3, items_in_arr);               // Decrease root from 10 to 3
  printf("After decreasing root value to 3:\n"); // Should be: 9, 8, 6, 3, 2
  pretty_print_tree(arr, items_in_arr);

  // Test 6: Edge cases
  printf("\nTest 6: Edge cases\n");

  // Test remove_max on heap with one element
  items_in_arr = 1;
  printf("Before remove_max on single-element heap:\n");
  pretty_print_tree(arr, items_in_arr);
  max = remove_max(arr, &items_in_arr);
  printf("Removed max: %d\n", max);
  printf("After remove_max (should be empty):\n");
  pretty_print_tree(arr, items_in_arr);

  // Test modify with same value
  insert_into_heap(arr, &items_in_arr, 5);
  printf("\nBefore modifying with same value:\n");
  pretty_print_tree(arr, items_in_arr);
  modify(arr, 0, 5, items_in_arr);
  printf("After modifying with same value (should be unchanged):\n");
  pretty_print_tree(arr, items_in_arr);
  free(arr);

  return 0;
}
