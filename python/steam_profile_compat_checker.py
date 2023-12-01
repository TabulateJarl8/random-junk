import sys
import requests


def get_game_average_rating(id: str) -> str:
	data = requests.get(f"https://protondb.max-p.me/games/{id}/reports/")
	ratings = []
	if data.status_code == 200:
		for rating in data.json():
			if 'rating' in rating:
				ratings.append(rating['rating'])
	if not ratings:
		return 'Unknown'
	else:
		return max(ratings, key=ratings.count)


def main(id: str):
	if id.isnumeric():
		suburl = 'profile'
	else:
		suburl = 'id'

	xml = requests.get('https://steamcommunity.com/{suburl}/{id}?xml=1')


if __name__ == '__main__':
	main(sys.argv[1])
