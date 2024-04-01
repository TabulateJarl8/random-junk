import os
import shutil
import sys
from pathlib import Path
import subprocess
import json
import tempfile

def check_dependencies():
	# check tesseract
	# /usr/share/tessdata/eng.traineddata
	binaries = ['tesseract', 'subtile-ocr', 'HandBrakeCLI', 'mkvextract', 'mkvmerge']

	for file in binaries:
		if shutil.which(file) is None:
			print(f'\u001b[0;31mERROR:\u001b[0m `{file}` is not installed, please install it.')
			if file == 'subtile-ocr':
				print('https://github.com/gwen-lg/subtile-ocr')

			sys.exit(1)

	# check tesseract data
	search_path = [Path(os.environ.get('TESSDATA_PREFIX', '')), Path('/usr/share/tessdata/eng.traineddata')]
	tesseract_data_found = False
	for path in search_path:
		if (path / 'eng.traineddata').exists():
			tesseract_data_found = True
			break

	if not tesseract_data_found:
		print('\u001b[0;31mERROR:\u001b[0m Tesseract english training data not found, please install. (`pacman -S tesseract-data-eng` on arch)')
		sys.exit(1)

def extract_subtitle_tracks(filename: Path) -> list:
	"""Extract the subtitle tracks for user prompting

	Args:
		filename (Path): file path to an MKV video

	Returns:
		list: the regex matches of the mkvinfo output
	"""
	mkv_info = subprocess.run(['mkvmerge', '--identify', '--identification-format', 'json', filename.resolve()], capture_output=True)
	mkv_info.check_returncode()

	tracklist = json.loads(mkv_info.stdout.decode()).get('tracks', [])

	return [track['id'] for track in tracklist if track['type'] == 'subtitles' and track['properties']['language'] == 'eng']

def convert_subtitles(filename: Path, track_number: str):
	"""Convert subtitles into srt file with OCR.

	Args:
		filename (Path): the filename of the MKV file
		track_number (str): the track number of the English subtitles
	"""
	srt_filename = filename.with_suffix('.eng.srt').resolve()

	with tempfile.TemporaryDirectory() as tempd:
		# extract the VODSUB subtitles
		subprocess.run(['mkvextract', 'tracks', filename.resolve(), f"{track_number}:{Path(tempd) / filename.stem}"]).check_returncode()

		# use OCR to convert the VODSUB into SRT
		subprocess.run(['subtile-ocr', '-l', 'eng', '-o', srt_filename.resolve(), (Path(tempd) / filename.with_suffix('.idx').name).resolve()]).check_returncode()

	with srt_filename.open('r+') as f:
		data = f.read()
		f.seek(0)

		# fix common errors in subtitles
		data = data.replace('|', 'I').replace('.:', ':').replace('“', '"').replace('”', '"')

		f.write(data)
		f.truncate()

def transcode_to_mp4():
	pass

def main():
	pass

if __name__ == '__main__':
	main()
	print(extract_subtitle_tracks(Path('office_rip/OFFICE_S2D3/B1_t00.mkv')))
	convert_subtitles(Path('office_rip/OFFICE_S2D3/B1_t00.mkv'), '3')
