import re


def get_numbers(string: str) -> int:
	num_dict = {
		"one": "1",
		"two": "2",
		"three": "3",
		"four": "4",
		"five": "5",
		"six": "6",
		"seven": "7",
		"eight": "8",
		"nine": "9",
	}
	numbers = "|".join(num_dict.keys())

	r = re.findall(r"(?=(\d|" + numbers + "))", string)

	match1 = num_dict.get(r[0], r[0])
	match2 = num_dict.get(r[-1], r[-1])

	if len(r) == 1:
		return int(match1 * 2)
	else:

		return int(match1 + match2)


def main(filename):
	with open(filename) as f:
		data = f.readlines()

	numbers = [get_numbers(line) for line in data]
	return sum(numbers)


if __name__ == "__main__":
	print(main("input.txt"))
