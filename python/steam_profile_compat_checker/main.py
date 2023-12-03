import os
import sys
import requests
# from rich.console import Console
# from rich.table import Table
from rich.text import Text
from textual import on
from textual.app import App, ComposeResult
from textual.widgets import Header, Input, Button, DataTable
from textual.containers import Center, Container
from textual.validation import Regex

class InvalidIDError(Exception):
	pass

class UnauthorizedError(Exception):
	pass

RATING_DICT: dict[str, tuple[int, str]] = {
	"borked": (0, 'red'),
	"unknown": (1, 'blue'),
	"pending": (1, 'blue'),
	"bronze": (2, '#CD7F32'),
	"silver": (3, '#A6A6A6'),
	"gold": (4, "#CFB53B"),
	"platinum": (5, "#B4C7DC"),
}


def get_game_average_rating(id: str) -> str:
	data = requests.get(f"https://www.protondb.com/api/v1/reports/summaries/{id}.json")
	if data.status_code != 200 or "tier" not in data.json():
		return "unknown"
	else:
		return data.json()["tier"]


def get_steam_user_data(api_key: str, id: str) -> list[dict[str, str]]:
	data = requests.get(
		f'http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key={api_key}&steamid={id}&format=json&include_appinfo=1'
	)
	if "Bad Request" in data.text:
		raise InvalidIDError()
	elif "Unauthorized" in data.text:
		raise UnauthorizedError()

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
	game_rating_nums = [RATING_DICT[game["rating"]][0] for game in game_ratings]
	user_average = round(sum(game_rating_nums) / len(game_rating_nums))
	user_average_text = [
		key for key, value in RATING_DICT.items() if value[0] == user_average
	][0]

	return game_ratings

	# table = Table(title="Game Compatibility")
	# table.add_column("Title", style="dim green")
	# table.add_column("Compatibility")

	# for game in game_ratings:
	# 	table.add_row(
	# 		game["name"],
	# 		Text(game["rating"].capitalize(), style=RATING_DICT[game["rating"]][1]),
	# 	)

	# console = Console()
	# console.print(table)

	# text = Text.assemble(
	# 	"Average User Rating: ",
	# 	(user_average_text.capitalize(), RATING_DICT[user_average_text][1]),
	# )
	# console.print(text)

	# return user_average_text


class SteamApp(App):
	CSS_PATH = "main.tcss"
	TITLE = "Steam Profile Proton Compatibility Checker"
	def compose(self) -> ComposeResult:
		yield Header()
		yield Center(
			Input(placeholder="Steam API Key", id='api-key', validators=Regex(r'[A-Z0-9]{32}')),
			Input(placeholder="User ID", id='user-id', validators=Regex(r'.+')),
			id="input-container"
		)
		yield Center(Button('Check Profile', variant="primary"))
		yield DataTable(zebra_stripes=True)

	def on_mount(self) -> None:
		# add nothing to table
		table = self.query_one(DataTable)
		table.add_columns('Title', 'Compatibility')

		
		for _ in range(14):
			table.add_row('', '')

	@on(Button.Pressed)
	@on(Input.Submitted)
	def populate_table(self) -> None:
		try:
			for item in self.query(Input):
				item.disabled = True
				item.blur()
				item.refresh()

			for item in self.query(Button):
				item.disabled = True
				item.blur()
				item.refresh()

			table = self.query_one(DataTable)

			table.set_loading(True)
			table.refresh()

			api_key: Input = self.query_one('#api-key')
			id: Input = self.query_one('#user-id')

			user_data = get_steam_user_data(api_key.value, id.value)
			table.clear()
			# user_data = [{'name': 'Euro Truck Simulator 2', 'rating': 'platinum', 'playtime': 12923}, {'name': 'BeamNG.drive', 'rating': 'gold', 'playtime': 7557}, {'name': 'Prison Architect', 'rating': 'gold', 'playtime': 6227}, {'name': 'Farming Simulator 19', 'rating': 'gold', 'playtime': 5815}, {'name': 'Cities: Skylines', 'rating': 'gold', 'playtime': 4434}, {'name': 'Grand Theft Auto V', 'rating': 'gold', 'playtime': 4393}, {'name': 'Horizon Zero Dawn™ Complete Edition', 'rating': 'gold', 'playtime': 3935}, {'name': 'Subnautica', 'rating': 'gold', 'playtime': 3897}, {'name': 'X-Plane 11', 'rating': 'gold', 'playtime': 3777}, {'name': 'Terraria', 'rating': 'gold', 'playtime': 2372}, {'name': 'Microsoft Flight Simulator', 'rating': 'silver', 'playtime': 2335}, {'name': 'Software Inc.', 'rating': 'platinum', 'playtime': 2304}, {'name': 'Stardew Valley', 'rating': 'platinum', 'playtime': 2221}, {'name': 'Planet Coaster', 'rating': 'gold', 'playtime': 2056}, {'name': 'STAR WARS Jedi: Fallen Order™ ', 'rating': 'gold', 'playtime': 1649}, {'name': 'Among Us', 'rating': 'gold', 'playtime': 1513}, {'name': 'Kerbal Space Program', 'rating': 'gold', 'playtime': 1444}, {'name': 'American Truck Simulator', 'rating': 'platinum', 'playtime': 1174}, {'name': 'Subnautica: Below Zero', 'rating': 'platinum', 'playtime': 1130}, {'name': 'The Jackbox Party Pack 7', 'rating': 'gold', 'playtime': 1117}, {'name': 'HITMAN™ 2', 'rating': 'gold', 'playtime': 1060}, {'name': 'Portal 2', 'rating': 'platinum', 'playtime': 1054}, {'name': 'Need for Speed™ Rivals', 'rating': 'gold', 'playtime': 967}, {'name': 'Battlefield 1 ™', 'rating': 'gold', 'playtime': 865}, {'name': 'Battlefield™ V', 'rating': 'gold', 'playtime': 834}, {'name': 'DiRT Rally 2.0', 'rating': 'platinum', 'playtime': 770}, {'name': 'Geometry Dash', 'rating': 'platinum', 'playtime': 734}, {'name': 'The Elder Scrolls V: Skyrim Special Edition', 'rating': 'gold', 'playtime': 700}, {'name': 'Battlefield 4™ ', 'rating': 'gold', 'playtime': 627}, {'name': 'Half-Life 2', 'rating': 'platinum', 'playtime': 613}, {'name': 'Counter-Strike 2', 'rating': 'gold', 'playtime': 552}, {'name': 'Red Dead Redemption 2', 'rating': 'gold', 'playtime': 531}, {'name': 'Sons Of The Forest', 'rating': 'gold', 'playtime': 484}, {'name': 'Hogwarts Legacy', 'rating': 'gold', 'playtime': 385}, {'name': 'The Jackbox Party Pack 8', 'rating': 'platinum', 'playtime': 369}, {'name': 'The Sims™ 4', 'rating': 'gold', 'playtime': 366}, {'name': 'Portal', 'rating': 'platinum', 'playtime': 365},{'name': 'tModLoader', 'rating': 'gold', 'playtime': 354}, {'name': 'STAR WARS Jedi: Survivor™', 'rating': 'gold', 'playtime': 318}, {'name': 'TrackMania Nations Forever', 'rating': 'platinum', 'playtime': 297}, {'name': 'Phasmophobia', 'rating': 'gold', 'playtime': 283}, {'name': 'Portal Stories: Mel', 'rating': 'platinum', 'playtime': 247}, {'name': 'Warframe', 'rating': 'gold', 'playtime': 234}, {'name': 'Unturned', 'rating': 'platinum', 'playtime': 196}, {'name': 'Bloons TD 6', 'rating': 'gold', 'playtime': 177}, {'name': "No Man's Sky", 'rating': 'gold', 'playtime': 177}, {'name': 'Universe Sandbox', 'rating': 'gold', 'playtime': 173}, {'name': 'Plants vs. Zombies™ Garden Warfare 2: Deluxe Edition', 'rating': 'gold', 'playtime': 141}, {'name': 'Halo: The Master Chief Collection', 'rating': 'gold', 'playtime': 110}, {'name': 'The Jackbox Party Pack 4', 'rating': 'platinum', 'playtime': 109}, {'name': "Don't Starve Together", 'rating': 'gold', 'playtime': 101}, {'name': 'Assetto Corsa Competizione', 'rating': 'gold', 'playtime': 85}, {'name': 'Scribble It!', 'rating': 'gold', 'playtime': 82}, {'name': 'Totally Accurate Battle Simulator', 'rating': 'gold', 'playtime': 58}, {'name': 'Apex Legends', 'rating': 'gold', 'playtime': 48}, {'name': 'ARK: Survival Evolved', 'rating': 'gold', 'playtime': 47}, {'name': 'Bloons TD Battles', 'rating': 'gold', 'playtime': 37}, {'name': 'Fishing Planet', 'rating': 'platinum', 'playtime': 15}, {'name': 'Portal with RTX', 'rating': 'silver', 'playtime': 8}, {'name': 'Surviving Mars', 'rating': 'gold', 'playtime': 3}, {'name': 'Metro: Last Light Complete Edition', 'rating': 'silver', 'playtime': 0}, {'name': 'Field of Glory II', 'rating': 'platinum', 'playtime': 0}, {'name': 'Mafia', 'rating': 'platinum', 'playtime': 0}, {'name': 'ARK: Survival Of The Fittest', 'rating': 'bronze', 'playtime': 0}, {'name': 'Tell Me Why', 'rating': 'platinum', 'playtime': 0}, {'name': 'Arma: Cold War Assault Mac/Linux', 'rating': 'pending', 'playtime': 0}, {'name': 'Little Nightmares', 'rating': 'platinum', 'playtime': 0}, {'name': 'Company of Heroes 2', 'rating': 'gold', 'playtime': 0}, {'name': 'Half-Life 2: Episode Two', 'rating': 'platinum', 'playtime': 0}, {'name': 'Half-Life 2: Episode One', 'rating': 'platinum', 'playtime': 0}, {'name': 'Half-Life Deathmatch: Source', 'rating': 'platinum', 'playtime': 0}, {'name': 'Half-Life 2: Lost Coast', 'rating': 'platinum', 'playtime': 0}, {'name': 'Half-Life 2: Deathmatch', 'rating': 'gold', 'playtime': 0}]

			for game in user_data:
				table.add_row(
					game["name"],
					Text(game["rating"].capitalize(), style=RATING_DICT[game["rating"]][1]),
				)
		except InvalidIDError:
			self.notify("Invalid Steam User ID", title='Error', severity="error")
		except UnauthorizedError:
			self.notify("Invalid Steam API Key", title='Error', severity="error")
		finally:
			for item in self.query(Input):
				item.disabled = False

			for item in self.query(Button):
				item.disabled = False

			table = self.query_one(DataTable)
			table.set_loading(False)

if __name__ == "__main__":
	app = SteamApp()
	app.run()
	# main(sys.argv[1])
