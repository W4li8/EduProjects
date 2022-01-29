import cv2
import numpy as np

camera = cv2.VideoCapture(1)

def nothing(x):
    pass

cv2.namedWindow('marking', cv2.WINDOW_NORMAL)
cv2.namedWindow('thresh', cv2.WINDOW_NORMAL)

cv2.createTrackbar('Block Size','marking',3,50,nothing)
cv2.createTrackbar('C','marking',1,50,nothing)
cv2.createTrackbar('slider','marking',1,255,nothing)
#cv2.setTrackbarPos('Block Size','marking')


while(1):
    _,img = camera.read()
    #img = cv2.flip(img,1)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blksize = cv2.getTrackbarPos('Block Size','marking')
    c = cv2.getTrackbarPos('C','marking')
    sliderPos = cv2.getTrackbarPos('slider', 'marking')

    #blksize = 7, c = 4 is ok
    #output = cv2.adaptiveThreshold(gray,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY,2*blksize+1,c)
    ret, output = cv2.threshold(gray,sliderPos,255,cv2.THRESH_BINARY) #maybe change to adaptative
    print(2*blksize+1)
    cv2.imshow('thresh',output)

    if cv2.waitKey(10) & 0xFF == ord('q'):
        camera.release()
        cv2.destroyAllWindows()
        break
