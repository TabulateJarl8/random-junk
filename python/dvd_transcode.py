import os
import shutil
import sys
from pathlib import Path
import subprocess
import json
import tempfile


def check_dependencies():
	# check tesseract
	binaries = ["tesseract", "subtile-ocr", "HandBrakeCLI", "mkvextract", "mkvmerge"]

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


def convert_subtitles(filename: Path, track_number: str):
	"""Convert subtitles into srt file with OCR.

	Args:
		filename (Path): the filename of the MKV file
		track_number (str): the track number of the English subtitles
	"""
	# Define the output SRT filename
	# should be `original_stem.eng.srt`
	srt_filename = filename.with_suffix(".eng.srt").resolve()

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


def transcode_to_mp4():
	pass


def main():
	check_dependencies()


if __name__ == "__main__":
	main()
	print(
		extract_subtitle_tracks(
			Path("/home/tabulate/Videos/office_rip/OFFICE_S2D3/B1_t00.mkv")
		)
	)
	convert_subtitles(
		Path("/home/tabulate/Videos/office_rip/OFFICE_S2D3/B1_t00.mkv"), "3"
	)
