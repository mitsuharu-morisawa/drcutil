#!/usr/bin/python
# coding: UTF-8
import sys
import os, time, re
import httplib2
import oauth2client.client
from oauth2client.client import OAuth2WebServerFlow
from apiclient.discovery import build
from apiclient.http import MediaFileUpload
from apiclient import errors
from datetime import datetime

CREDENTIAL_FILE = os.environ['HOME'] + '/.jenkinshrg/jsonCredential.txt'

CLIENT_ID = os.environ['CLIENT_ID']
CLIENT_SECRET = os.environ['CLIENT_SECRET']
OAUTH_SCOPE = 'https://www.googleapis.com/auth/drive'
REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'

def storeJsonCredential(jsonStr):
	f = open(CREDENTIAL_FILE, 'w')
	f.write(jsonStr)
	f.close()

def readJsonCredential():
	f = open(CREDENTIAL_FILE)
	json_credential = f.read()
	f.close()
	return json_credential

def get_stored_credentials():
	json_credential = readJsonCredential()
	return oauth2client.client.Credentials.new_from_json(json_credential)

def store_credentials(credentials):
	json_credential = credentials.to_json()
	storeJsonCredential(json_credential)

def first_authorize():
	flow = OAuth2WebServerFlow(CLIENT_ID, CLIENT_SECRET, OAUTH_SCOPE, REDIRECT_URI)
	authorize_url = flow.step1_get_authorize_url()
	print 'Go to the following link in your browser: ' + authorize_url
	code = raw_input('Enter verification code: ').strip()
	credentials = flow.step2_exchange(code)
	store_credentials(credentials)
	return credentials

def build_service():
	try:
		credentials = get_stored_credentials()
		if credentials is None or credentials.invalid:
			credentials = first_authorize()
	except Exception, e:
		credentials = first_authorize()
	http = httplib2.Http()
	http = credentials.authorize(http)
	drive_service = build('drive', 'v2', http=http)
	return drive_service

def create_folder(service, parent_id, title):
	body = {
		'title': title,
		'mimeType': 'application/vnd.google-apps.folder',
                'parents': [{
                        'id': parent_id
                }]
	}
	return service.files().insert(body=body).execute()

def upload_file(service, parent_id, title, file_mimetype, filename):
	media_body = MediaFileUpload(filename, mimetype=file_mimetype, resumable=True)
	body = {
		'title': title,
                'labels': {
                    'restricted': True
                },
		'mimeType': file_mimetype,
                'parents': [{
                        'id': parent_id
                }]
	}
	return service.files().insert(body=body, media_body=media_body).execute()

def retrieve_files(service, query):
	result = []
	page_token = None
	while True:
		try:
			param = {}
			if page_token:
				param['pageToken'] = page_token
			param['q'] = query
			files = service.files().list(**param).execute()

			result.extend(files['items'])
			page_token = files.get('nextPageToken')
			if not page_token:
				break
		except errors.HttpError, error:
			#print 'An error occurred: %s' % error
			break
	return result

def delete_file(service, file_id):
  	try:
  		service.files().delete(fileId=file_id).execute()
	except errors.HttpError, error:
		#print 'An error occurred: %s' % error
		pass

def threshold_date_str(hours_before):
	import time
	today = time.localtime()
	today_epoch_delta = time.mktime(today)
	return_day_epoch_delta = today_epoch_delta - hours_before*60*60
	return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(return_day_epoch_delta))

if __name__ == '__main__':
	drive_service = build_service()

	query = "title != 'share'"
	query += " and modifiedDate <'" + threshold_date_str(240) + "'"
	files = retrieve_files(drive_service, query)
	for item in files:
		delete_file(drive_service, item["id"])

	dt = datetime.now().strftime("%Y-%m-%d")
	query = "title = '" + dt + "'"
	query += " and mimeType = 'application/vnd.google-apps.folder'"
	files = retrieve_files(drive_service, query)
	parent_id = ""
	for item in files:
		parent_id = item["id"]

	if parent_id == "":
		query = "title = 'share'"
		query += " and mimeType = 'application/vnd.google-apps.folder'"
		files = retrieve_files(drive_service, query)
		root_id = ""
		for item in files:
			root_id = item["id"]
		file = create_folder(drive_service, root_id, dt)
		parent_id = file["id"]

	file = upload_file(drive_service, parent_id, sys.argv[1], sys.argv[2], sys.argv[3])
	print file["alternateLink"]
