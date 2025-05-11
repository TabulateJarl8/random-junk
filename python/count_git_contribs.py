import subprocess


def count_authors_in_file(file: str) -> dict[str, int]:
    try:
        p = subprocess.run(
            ["git", "blame", "--line-porcelain", file], capture_output=True, text=True
        )
    except UnicodeDecodeError:
        return {}

    # gets the author name per line
    filtered_stdout = [
        line.split(" ", maxsplit=1)[1]
        for line in p.stdout.split("\n")
        if line.startswith("author ")
    ]

    return {user: filtered_stdout.count(user) for user in filtered_stdout}


def get_tracked_files():
    p = subprocess.run(["git", "ls-files"], capture_output=True, text=True)

    return [file for file in p.stdout.split("\n") if file]


def main():
    files = get_tracked_files()

    counts = {}
    for file in files:
        authors = count_authors_in_file(file)
        for author, lines in authors.items():
            if author in counts:
                counts[author] += lines
            else:
                counts[author] = lines

    print(counts)


if __name__ == "__main__":
    main()
