"""Program that will collect the compatibility with everyone that you have a spotify blend with. Just open the spotify app and run the program"""
from xml.etree import ElementTree
import re
from uiautomator import Device, JsonRPCError

def get_middle_of_element(bounds):
	# parse bounds string
	bounds = bounds[1:-1] # trim off ends
	bounds = bounds.split('][')
	top_bounds = [int(coord) for coord in bounds[0].split(',')]
	bottom_bounds = [int(coord) for coord in bounds[1].split(',')]

	middle_x = (bottom_bounds[0] + top_bounds[0]) // 2
	middle_y = (bottom_bounds[1] + top_bounds[1]) // 2
	return middle_x, middle_y

def main():
	d = Device()
	d(text='Your Library').click()
	done_blends = []

	last_item = ''

	while last_item is not None:
		xml = ElementTree.fromstring(d.dump())

		# extract blends
		items = [
			element for element in xml.iter()
			if element.get('resource-id') == 'com.spotify.music:id/row_root'
		][:5]

		# detect when we get to the bottom of the screen
		if ElementTree.tostring(items[-1]) == last_item:
			last_item = None
		else:
			last_item = ElementTree.tostring(items[-1])

		blends = [
			element for element in items
			if re.match(r'^[^+]+\s\+\s[^+]+, Playlist • Spotify', str(element.get('content-desc')))
			and str(element.get('content-desc')).split(' + ')[0] not in [list(item.keys())[0] for item in done_blends] # prevent duplicates
		]

		for item in blends:
			# extract blend title and click that element
			try:
				d(text=item.get('content-desc').split(',')[0]).click.wait()
			except JsonRPCError:
				print(f'skipping {item.get("content-desc").split(",")[0]} as it is not visible')
			#click on the blends icon
			d(resourceId='com.spotify.music:id/preview_button').click.wait()
			# extract percentage from screen
			blend_percentage = d(resourceId='com.spotify.music:id/title1').info['text']
			blend_percentage = re.findall(r'(\d+)%', blend_percentage)
			done_blends.append(
				{
					item.get('content-desc').split(' + ')[0]: blend_percentage[0]
				}
			)

			# go back to menu
			d.press.back()
			d.press.back()

		# swipe up
		
		first = get_middle_of_element(items[0].get('bounds'))
		last = get_middle_of_element(items[-1].get('bounds'))
		d.swipe(last[0], last[1], first[0], first[1], steps=50)

	print(done_blends)

if __name__ == '__main__':
	main()