from celery import Celery
from firebase import firebase as firebase_lib
import json
import tesseract
import datetime
import urllib
import os
import json
import re
import string

s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'
app = Celery('celery_textrec', backend='amqp', broker='amqp://guest@localhost//')

from celery.utils.log import get_task_logger
logger = get_task_logger(__name__)

def auth():
	fb = firebase_lib.FirebaseApplication('https://keeper-dev.firebaseio.com', None)
	authentication = firebase_lib.FirebaseAuthentication('zElIpVVoPvzdTmVtmaYLOZ2P5vrxsMtNy0IDjQUu', 
	'henry@duffytech.co',
	 admin=True,
	 extra={'id': 1}
	 )
	fb.authentication = authentication
	logger.info(authentication.extra)
	user = fb.authentication.get_user()
	logger.info(user.firebase_auth_token)
	logger.info('fb.authentication.authtoken: ' + fb.authentication.get_user().firebase_auth_token)
	return fb


def downloadImage(image_key):
	local_image_path = '/tmp/' + image_key + ".jpg"
	remote_image_path = s3_base_url + image_key

	if not os.path.isfile(local_image_path):
		f = open(local_image_path, 'wb')
		logger.info('Downloading: ' + remote_image_path + ' to: ' + local_image_path)
		f.write(urllib.urlopen(remote_image_path).read())
		f.close()
	else:
		logger.info(local_image_path + ' already exists.')

	return local_image_path

def postToServer(photo_key, text, fb):
	photo_data = fb.get("photos/" + photo_key, None)
	user = photo_data.get('user', '')
	searchDoc = {
		'user' : user,
		'text' : text,
		'date' :  datetime.datetime.utcnow()
	}
	result = fb.put('/searchDocs/', photo_key, searchDoc)
	return result

def cleanText(text):
	output = text.decode('utf-8').strip()
	output = output.replace('\n', ' ').replace('\r', '')
	output = filter(lambda x: x in string.printable, output)
	
	return output

def recognizeText(local_image_path):
	api = tesseract.TessBaseAPI()
	api.SetOutputName("outputName");
	api.Init("/usr/share/tesseract-ocr/", "eng", tesseract.OEM_DEFAULT)
	api.SetPageSegMode(tesseract.PSM_AUTO)
	logger.debug("Evaluating: %s" % local_image_path)
	pix_image = tesseract.pixRead(str(local_image_path))
	api.SetImage(pix_image)
	
	output_text = api.GetUTF8Text()
	conf = api.MeanTextConf()
	api.End()

	goodWords = list()

	if output_text:
		output_text = cleanText(output_text)
		
		logger.debug("OCR output:\n%s" % output_text)
		logger.debug("Confidence Level: %d %%" % conf)
		for word in output_text.split(' '):
			word = word.strip()
			if len(word) == 0:
				pass
			elif isWordGarbage(word):
				logger.debug("Throwing out: %s" % word)
			else:
				logger.debug("Keeping: %s" % word)
				goodWords.append(word)
	else:
		output_text = ""
		logger.debug("output_text was None")

	logger.debug("Result goodWords: %s" % goodWords)
	return ' '.join(goodWords)

# Regex's used to tell if a word is garbage
ACRONYM 	= re.compile(r"^\(?[A-Z0-9\.-]+('?s)?\)?[.,:]?$")
WORD        = re.compile(r"\S+")
SPACE       = re.compile(r"\s+")
NEWLINE     = re.compile(r"[\r\n]")
ALNUM       = re.compile(r"[a-z0-9]", re.IGNORECASE)
PUNCT       = re.compile("[" + re.escape(string.punctuation) + "]", re.IGNORECASE)
REPEAT      = re.compile(r"([^0-9])\1{2,}")
UPPER       = re.compile(r"[A-Z]")
LOWER       = re.compile(r"[a-z]")
ACRONYM     = re.compile(r"^\(?[A-Z0-9\.-]+('?s)?\)?[.,:]?$")
ALL_ALPHA   = re.compile(r"^[a-z]+$", re.IGNORECASE)
CONSONANT   = re.compile(r"(^y|[bcdfghjklmnpqrstvwxz])", re.IGNORECASE)
VOWEL       = re.compile(r"([aeiou]|y$)", re.IGNORECASE)
CONSONANT_5 = re.compile(r"[bcdfghjklmnpqrstvwxyz]{5}", re.IGNORECASE)
VOWEL_5     = re.compile(r"[aeiou]{5}", re.IGNORECASE)
REPEATED    = re.compile(r"(\b\S{1,2}\s+)(\S{1,3}\s+){5,}(\S{1,2}\s+)")
SINGLETONS  = re.compile(r"^[AaIi]$")

@app.task
def isWordGarbage(word):
	acronym = ACRONYM.match(word)

	vows = len(VOWEL.findall(word))
	cons = len(CONSONANT.findall(word))
	if (len(word) > 30 or

		# If there are three or more identical characters in a row in the string.
		(len(REPEAT.findall(word)) > 0) or

		# More punctuation than alpha numerics.
		(not acronym and len(ALNUM.findall(word)) < len(PUNCT.findall(word))) or

		# Ignoring the first and last characters in the string, if there are three or
		# more different punctuation characters in the string.
		(len(set(PUNCT.findall(word[1:len(word)-1]))) >= 3) or

		# Four or more consecutive vowels, or five or more consecutive consonants.
		(VOWEL_5.match(word) or CONSONANT_5.match(word)) or

		# Number of uppercase letters greater than lowercase letters, but the word is
		# not all uppercase + punctuation.
		(not acronym and len(UPPER.findall(word)) > len(LOWER.findall(word))) or

		# Single letters that are not A or I.
		(len(word) == 1 and ALL_ALPHA.match(word) and not SINGLETONS.match(word)) or

		# All characters are alphabetic and there are 8 times more vowels than
		# consonants, or 8 times more consonants than vowels.
		(not acronym and (len(word) > 2 and ALL_ALPHA.match(word)) and ((vows > cons * 8) or (cons > vows * 8)))
		):
		return True
	else:
		return False

def processPhotoData(photo_key, photo_data, fb):
	local_image_path = downloadImage(photo_data['imageKey'])
	text = recognizeText(local_image_path)

	ret = postToServer(photo_key, text, fb)
	return json.dumps(ret)

@app.task
def processPhotoByKey(photo_key):
	fb = auth()

	photo_data = fb.get("photos/" + photo_key, None)
	return processPhotoData(photo_key, photo_data, fb)

@app.task
def processAllPhotos():
	fb = auth()

	all_photos = fb.get('/photos', None)

	for photo_key, photo_data in all_photos.iteritems():
		processPhotoData(photo_key, photo_data, fb)




