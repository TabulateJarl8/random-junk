import argparse
from dataclasses import dataclass
import os
import shutil
import sys
from pathlib import Path
import subprocess
import json
import tempfile
import readline  # noqa: F401
from typing import Optional, Union


@dataclass
class MP4File:
	filename: Path
	track_number: int

	def __init__(self, filename: Union[str, Path], track_number: int):
		if isinstance(filename, str):
			self.filename = Path(filename)
		else:
			self.filename = filename

		self.track_number = track_number


def check_dependencies():
	# check tesseract
	binaries = [
		"tesseract",
		"subtile-ocr",
		"HandBrakeCLI",
		"mkvextract",
		"mkvmerge",
		"ffmpeg",
	]

	for file in binaries:
		if shutil.which(file) is None:
			print(
				f"\u001b[0;31mERROR:\u001b[0m `{file}` is not installed, please install it."
			)
			if file == "subtile-ocr":
				print("https://github.com/gwen-lg/subtile-ocr")

			sys.exit(1)

	# check tesseract data
	search_path = [
		Path(os.environ.get("TESSDATA_PREFIX", "")),
		Path("/usr/share/tessdata/"),
	]
	tesseract_data_found = False
	for path in search_path:
		if (path / "eng.traineddata").exists():
			tesseract_data_found = True
			break

	if not tesseract_data_found:
		print(
			"\u001b[0;31mERROR:\u001b[0m Tesseract english training data not found, please install. (`pacman -S tesseract-data-eng` on arch)"
		)
		sys.exit(1)


def extract_subtitle_tracks(filename: Path) -> list[int]:
	"""Extract the subtitle tracks for user prompting

	Args:
		filename (Path): file path to an MKV video

	Returns:
		list[int]: the track IDs of the english subtitle tracks
	"""
	# Run mkvmerge to identify the tracks in the MKV file
	mkv_info = subprocess.run(
		[
			"mkvmerge",
			"--identify",
			"--identification-format",
			"json",
			filename.resolve(),
		],
		capture_output=True,
	)
	# Ensure mkvmerge ran successfully
	mkv_info.check_returncode()

	# Load the JSON output of mkvmerge and get the list of tracks
	tracklist = json.loads(mkv_info.stdout.decode()).get("tracks", [])

	# Filter the list to extract only English subtitle tracks
	return [
		track["id"]
		for track in tracklist
		if track["type"] == "subtitles"
		and track["properties"]["language"] == "eng"
		and track["properties"]["codec_id"] == "S_VOBSUB"
	]


def convert_subtitles(
	filename: Path,
	track_number: Union[str, int],
	output_filename: Optional[Path] = None,
	dest_dir: Optional[Path] = None,
):
	"""Convert subtitles into srt file with OCR.

	Args:
		filename (Path): the filename of the MKV file
		track_number (Union[str, int]): the track number of the English subtitles
		output_filename (Path): filename to use as an override (dont include .eng.srt)
		dest_dir (Path, Optional): the optional destination directory to output to
	"""
	track_number = str(track_number)

	# Define the output SRT filename
	# should be `original_stem.eng.srt`
	if output_filename is None:
		srt_filename = filename.with_suffix(".eng.srt").resolve()
	else:
		srt_filename = output_filename.with_suffix(".eng.srt").resolve()

	if dest_dir is not None and dest_dir.exists():
		srt_filename = dest_dir / srt_filename.name
	elif dest_dir is not None and not dest_dir.exists():
		print('ERROR: destination directory `{dest_dir}` does not exist. Exiting...')
		sys.exit(1)

	# Use a temporary directory to work with subtitle files
	with tempfile.TemporaryDirectory() as tempd:
		# Extract the VODSUB subtitles from the MKV file
		subprocess.run(
			[
				"mkvextract",
				"tracks",
				filename.resolve(),
				f"{track_number}:{Path(tempd) / filename.stem}",
			]
		).check_returncode()

		# use OCR to convert the VODSUB into SRT
		subprocess.run(
			[
				"subtile-ocr",
				"-l",
				"eng",
				"-o",
				srt_filename.resolve(),
				(Path(tempd) / filename.with_suffix(".idx").name).resolve(),
			]
		).check_returncode()

	# Open the new SRT file for applying small OCR fixes
	with srt_filename.open("r+") as f:
		# read the file
		data = f.read()
		f.seek(0)

		# fix common errors in subtitles
		data = (
			data.replace("|", "I")
			.replace(".:", ":")
			.replace("“", '"')
			.replace("”", '"')
		)

		# write the correct data back to the file
		f.write(data)
		f.truncate()


def transcode_to_mp4_files(
	filename: Path, audio_track_files: list[MP4File],
	dest_dir: Optional[Path] = None,
) -> list[Path]:
	"""Transcode an MKV into an MP4, creating a new MP4 for each specified audio track.

	Args:
		filename (Path): the path to the file
		audio_track_files (list[MP4File]): The MP4 filenames and their respective track IDs
		dest_dir (Path, Optional): the optional destination directory to output to

	Returns:
		list[Path]: a list of the files that were outputted
	"""
	with tempfile.TemporaryDirectory() as tempd:
		mp4_filename = Path(tempd) / filename.with_suffix(".mp4").name

		# transcode the master file to mp4
		subprocess.run(
			[
				"HandBrakeCLI",
				"--preset",
				"Fast 480p30",
				"-i",
				filename.resolve(),
				"-s",
				"none",
				"-o",
				mp4_filename,
				"--audio-lang-list",
				"eng",
				"--all-audio",
			]
		).check_returncode()

		output_files = []

		for track in audio_track_files:
			track_filename = track.filename.name
			track_id = track.track_number

			output_path = filename.parent / track_filename
			if dest_dir is not None and dest_dir.exists():
				output_path = dest_dir / track_filename
			elif dest_dir is not None and not dest_dir.exists():
				print('ERROR: destination directory `{dest_dir}` does not exist. Exiting...')
				sys.exit(1)

			subprocess.run(
				[
					"ffmpeg",
					"-i",
					mp4_filename,
					"-map",
					"0:v",
					"-map",
					f"0:a:{track_id}",
					"-c:v",
					"copy",
					"-c:a",
					"copy",
					output_path,
				]
			).check_returncode()

			output_files.append(output_path)

		return output_files


def get_audio_track_names(filename: Path) -> list[str]:
	"""Get the names of the audio tracks within an MKV file

	Args:
		filename (Path): the path to the MKV

	Returns:
		list[str]: the names of the audio tracks in the MKV
	"""
	# Run mkvmerge to identify the tracks in the MKV file
	mkv_info = subprocess.run(
		[
			"mkvmerge",
			"--identify",
			"--identification-format",
			"json",
			filename.resolve(),
		],
		capture_output=True,
	)
	# # Ensure mkvmerge ran successfully
	mkv_info.check_returncode()

	# Load the JSON output of mkvmerge and get the list of tracks
	tracklist = json.loads(mkv_info.stdout.decode()).get("tracks", [])

	# Filter the list to extract only English subtitle tracks
	return [
		track["properties"]["track_name"]
		for track in tracklist
		if track["type"] == "audio" and track["properties"]["language"] == "eng"
	]


def prompt_audio_track_names(filename: Path) -> list[MP4File]:
	"""Prompt the user to name each audio track in a file

	Args:
		filename (Path): the path to the file

	Returns:
		list[MP4File]: the list of filenames and tracks
	"""
	# First, we must process the audio tracks
	# prompt the user to name each one
	audio_tracks = get_audio_track_names(filename)

	assert len(audio_tracks) > 0

	parent_dir = filename.resolve().parent

	audio_track_encoded_names = [
		MP4File(filename=filename.with_suffix(".mp4"), track_number=0)
	]

	if audio_track_encoded_names[0].filename.exists():
		if (
			input(
				f"File `{audio_track_encoded_names[0].filename}` already exists. Would you like to remove it? [y/N] "
			).lower()
			== "y"
		):
			audio_track_encoded_names[0].filename.unlink()
		else:
			print("Exiting...")
			sys.exit(1)

	print(
		f"Filename for track 1 automatically set: `{audio_track_encoded_names[0].filename.name}`"
	)

	if len(audio_tracks) > 1:
		for index, track in enumerate(audio_tracks[1:]):
			track_filename = Path(
				input(f"Enter filename for track {index + 2} ({track}): ")
			)
			if not track_filename.name:
				continue

			new_filename = parent_dir / track_filename.with_suffix(".mp4")
			if new_filename.exists():
				if (
					input(
						f"File `{new_filename}` already exists. Would you like to remove it? [y/N] "
					).lower()
					== "y"
				):
					new_filename.unlink()
				else:
					print("Exiting...")
					sys.exit(1)
			audio_track_encoded_names.append(MP4File(new_filename, index + 1))

	return audio_track_encoded_names


def process_file(filename: Path, audio_track_encoded_names: list[MP4File], dest_dir: Optional[Path] = None):
	"""Process an MPV file

	Args:
		filename (Path): the path to the MPV file
		audio_track_encoded_names (list[MP4File]): the list of filenames for each track in the file
		dest_dir (Path, Optional): the optional destination directory to output to
	"""

	# now, we must extract the audio for each file
	print("Transcoding to MP4...")
	finished_encoded_files = transcode_to_mp4_files(filename, audio_track_encoded_names, dest_dir)

	# now, we should extract the subtitles and convert them to SRT files
	print("Extracting subtitle tracks...")
	subtitle_track_ids = extract_subtitle_tracks(filename)

	for index, track in enumerate(subtitle_track_ids):
		print(f"Converting subtitles for track {index + 1}...")
		try:
			convert_subtitles(filename, track, finished_encoded_files[index], dest_dir)
		except IndexError:
			print('WARNING: IndexError on subtitle conversion')
			print(f'{subtitle_track_ids=}')
			print(f'{finished_encoded_files=}')


def process_directory(directory: Path, dest_dir: Optional[Path] = None):
	"""Process an entire directory of MPV files.

	Args:
		directory (Path): the path to the directory
		dest_dir (Path, Optional): the optional destination directory to output to
	"""
	if not directory.exists():
		print(f"Directory `{directory.resolve()}` does not exist. Exiting...")
		sys.exit(1)

	all_files = [prompt_audio_track_names(filename) for filename in directory.glob('*.mkv')]

	for index, file in enumerate(directory.glob('*.mkv')):
		process_file(file, all_files[index], dest_dir)


def file_type(path):
	if Path(path).exists():
		return Path(path)
	else:
		raise argparse.ArgumentTypeError(f"{path} is not a valid path")


def parse_arguments():
	parser = argparse.ArgumentParser(
		description="Reencode DVDs",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter,
	)
	parser.add_argument(
		"file_path", type=file_type, help="The path to a file or directory"
	)
	parser.add_argument('--dest-dir', dest='dest_dir', type=file_type, help='The destination directory to write to')
	parser.add_argument('--captions', dest='captions', action='store_true', help='Only generate captions for the specified file')
	parser.add_argument('--captions-index', dest='captions_index', default=0, help='The index of the captions to generate. Skips non-english tracks')
	parser.add_argument('--captions-filename', dest='captions_filename', type=lambda x: Path(x), help='Optional output filename for the captions file')
	return parser.parse_args()


def main():
	check_dependencies()
	args = parse_arguments()
	mkv_path: Path = args.file_path

	if args.captions:
		if mkv_path.is_dir():
			for file in mkv_path.glob('*.mkv'):
				try:
					subtitle_id = extract_subtitle_tracks(file)[int(args.captions_index)]
					convert_subtitles(file, subtitle_id, args.captions_filename, args.dest_dir)
				except IndexError:
					pass
			sys.exit(0)
		else:
			subtitle_id = extract_subtitle_tracks(mkv_path)[int(args.captions_index)]
			convert_subtitles(mkv_path, subtitle_id, args.captions_filename, args.dest_dir)
			sys.exit(0)

	if mkv_path.is_dir():
		process_directory(mkv_path, args.dest_dir)
	else:
		audio_tracks = prompt_audio_track_names(mkv_path)
		process_file(mkv_path, audio_tracks, args.dest_dir)


if __name__ == "__main__":
	main()
