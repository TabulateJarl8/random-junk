import os
import sys
import requests
from rich.console import Console
from rich.table import Table
from rich.text import Text

RATING_DICT = {
	"borked": 0,
	"unknown": 1,
	"pending": 1,
	"bronze": 2,
	"silver": 3,
	"gold": 4,
	"platinum": 5,
}

RATING_COLORS = {
	"borked": "red",
	"unknown": "blue",
	"pending": "blue",
	"bronze": "#CD7F32",
	"silver": "#A6A6A6",
	"gold": "#CFB53B",
	"platinum": "#B4C7DC",
}


def get_game_average_rating(id: str) -> str:
	data = requests.get(f"https://www.protondb.com/api/v1/reports/summaries/{id}.json")
	if data.status_code != 200 or "tier" not in data.json():
		return "unknown"
	else:
		return data.json()["tier"]


def main(id: str):
	data = requests.get(
		f'http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key={os.environ.get("API")}&steamid={id}&format=json&include_appinfo=1'
	)
	if "Bad Request" in data.text:
		return "Unknown steam id"
	elif "Unauthorized" in data.text:
		return "Unauthorized"

	games = data.json()["response"]["games"]
	game_ratings = [
		{
			"name": game["name"],
			"rating": get_game_average_rating(game["appid"]),
			"playtime": game["playtime_forever"],
		}
		for game in games
	]

	game_ratings.sort(key=lambda x: x["playtime"])
	game_ratings.reverse()

	# compute user average
	game_rating_nums = [RATING_DICT[game["rating"]] for game in game_ratings]
	user_average = round(sum(game_rating_nums) / len(game_rating_nums))
	user_average_text = [
		key for key, value in RATING_DICT.items() if value == user_average
	][0]

	table = Table(title="Game Compatibility")
	table.add_column("Title", style="dim green")
	table.add_column("Compatibility")

	for game in game_ratings:
		table.add_row(
			game["name"],
			Text(game["rating"].capitalize(), style=RATING_COLORS[game["rating"]]),
		)

	console = Console()
	console.print(table)

	text = Text.assemble(
		"Average User Rating: ",
		(user_average_text.capitalize(), RATING_COLORS[user_average_text]),
	)
	console.print(text)

	return user_average_text


if __name__ == "__main__":
	main(sys.argv[1])
