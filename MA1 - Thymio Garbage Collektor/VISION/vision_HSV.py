import cv2
import numpy as np

camera = cv2.VideoCapture(1)

def nothing(x):
    pass

cv2.namedWindow('marking', cv2.WINDOW_NORMAL)
cv2.namedWindow('mask', cv2.WINDOW_NORMAL)

cv2.createTrackbar('H Lower','marking',0,255,nothing)
cv2.createTrackbar('H Higher','marking',255,255,nothing)
cv2.createTrackbar('S Lower','marking',0,255,nothing)
cv2.createTrackbar('S Higher','marking',255,255,nothing)
cv2.createTrackbar('V Lower','marking',0,255,nothing)
cv2.createTrackbar('V Higher','marking',255,255,nothing)


while(1):
    _,img = camera.read()

    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    hL = cv2.getTrackbarPos('H Lower','marking')
    hH = cv2.getTrackbarPos('H Higher','marking')
    sL = cv2.getTrackbarPos('S Lower','marking')
    sH = cv2.getTrackbarPos('S Higher','marking')
    vL = cv2.getTrackbarPos('V Lower','marking')
    vH = cv2.getTrackbarPos('V Higher','marking')

    LowerRegion = np.array([hL,sL,vL],np.uint8)
    upperRegion = np.array([hH,sH,vH],np.uint8)

    redObject = cv2.inRange(hsv,LowerRegion,upperRegion)

    kernal = np.ones((1,1),"uint8")

    red = cv2.morphologyEx(redObject,cv2.MORPH_OPEN,kernal)
    red = cv2.dilate(red,kernal,iterations=1)

    res1=cv2.bitwise_and(img, img, mask = red)


    cv2.imshow('mask',res1)

    if cv2.waitKey(10) & 0xFF == ord('q'):
        camera.release()
        cv2.destroyAllWindows()
        break
