def check_invalid(row: str, index: int, include_current: bool):
	if index != 0:
		start = not row[index - 1].isnumeric() and row[index - 1] != '.'
	else:
		start = False

	if include_current:
		middle = not row[index].isnumeric() and row[index] != '.'
	else:
		middle = False

	try:
		end = not row[index + 1].isnumeric() and row[index + 1] != '.'
	except IndexError:
		end = False

	return start or middle or end


def main(filename):
	with open(filename) as f:
		data = [line.strip() for line in f.readlines()]

	total = 0
	for rowindex, row in enumerate(data):
		for charindex, char in enumerate(row):
			if char.isnumeric():
				# check characters directly next to digit
				if check_invalid(row, charindex, False):
					continue

				if rowindex != 0:
					if check_invalid(data[rowindex - 1], charindex, True):
						continue

				if rowindex < len(data) - 2:
					if check_invalid(data[rowindex + 1], charindex, True):
						continue

				total += int(char)

	print(total)

				


if __name__ == '__main__':
	main('test.txt')