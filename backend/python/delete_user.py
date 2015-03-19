#!/usr/local/Cellar/python/2.7.9/bin/python
from firebase import firebase
import json
import urllib
import os.path
import sys
import datetime
import argparse

fb = firebase.FirebaseApplication('https://keeper-dev.firebaseio.com', None)
s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'
min_index_date = datetime.datetime.utcnow()

def main():
    parser = argparse.ArgumentParser(description='Delete a user')
    parser.add_argument('user', type=str, nargs='+', help="The user to delete")
    args = parser.parse_args()
    auth()
    
    global all_photos_dict, all_imagedata_dict
    all_photos_dict = fb.get('/photos', None)
    all_imagedata_dict = fb.get('/imageData', None)
    
    user = args.user[0]
    print "deleting user: %s" %(user)
    deleteUser(user)

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

def deleteUser(user):
    scan_tasks = []
    for photo_key, photo_dict in all_photos_dict.iteritems():
        photo_user = photo_dict.get('user', '')
        if photo_user != user:
            continue

        print "deleting photo:%s for user %s" %(photo_key, image_key, user)

        fb.delete('/photos', photo_key)
        fb.delete('/searchDocs', photo_key)

    for image_key, image_dict in all_imagedata_dict.iteritems():
        image_user = image_dict.get('user', '')
        if image_user != user:
            continue
        
        print "deleting image:%s for user %s" %(image_key, user)
        fb.delete('/imageData', image_key)
        
    fb.delete('/users', user)

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