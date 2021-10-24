import io
import pathlib
import configparser

from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.http import MediaIoBaseDownload

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly', 'https://www.googleapis.com/auth/drive.readonly']


def main():
	"""Download latest file from specified folder
	Folder ID is specified in the `gdrive_folder_id` key in config.ini
	"""

	config = configparser.ConfigParser()
	config.read('config.ini')
	gdrive_folder_id = config['gdrive_folder_id']

	creds = None
	# The file token.json stores the user's access and refresh tokens, and is
	# created automatically when the authorization flow completes for the first
	# time.
	if pathlib.Path('token.json').is_file():
		creds = Credentials.from_authorized_user_file('token.json', SCOPES)
	# If there are no (valid) credentials available, let the user log in.
	if not creds or not creds.valid:
		if creds and creds.expired and creds.refresh_token:
			creds.refresh(Request())
		else:
			flow = InstalledAppFlow.from_client_secrets_file(
				'credentials.json', SCOPES)
			creds = flow.run_local_server(port=0)
		# Save the credentials for the next run
		with open('token.json', 'w') as token:
			token.write(creds.to_json())

	service = build('drive', 'v3', credentials=creds)

	# Call the Drive v3 API
	results = service.files().list(
		q=f"'{gdrive_folder_id}' in parents and trashed=false",
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


if __name__ == '__main__':
	main()
