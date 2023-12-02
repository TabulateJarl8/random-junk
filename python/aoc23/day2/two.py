from one import Colors, Game


def main(filename: str):
	with open(filename) as f:
		data = f.readlines()

	games = [Game.parse_line(line) for line in data]
	constraints = Colors(red=12, green=13, blue=14)

	# calculate powers
	power = 0
	for game in games:
		maxred = max([color.red for color in game.colors])
		maxgreen = max([color.green for color in game.colors])
		maxblue = max([color.blue for color in game.colors])
		power += maxred * maxgreen * maxblue

	return power


if __name__ == "__main__":
	print(main("input.txt"))
