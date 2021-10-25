#!/usr/bin/env python3

import re
import pathlib
import sys
import os
import configparser
import shutil
import io

import pick # pip3 install pick
import requests # pip3 install requests

# pip3 install -U google-api-python-client google-auth-httplib2 google-auth-oauthlib
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.http import MediaIoBaseDownload


class HomeworkSubmitter:
	def __init__(self):
		self.current_directory = pathlib.Path(__file__).resolve().parent

		config = configparser.ConfigParser()
		config.read(self.current_directory / 'config.ini')
		self.CANVAS_TOKEN = config['config']['api_key']
		self.COURSE_ID = config['config']['course_id']
		self.GDRIVE_FOLDER_ID = config['config']['gdrive_folder_id']

		# If modifying these scopes, delete the file token.json.
		self.SCOPES = [
			'https://www.googleapis.com/auth/drive.metadata.readonly',
			'https://www.googleapis.com/auth/drive.readonly'
		]

		self.assignment = None
		self.filepath = None
		self.file_id = None
		self.upload_success = None

	def download_latest_file(self):
		"""Download latest file from specified folder
		Folder ID is specified in the `gdrive_folder_id` key in config.ini
		"""

		creds = None
		# The file token.json stores the user's access and refresh tokens, and is
		# created automatically when the authorization flow completes for the first
		# time.
		if pathlib.Path(self.current_directory / 'token.json').is_file():
			creds = Credentials.from_authorized_user_file(self.current_directory / 'token.json', self.SCOPES)
		# If there are no (valid) credentials available, let the user log in.
		if not creds or not creds.valid:
			if creds and creds.expired and creds.refresh_token:
				creds.refresh(Request())
			else:
				flow = InstalledAppFlow.from_client_secrets_file(
					self.current_directory / 'credentials.json', self.SCOPES)
				creds = flow.run_local_server(port=0)
			# Save the credentials for the next run
			with open(self.current_directory / 'token.json', 'w') as token:
				token.write(creds.to_json())

		service = build('drive', 'v3', credentials=creds)

		# Call the Drive v3 API
		results = service.files().list(
			q=f"'{self.GDRIVE_FOLDER_ID}' in parents and trashed=false",
			pageSize=1, fields="nextPageToken, files(id, name)"
		).execute()
		items = results.get('files', [])

		if not items:
			print('No files found.')
		else:
			request = service.files().get_media(fileId=items[0]['id'])
			fh = io.BytesIO()
			downloader = MediaIoBaseDownload(fh, request)
			done = False
			while done is False:
				status, done = downloader.next_chunk()
				print("Download %d%%." % int(status.progress() * 100))

			return items[0]['name'], fh

	def get_assignment(self):
		"""Get user to choose canvas assignment"""
		headers = {'Authorization': f'Bearer {self.CANVAS_TOKEN}'}

		print('Getting assignments...')

		assignments = requests.get(f'https://learn.vccs.edu/api/v1/courses/{self.COURSE_ID}/assignments?per_page=1000', headers=headers).json()
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

		assignment_desc = requests.get(f'https://learn.vccs.edu/api/v1/courses/{self.COURSE_ID}/assignments/{homeworks[option]}', headers=headers).json()['description']
		form_url = re.search(r'href="(.*?)"', assignment_desc).group(1)

		# floor unit num
		unit_num = int(float(re.findall(r'^\D*(\d+(?:\.\d+)?)', option)[0]))

		filename, fh = self.download_latest_file()

		self.assignment = {
			'name': option,
			'id': homeworks[option],
			'form_url': form_url,
			'unit_num': unit_num,
			'filename': filename,
			'fh': fh
		}

	def write_assignment_to_school(self):
		"""Write file to my school git repo"""
		self.filepath = pathlib.Path.home() / pathlib.Path(f'school/11th/sem1/ch{self.assignment["unit_num"]}/{self.assignment["filename"]}')
		if self.filepath.is_file():
			print(f'Error: File exists: {str(self.filepath)}')
			if input('Continue Anyway? [y/N] ').lower() != 'y':
				sys.exit(1)
			else:
				os.remove(str(self.filepath))

		self.filepath.parent.mkdir(exist_ok=True)
		with self.filepath.open('wb') as f:
			f.write(self.assignment["fh"].getbuffer())

	def upload_file(self):
		"""Upload file to canvas"""
		headers = {'Authorization': f'Bearer {self.CANVAS_TOKEN}'}
		data = {
			'name': self.filepath.name,
			'size': self.filepath.stat().st_size,
			'content_type': 'application/pdf',
		}

		print('Uploading... (1/3)', end='', flush=True)
		resp = requests.post(f'https://learn.vccs.edu/api/v1/courses/{self.COURSE_ID}/assignments/{self.assignment["id"]}/submissions/self/files', headers=headers, data=data).json()

		# upload file
		print('\rUploading... (2/3)', end='', flush=True)
		resp = requests.post(resp['upload_url'], data=resp['upload_params'], files={'file': open(self.filepath, 'rb')}, allow_redirects=False)

		print('\rUploading... (3/3)', end='', flush=True)
		headers['Content-Length'] = '0'
		resp = requests.get(resp.headers['Location'], headers=headers).json()

		print('\rFile upload complete!\n\n', flush=True)
		self.file_id = resp['id']

	def submit_assignment(self):
		"""Submit canvas assignment with file upload"""
		headers = {'Authorization': f'Bearer {self.CANVAS_TOKEN}'}

		data = {
			'submission[submission_type]': 'online_upload',
			'submission[file_ids][]': self.file_id
		}

		print('Submitting assignment...')

		resp = requests.post(f'https://learn.vccs.edu/api/v1/courses/{self.COURSE_ID}/assignments/{self.assignment["id"]}/submissions', headers=headers, data=data).json()
		if resp['upload_status'] == 'success':
			print('Assignment uploaded successfully!')
			self.upload_success = True
		else:
			print('Error:')
			print(resp)
			self.upload_success = False

	def finalize(self):
		if self.upload_success:
			os.system(f'/usr/lib/firefox/firefox -P School "{self.assignment["form_url"]}"')
			if shutil.which('pushschool'):
				os.system('pushschool')
			else:
				print('Warning: pushschool command not found. Skipping')

	def autorun(self):
		"""Run all functions needed to submit homework"""
		self.get_assignment()
		self.write_assignment_to_school()
		self.upload_file()
		self.submit_assignment()
		self.finalize()


if __name__ == '__main__':
	HomeworkSubmitter().autorun()
