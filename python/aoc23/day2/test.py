from collections import defaultdict

p1, p2 = 0, 0
for i, game in enumerate(open("input.txt"), start=1):
	_, game = game.split(":")
	bag = defaultdict(int)
	for color in game.split(";"):
		for part in color.split(","):
			count, color = part.split()
			bag[color] = max(int(count), bag[color])

	if bag["red"] <= 12 and bag["green"] <= 13 and bag["blue"] <= 14:
		print(i)
		p1 += i
	p2 += bag["red"] * bag["green"] * bag["blue"]

print("p1", p1)
print("p2", p2)
