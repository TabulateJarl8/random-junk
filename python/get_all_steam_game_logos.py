import requests
from xml.etree import ElementTree
import os

username = input('Steam ID: ')

url = f'https://steamcommunity.com/id/{username}/games/?tab=all&xml=1'
steam_data = ElementTree.fromstring(requests.get(url).text)
games = steam_data.find('games')

for index, game in enumerate(games):
    print(f'{index + 1}/{len(games)}')
    game_url = game.find('logo').text
    id = game_url.split('/')[-2]

    if not os.path.isdir('images'):
        os.mkdir('images')

    if not os.path.isfile(f'images/{id}.jpg'):
        with open(f'images/{id}.jpg', 'wb') as f:
            f.write(requests.get(game_url).content)