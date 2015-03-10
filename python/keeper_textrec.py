#!/usr/local/Cellar/python/2.7.9/bin/python
from firebase import firebase
import json
import tesseract
import urllib
import os.path
import cv2
import cv2.cv as cv
import sys
import datetime


firebase = firebase.FirebaseApplication('https://keeper-dev.firebaseio.com', None)
s3_base_url = 'https://duffy-keeper-dev.s3.amazonaws.com/'
current_index_pass = 1

def main():
    images_to_scan = []
    all_image_data_dict = firebase.get('/imageData', None)
    for key, image_data in all_image_data_dict.iteritems():
        uploaded = image_data.get("uploaded", 0)    
        index_pass = image_data.get("indexPass", 0)
        if uploaded == True and index_pass < current_index_pass:
            print "adding " + key + " for indexing."
            images_to_scan.append(key)
        
    #do rec on each file        
    for image_key in images_to_scan:
        local_image_path = downloadImageKey(image_key)
        text = recognizeText(local_image_path)
        postToServer(image_key, text, image_data)

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
    image0=cv2.imread(local_image_path)
    #### you may need to thicken the border in order to make tesseract feel happy to ocr your image #####
    offset=20
    height,width,channel = image0.shape
    image1=cv2.copyMakeBorder(image0,offset,offset,offset,offset,cv2.BORDER_CONSTANT,value=(255,255,255)) 
    #cv2.namedWindow("Test")
    #cv2.imshow("Test", image1)
    #cv2.waitKey(0)
    #cv2.destroyWindow("Test")
    #####################################################################################################
    api = tesseract.TessBaseAPI()
    api.Init(".","eng",tesseract.OEM_DEFAULT)
    api.SetPageSegMode(tesseract.PSM_AUTO)
    height1,width1,channel1=image1.shape
    print image1.shape
    print image1.dtype.itemsize
    width_step = width*image1.dtype.itemsize
    print width_step
    #method 1 
    iplimage = cv.CreateImageHeader((width1,height1), cv.IPL_DEPTH_8U, channel1)
    cv.SetData(iplimage, image1.tostring(),image1.dtype.itemsize * channel1 * (width1))
    tesseract.SetCvImage(iplimage,api)

    text=api.GetUTF8Text()
    conf=api.MeanTextConf()
    image=None
    print "..............."
    print "Ocred Text: " + text.decode('utf-8')
    print "Cofidence Level: %d %%"%conf

    #method 2:
    cvmat_image=cv.fromarray(image1)
    iplimage =cv.GetImage(cvmat_image)
    print iplimage

    tesseract.SetCvImage(iplimage,api)
    #api.SetImage(m_any,width,height,channel1)
    text2=api.GetUTF8Text()
    conf2=api.MeanTextConf()
    image=None
    print "..............."
    print "Ocred Text: " + text2.decode('utf-8')
    print "Cofidence Level: %d %%"%conf2
    api.End()
    
    if conf2 > conf:
        return text2
    return text

def postToServer(image_key, text, image_data):
    user = image_data.get('user', '')
    searchDoc = {
        'user' : user,
        'text' : text,
        'date' :  datetime.datetime.utcnow()
    }
    
    result = firebase.put('/searchDocs/', image_key, searchDoc)

if __name__ == "__main__":
   sys.exit(main())