import re
import pathlib
import sys
import os
import configparser
import shutil

import pick # pip3 install pick
import requests # pip3 install requests

import gdrive


def get_assignment(CANVAS_TOKEN, course_id):
	"""Get user to choose canvas assignment"""
	headers = {'Authorization': f'Bearer {CANVAS_TOKEN}'}

	print('Getting assignments...')

	assignments = requests.get(f'https://learn.vccs.edu/api/v1/courses/{course_id}/assignments?per_page=1000', headers=headers).json()
	homeworks = {
		assignment['name']: assignment['id']
		for assignment in assignments
		if re.search(r'\d+', assignment['name']) and
		'test' not in assignment['name'].lower() and
		'quiz' not in assignment['name'].lower()
	}

	# sort by assignment number
	homeworks = {key: value for key, value in sorted(homeworks.items(), key=lambda item: float(re.findall(r'^\D*(\d+(?:\.\d+)?)', item[0])[0]), reverse=True)}

	option, _ = pick.pick(list(homeworks.keys()), 'Choose an assignment', indicator='>>')

	assignment_desc = requests.get(f'https://learn.vccs.edu/api/v1/courses/{course_id}/assignments/{homeworks[option]}', headers=headers).json()['description']
	form_url = re.search(r'href="(.*?)"', assignment_desc).group(1)

	return {'name': option, 'id': homeworks[option], 'form_url': form_url}


def write_file_to_school(unit_num, filename, fh):
	"""Write file to my school git repo"""
	math_folder = pathlib.Path.home() / pathlib.Path(f'school/11th/sem1/ch{unit_num}/{filename}')
	if math_folder.is_file():
		print(f'Error: File exists: {str(math_folder)}')
		if input('Continue Anyway? [y/N] ').lower() != 'y':
			sys.exit(1)
		else:
			os.remove(str(math_folder))

	math_folder.parent.mkdir(exist_ok=True)
	with math_folder.open('wb') as f:
		f.write(fh.getbuffer())

	return math_folder


def upload_file(assignment_id, path_to_file: pathlib.Path, CANVAS_TOKEN, course_id):
	"""Upload file to canvas"""
	headers = {'Authorization': f'Bearer {CANVAS_TOKEN}'}
	data = {
		'name': path_to_file.name,
		'size': path_to_file.stat().st_size,
		'content_type': 'application/pdf',
	}

	print('Uploading... (1/3)', end='', flush=True)
	resp = requests.post(f'https://learn.vccs.edu/api/v1/courses/{course_id}/assignments/{assignment_id}/submissions/self/files', headers=headers, data=data).json()

	# upload file
	print('\rUploading... (2/3)', end='', flush=True)
	resp = requests.post(resp['upload_url'], data=resp['upload_params'], files={'file': open(path_to_file, 'rb')}, allow_redirects=False)

	print('\rUploading... (3/3)', end='', flush=True)
	headers['Content-Length'] = '0'
	resp = requests.get(resp.headers['Location'], headers=headers).json()

	print('\rFile upload complete!\n\n', flush=True)
	return resp['id']


def submit_assignment(assignment_id, fileid, CANVAS_TOKEN, course_id):
	"""Submit canvas assignment with file upload"""
	headers = {'Authorization': f'Bearer {CANVAS_TOKEN}'}

	data = {
		'submission[submission_type]': 'online_upload',
		'submission[file_ids][]': fileid
	}

	print('Submitting assignment...')

	resp = requests.post(f'https://learn.vccs.edu/api/v1/courses/{course_id}/assignments/{assignment_id}/submissions', headers=headers, data=data).json()
	if resp['upload_status'] == 'success':
		print('Assignment uploaded successfully!')
		return True

	print('Error:')
	print(resp)
	return False


if __name__ == '__main__':
	config = configparser.ConfigParser()
	config.read('config.ini')
	CANVAS_TOKEN = config['api_key']
	COURSE_ID = config['course_id']

	assignment = get_assignment(CANVAS_TOKEN, COURSE_ID)

	# floor unit num
	unit_num = int(float(re.findall(r'^\D*(\d+(?:\.\d+)?)', assignment['name'])[0]))

	filename, fh = gdrive.main()

	filepath = write_file_to_school(unit_num, filename, fh)

	file_id = upload_file(assignment['id'], filepath, CANVAS_TOKEN, COURSE_ID)

	success = submit_assignment(assignment['id'], file_id, CANVAS_TOKEN, COURSE_ID)

	if success:
		os.system(f'/usr/lib/firefox/firefox -P School "{assignment["form_url"]}"')
		if shutil.which('pushschool'):
			os.system('pushschool')
		else:
			print('Warning: pushschool command not found. Skipping')
