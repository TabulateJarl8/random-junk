"""Program that will collect the compatibility with everyone that you have a spotify blend with. Just open the spotify app and run the program"""
from xml.etree import ElementTree
import re
from uiautomator import JsonRPCError, Device

# logging and data loading
import logging
import os
import json
import argparse
from pathlib import Path
from datetime import datetime

logging.basicConfig(level=os.environ.get('LOGLEVEL', 'WARNING').upper())

def get_middle_of_element(bounds: str) -> tuple[int, int]:
	"""Parse bounds from XML and return the middle of the bounds

	Args:
		bounds (str): bounds of element ([x1,y1][x2,y2])

	Returns:
		tuple: tuple containing the middle x and y values
	"""
	# parse bounds string
	bounds = bounds[1:-1] # trim off ends
	bounds = bounds.split('][')
	top_bounds = [int(coord) for coord in bounds[0].split(',')]
	bottom_bounds = [int(coord) for coord in bounds[1].split(',')]

	middle_x = (bottom_bounds[0] + top_bounds[0]) // 2
	middle_y = (bottom_bounds[1] + top_bounds[1]) // 2
	return middle_x, middle_y

def retrieve_blend_information() -> list[dict[str, str]]:
	# create device and open spotify's library
	logging.debug('Creating device and opening library')
	d = Device()
	d(text='Your Library').click()

	done_blends = []
	scroll = True

	# loop until we have gone through everything in the library
	while scroll:
		# get dump of everything on screen
		logging.debug('Getting screen XML dump')
		xml = ElementTree.fromstring(d.dump())

		# extract first 5 playlists that are visible
		items = [
			element for element in xml.iter()
			if element.get('resource-id') == 'com.spotify.music:id/row_root'
		][:5]

		# detect when we get to the bottom of the screen
		scroll = not d(text='Add podcasts & shows').exists

		# filter out blends from playlists
		blends = [
			element for element in items
			if re.match(
				r'^[^+]+\s\+\s[^+]+, Playlist • Spotify',
				str(element.get('content-desc'))
			)
			and str(element.get('content-desc')).split(' + ')[0] not in [list(item.keys())[0] for item in done_blends] # prevent duplicates
		]

		# iterate over each blend
		for item in blends:
			# try to extract blend title and click that element
			blend_title = item.get('content-desc').split(',')[0]
			try:
				logging.debug(f'Opening blend {blend_title}')
				d(text=blend_title).click.wait()
			except JsonRPCError:
				logging.warning(f'skipping {blend_title} as it is not visible')

			# click on the blend's icon
			d(resourceId='com.spotify.music:id/preview_button').click.wait()

			# extract percentage from screen
			logging.debug('Extracting blend percentage')
			blend_percentage = d(resourceId='com.spotify.music:id/title1').info['text']
			blend_percentage = re.findall(r'(\d+)%', blend_percentage)
			logging.debug(f'Blend percentage: {blend_percentage}')
			done_blends.append(
				{
					item.get('content-desc').split(' + ')[0]: blend_percentage[0]
				}
			)

			# go back to library menu
			d.press.back()
			d.press.back()

		# swipe up to scroll down
		first = get_middle_of_element(items[0].get('bounds'))
		last = get_middle_of_element(items[-1].get('bounds'))
		logging.debug(f'Scroll region: ({last[0]}, {last[1]}) -> ({first[0]}, {first[1]})')
		d.swipe(last[0], last[1], first[0], first[1], steps=50)

	return done_blends

if __name__ == '__main__':
	blend_info = retrieve_blend_information()
	print(blend_info)

	parser = argparse.ArgumentParser(
		prog='Spotify Blend Harvester',
		description='Program that will collect the compatibility with everyone that you have a spotify blend with.'
	)
	parser.add_argument('-d', '--data')

	args = parser.parse_args()
	if args.data:
		datafile = Path(args.data).expanduser().resolve()
		logging.debug(f'Data file path: {datafile}')

		# load data if preexisting
		if datafile.is_file():
			with open(datafile) as f:
				data = json.load(f)
		else:
			data = {}

		if 'dates' not in data:
			data['dates'] = []
		if 'people' not in data:
			data['people'] = {}

		data['dates'].append(datetime.now().strftime('%m-%d-%y'))
		for person_info in blend_info:
			name = list(person_info.keys())[0]
			if name not in data['people']:
				data['people'][name] = []

			data['people'][name].append(int(person_info[name]))

			# pad data if it isn't the same length as the dates list (new person added)
			
			if len(data['people'][name]) < len(data['dates']):
				for _ in range(len(data['dates']) - len(data['people'][name])):
					data['people'][name].insert(0, None)

		with open(datafile, 'w') as f:
			json.dump(data, f)
