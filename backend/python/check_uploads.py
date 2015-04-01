#!/usr/local/Cellar/python/2.7.9/bin/python
from firebase import firebase
import json
import urllib
import os.path
import sys
import datetime
import argparse

from urllib2 import Request, urlopen, HTTPError, URLError

prod_fb = firebase.FirebaseApplication('https://blazing-heat-8620.firebaseIO.com', None)
prod_secret = '0A4pIoMBlwB5LGOo2MKNxUAG4AWuOT0OKCbJWgjF'
# prod_s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'
prod_s3_base_url = 'https://duffy-keeper.s3.amazonaws.com/'

dev_fb = firebase.FirebaseApplication('https://keeper-dev.firebaseio.com', None)
dev_secret  = 'zElIpVVoPvzdTmVtmaYLOZ2P5vrxsMtNy0IDjQUu'
dev_s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'

min_index_date = datetime.datetime.utcnow()

def main():
    parser = argparse.ArgumentParser(description='Check photos marked uploaded are actually uploaded')
    parser.add_argument('--prod', dest='targetProd', action='store_const', const=True, default=False, help="Target dev or prod database (default: dev)")
    parser.add_argument('--fix', dest='fix', action='store_const', const=True, default=False, help="Mark not found photos as not uploaded or just print results (default: just print)")
    args = parser.parse_args()
    
    global fb, secret, s3_base_url
    if args.targetProd:
        fb = prod_fb
        secret = prod_secret
        s3_base_url = prod_s3_base_url
    else:
        fb = dev_fb
        secret = dev_secret
        s3_base_url = dev_s3_base_url
        
    auth()
    global all_imagedata_dict
    all_imagedata_dict = fb.get('/imageData', None)

    scanImages()

def auth():
    print secret
    
    authentication = firebase.FirebaseAuthentication(secret, 
    'henry@duffytech.co',
     admin=True,
     extra={'id': 1}
     )
    fb.authentication = authentication
    print authentication.extra
    user = fb.authentication.get_user()
    print user.firebase_auth_token
    print 'fb.authentication.authtoken: ' + fb.authentication.get_user().firebase_auth_token

def scanImages():
    problems = []
    for image_key, image_dict in all_imagedata_dict.iteritems():
        if image_dict.get('uploaded', False):
            exists = doesImageExist(image_key)
            if exists == False:
                print '[MISSING] ' + str(image_dict)
        else:
            print '[OK] image not uploaded: ' + image_key
    
def doesImageExist(image_key):
    image_url =  s3_base_url + image_key
    
    user_agent = 'Mozilla/20.0.1 (compatible; MSIE 5.5; Windows NT)'
    headers = { 'User-Agent':user_agent }
    req = Request(image_url, headers = headers)
    try:
        page_open = urlopen(req)
    except HTTPError, e:
        print '[HTTP ERROR ' + str(e.code) + '] ' + image_url
        if e.code == 404:
            return False
        return 'unknown'
    except URLError, e:
        print '[URL ERROR] ' + image_url + ' reason: ' + e.reason
        return 'unknown'
    else:
        print '[OK] ' + image_url
        return True

if __name__ == "__main__":
   sys.exit(main())