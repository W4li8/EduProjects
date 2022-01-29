import cv2
import numpy as np
import os

cv2.namedWindow('Frame', cv2.WINDOW_NORMAL)
cv2.namedWindow('Dst', cv2.WINDOW_NORMAL)
cv2.namedWindow('Output', cv2.WINDOW_NORMAL)


criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
objp = np.zeros((6*7,3), np.float32)
objp[:,:2] = np.mgrid[0:7,0:6].T.reshape(-1,2)
objpoints = [] # 3d point in real world space
imgpoints = [] # 2d points in image plane.

currentDir = os.getcwd()

returned = None
mtx = None
dist = None
rvecs = None
tvecs = None

def applyChess():
    global returned, mtx, dist, rvecs, tvecs

    cnt = 0
    for file in os.listdir(currentDir):
        if 'image' in file:
            print(file)
            img = cv2.imread(file)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            ret, corners = cv2.findChessboardCorners(gray, (7,6), None)
            if ret == True:
                print('OK RETRIEVAL')
                objpoints.append(objp)
                corners2 = cv2.cornerSubPix(gray,corners, (11,11), (-1,-1), criteria)
                imgpoints.append(corners)
                # Draw and display the corners
                cv2.drawChessboardCorners(img, (7,6), corners2, ret)
                #cv2.imshow('Frame', img)
                #cv2.waitKey(500)
                cv2.imwrite('test_{}.png'.format(cnt), img)
                cnt += 1
            else:
                print('removing : ', file)
                os.remove(file)
    returned, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(objpoints, imgpoints, gray.shape[::-1], None, None)
    np.save('camera_param_dist', dist)
    np.save('camera_param_mtx', mtx)

def takePictures():
    cnt = 0
    while True:
        ret, frame = cap.read()
        if ret :
            cv2.imshow('Frame', frame)

            if cv2.waitKey(1) & 0xFF == ord('r'):
                print('Image number : ', cnt)
                cv2.imwrite('image_{}.png'.format(cnt), frame)
                cnt += 1
                continue

            elif cv2.waitKey(1) & 0xFF == ord('q'):
                break

    # When everything done, release the capture
    cap.release()
    cv2.destroyAllWindows()




if __name__ == '__main__':
    cap = cv2.VideoCapture(1)

    #takePictures()
    applyChess()

    while True:
        flag, frame = cap.read()
        if flag :
            #print(returned, mtx, dist, rvecs, tvecs)


            h, w = frame.shape[:2]
            newcameramtx, roi = cv2.getOptimalNewCameraMatrix(mtx, dist, (w,h), 1, (w,h))
            dst = cv2.undistort(frame, mtx, dist, None, newcameramtx)
            x, y, w, h = roi
            dst = dst[y:y+h, x:x+w]


            cv2.imshow('Frame', frame)
            cv2.imshow('Dst', gray)
            #cv2.imshow('Output', frame-dst)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    #cv2.destroyAllWindows()





#
