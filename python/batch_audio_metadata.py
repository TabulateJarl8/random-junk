import music_tag
import argparse
from pathlib import Path

def set_metadata(path, extension):
	directory = Path(path)
	for file in directory.glob(f'*.{extension.lstrip(".")}'):
		print(file)
		filename_components = file.stem.split(' - ', 1)
		song = filename_components[0].split('. ', 1)[1]
		artist = filename_components[1]
		print([song, artist])

		audio = music_tag.load_file(file)
		audio['title'] = song
		audio['artist'] = artist
		audio.save()
		print()


def main():
	parser = argparse.ArgumentParser(
		prog='batch_audio_metadata',
		description='Set audio metadata based on title of track except im lazy so the pattern matching is hardcoded'
	)

	parser.add_argument('path', help='Path of files to edit')
	parser.add_argument('-e', '--extension', help='File extension of audio files', required=True)
	args = parser.parse_args()

	set_metadata(args.path, args.extension)

if __name__ == '__main__':
	main()