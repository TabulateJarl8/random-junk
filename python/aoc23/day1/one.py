def get_first_number(string: str) -> str:
	for char in string:
		if char.isnumeric():
			return char

	return ""


def main(filename):
	with open(filename) as f:
		data = f.readlines()

	numbers = [
		int(get_first_number(line) + get_first_number(line[::-1])) for line in data
	]
	return sum(numbers)


if __name__ == "__main__":
	print(main("input.txt"))
