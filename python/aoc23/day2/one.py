from dataclasses import dataclass
import re


@dataclass
class Colors:
	red: int
	green: int
	blue: int

	def __gt__(self, other: "Colors"):
		return (
			self.red > other.red or self.green > other.green or self.blue > other.blue
		)


@dataclass
class Game:
	id: int
	colors: list[Colors]

	@staticmethod
	def parse_line(line) -> "Game":
		id = int(re.match(r"Game (\d+)", line).group(1))
		matches = line.split(": ")[1].split("; ")

		colors = []
		for game in matches:
			red = re.search(r"(\d+)\s+red", game)
			green = re.search(r"(\d+)\s+green", game)
			blue = re.search(r"(\d+)\s+blue", game)

			if red is None:
				red = 0
			else:
				red = red.group(1)

			if green is None:
				green = 0
			else:
				green = green.group(1)

			if blue is None:
				blue = 0
			else:
				blue = blue.group(1)

			colors.append(Colors(red=int(red), green=int(green), blue=int(blue)))

		return Game(id=id, colors=colors)

	def max(self):
		return max(self.colors)


def main(filename: str):
	with open(filename) as f:
		data = f.readlines()

	games = [Game.parse_line(line) for line in data]
	constraints = Colors(red=12, green=13, blue=14)

	# calculate valid games
	valid = 0
	for game in games:
		if not any(gamecolors > constraints for gamecolors in game.colors):
			valid += game.id

	return valid


if __name__ == "__main__":
	print(main("input.txt"))
