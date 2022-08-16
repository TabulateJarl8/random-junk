# A script to automatically submit my precalc homework

My precalc homework is automatically uploaded to my Google Drive when I scan it with my printer, so I figured that I'd automate uploading it to Canvas.

This program requires a [`credentials.json` file](https://cloud.google.com/docs/authentication/getting-started) for authentication with Google, and a `config.ini` file. Here's an example config.ini file:

```ini
[config]
; canvas API key
api_key = greatapikeyforcanvas123
; canvas course id
course_id = 234786
; ID of google drive folder containing uploaded assignments
gdrive_folder_id = 3u829uhr3-32uhj89rh3
; class folder path (relative to home directory)
class_folder_path = school/12th/sem1/calc1
```

My school git repository for precalc is located at `~/school/11th/sem1/precalc/`