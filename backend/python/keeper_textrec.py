#!/usr/local/Cellar/python/2.7.9/bin/python
from firebase import firebase
import json
import Image
import tesseract
import pytesseract
import urllib
import os.path
import cv2
import sys
import datetime
import argparse

fb = firebase.FirebaseApplication('https://keeper-dev.firebaseio.com', None)
s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'
min_index_date = datetime.datetime.utcnow()

def main():
    parser = argparse.ArgumentParser(description='Run text recognition')
    parser.add_argument('--no-upload', dest='upload', action='store_const', const=False, default=True, help="don't upload the results")
    args = parser.parse_args()
   
    global Upload_Results
    Upload_Results = args.upload

    auth()
    global all_photos_dict, all_imagedata_dict
    all_photos_dict = fb.get('/photos', None)
    all_imagedata_dict = fb.get('/imageData', None)
    
    scan_tasks = generateScanTasks()
    for scan_task in scan_tasks:
        performScanTask(scan_task)

def auth():
    authentication = firebase.FirebaseAuthentication('zElIpVVoPvzdTmVtmaYLOZ2P5vrxsMtNy0IDjQUu', 
    'henry@duffytech.co',
     admin=True,
     extra={'id': 1}
     )
    fb.authentication = authentication
    print authentication.extra
    user = fb.authentication.get_user()
    print user.firebase_auth_token
    print 'fb.authentication.authtoken: ' + fb.authentication.get_user().firebase_auth_token

def generateScanTasks():
    scan_tasks = []
    for photo_key, photo_dict in all_photos_dict.iteritems():
        image_key = photo_dict.get('imageKey', photo_key)
        image_dict = all_imagedata_dict[image_key]
        uploaded = image_dict.get('uploaded', 0)    
        index_date = photo_dict.get('indexed', None)
        if uploaded == True:
            if index_date is None or index_date > min_index_date:
                scanTask = {'image_key' : image_key, 'photo_key' : photo_key}
                print 'adding photo: ' + photo_key + ' with image_key: ' + image_key + ' for indexing.'
                scan_tasks.append(scanTask)
    return scan_tasks

def performScanTask(scan_task):
    image_key = scan_task['image_key']
    photo_key = scan_task['photo_key']
    local_image_path = downloadImageKey(image_key)
    text = recognizeText(local_image_path)
    if Upload_Results:
        postToServer(photo_key, text, all_photos_dict[photo_key])

def downloadImageKey(image_key):
    local_image_path = '/tmp/' + image_key + '.jpg'

    if not os.path.isfile(local_image_path):
        f = open(local_image_path, 'wb')
        print 'downloading: ' + s3_base_url + image_key + ' to: ' + local_image_path
        f.write(urllib.urlopen(s3_base_url + image_key).read())
        f.close()
    else:
        print local_image_path + ' already exists.'

    return local_image_path


def recognizeText(local_image_path):
    #print pytesseract.image_to_string(Image.open(local_image_path))
    
    api = tesseract.TessBaseAPI()
    api.SetOutputName("outputName");
    api.Init("/usr/share/tesseract-ocr/","eng",tesseract.OEM_DEFAULT)
    api.SetPageSegMode(tesseract.PSM_AUTO)
    mImgFile = str(local_image_path)
    pixImage=tesseract.pixRead(mImgFile)
    api.SetImage(pixImage)
    
    outText=api.GetUTF8Text()
    conf=api.MeanTextConf()
    print("OCR output:\n%s"%outText);
    api.End()
    print "..............."
    print "Confidence Level: %d %%"%conf    
    print "Ocred Text: " + outText.decode('utf-8').strip()
   
    return outText
    

def postToServer(photo_key, text, photo_dict):
    user = photo_dict.get('user', '')
    searchDoc = {
        'user' : user,
        'text' : text,
        'date' :  datetime.datetime.utcnow()
    }    
    result = fb.put('/searchDocs/', photo_key, searchDoc)

if __name__ == "__main__":
   sys.exit(main())