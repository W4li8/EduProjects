import numpy as np
import cv2


robotLeftlower = np.array([68,116,0])
robotLeftUpper = np.array([93,255,255])
robotRightLower = np.array([95,176,60])
robotRightUpper = np.array([115,255,255])

cv2.namedWindow('Frame', cv2.WINDOW_NORMAL)



class MAP(object):
    """
    to handle the frames, the map and the objects located on the map.
     """

    def __init__(self, cam: int, show: bool):
        #FRAMES
        self.cap = cv2.VideoCapture(cam)
        self.cap.set(cv2.CAP_PROP_FPS, 15)
        self.warpPoints = [] #store 4 points for the homography
        self.transformMatrix = 0
        self.frame = 0 #current frame of camera
        self.warpped = 0 #truncated frame = output of getPerspectiveTransformation

        #MAPPING
        self.mapWidth = 970 #use the same ratio as for the real map !!
        self.mapHeight = 770 #here 1 pixel = 1 mm on map
        self.mapResolution = 10 #warning : mapResolution should divide mapWidth and mapHeight
        self.mapRows = int(self.mapHeight/self.mapResolution)
        self.mapColumns = int(self.mapWidth/self.mapResolution)
        self.mapMatrix = np.zeros((self.mapRows, self.mapColumns), dtype = np.uint8)

        #ROBOT
        self.goalPos = np.zeros((1,2))
        self.robotMatrixPos = np.zeros((1,2))
        self.robotAngle = None
        self.robotGlobalPose = None #pos and angle packed together
        self.robotWidth = None #in image coordinates
        self.robotRealWidth = 80 #mm
        self.objectPos = np.zeros((1,2))

        self.file = open('datas.txt', 'w')
        self.file.write('#first column : real data ; second column : estimated data from camera\n')

        self.realData = 100
        self.increment = 100
        self.measureNumber = 0
        self.nbIterations = 30
        self.errorData = []
        self.maxRealData = 800

    def click_event(self, event, x, y, flags, params):
        if event == cv2.EVENT_LBUTTONDOWN:
            if len(self.warpPoints) < 4:
                self.warpPoints.append([x, y])

    """
    Select the 4 points used for homography transform.
    """
    def initializeWarp(self): #selecting corners manually
        print('Initializing Warp...')
        while len(self.warpPoints) != 4:
            ret, self.frame = self.cap.read()
            if ret :
                for p in self.warpPoints:
                    cv2.circle(self.frame, (p[0], p[1]), 4, (0, 0, 255), -1)
                cv2.imshow('Frame',self.frame)
                cv2.setMouseCallback('Frame', self.click_event)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

        pts1 = np.float32(self.warpPoints)
        pts2 = np.float32([[0, 0], [self.mapWidth, 0], [self.mapWidth, self.mapHeight], [0, self.mapHeight]])
        self.transformMatrix = cv2.getPerspectiveTransform(pts1, pts2)


    def initializeWarp2(self): #selecting corners automatically
        ret, self.frame = self.cap.read()
        if ret :
            gray = cv2.cvtColor(self.frame,cv2.COLOR_BGR2GRAY)
            blur = cv2.GaussianBlur(gray, (7,7), cv2.BORDER_REFLECT)
            thresh = cv2.adaptiveThreshold(blur,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY,11,2)

            minLineLength = 20
            maxLineGap = 100
            lines = cv2.HoughLinesP(gray,1,np.pi/180,100,minLineLength,maxLineGap)
            for line in lines[0]:
                x1 = line[0]
                y1 = line[1]
                x2 = line[2]
                y2 = line[3]
                print('lines')
                cv2.line(self.frame,(x1,y1),(x2,y2),(0,255,0),2)

            cv2.imshow('thresh', thresh)
            cv2.imshow('blue', blur)
            cv2.imshow('frame from warp', self.frame)
            """
            cv2.imshow('gray', gray)
            ret,thresh = cv2.threshold(gray,127,255,0)
            cv2.imshow('thresh', thresh)

            edges = cv2.Canny(gray,50,150,apertureSize = 3)
            cv2.imshow('Canny', edges)
            contours, hierarchy = cv2.findContours(edges,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)
            cv2.drawContours(self.frame, contours, -1, (255,128,0), 3)
            """


    """
    Applies homography transform on current frame.
    """
    def warpFrame(self):
        self.warpped = cv2.warpPerspective(self.frame, self.transformMatrix, (self.mapWidth, self.mapHeight))
        self.error = False
        self.errorMessage = ''


    """
    Computes the mean (centroid) of the given mask.

    Args:
         mask (binary image): white pixel reprensents an object
         type (string)      : specifies if the centroid should be calculated in
                              matrix or image coordinates

    Returns:
        Flag (bool)         : if the position computation was successful or not
        Position (np.array) : the calculated position
     """
    def extractMeanPos(self, mask, type): #returns the centroid of the given mask in matrix or image coordinate

        coordinates = np.where(mask == [255])
        if len(coordinates[0]) != 0 and len(coordinates[1]) != 0:
            meanX = np.mean(coordinates[0])
            meanY = np.mean(coordinates[1])
            if type == 'matrix':
                meanX = int(meanX/self.mapResolution)
                meanY = int(meanY/self.mapResolution)
            return True, np.array([meanX, meanY])
        else:
            print('ERROR : did not find the mean !')
            return False, None


    """
    Compute the centroids of the 2 lego colored plates on the robot. Use them
    to compute the robot mean position as well as its orientation in radians.
    """
    def extractRobotPose(self):

        img_hsv = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2HSV)
        kernel = np.ones((5,5),np.uint8)

        rightMask = self.maskAndReplace(robotRightLower, robotRightUpper, img_hsv, kernel)
        foundRight, meanRight = self.extractMeanPos(rightMask, 'image')
        if not foundRight:
            print('Unable to find right mean')
            self.error = True
            self.errorMessage += 'RIGHT_MEAN '

        leftMask = self.maskAndReplace(robotLeftlower, robotLeftUpper, img_hsv, kernel)
        foundLeft, meanLeft = self.extractMeanPos(leftMask, 'image')
        if not foundLeft:
            print('Unable to find left mean')
            self.error = True
            self.errorMessage += 'LEFT_MEAN '

        if foundRight and foundLeft:
            self.robotWidth = np.linalg.norm(meanRight - meanLeft)
            meanPos = (meanRight + meanLeft)/2 #in image coordinates
            self.robotGlobalPos = meanPos # * self.robotRealWidth/self.robotWidth
            meanPos = meanPos / self.mapResolution
            self.robotMatrixPos = meanPos.astype(int) #in matrix coordinates => useful for A_STAR

            self.robotAngle = -np.degrees((np.arctan2(meanRight[1] - meanLeft[1], meanRight[0] - meanLeft[0])))




            print('measure {}'.format(self.measureNumber))
            err = self.realData - self.robotGlobalPos[0]
            string = '|{}|{}|{}|\n'.format(self.realData, self.robotGlobalPos[0], err)
            print(string)
            self.file.write(string)
            self.errorData.append(err)

            self.measureNumber = (self.measureNumber + 1)%self.nbIterations
            if self.measureNumber == 0:
                self.realData += self.increment

            if self.realData == self.maxRealData:
                self.realData = 100


            self.robotGlobalPose = np.hstack((self.robotGlobalPos, self.robotAngle))



    """
    Applies masking on the image, some morphological operations. Then replaces
    the current warpped frame pixels located as in mask and replace them with
    white such that they won't be recognized as obstacles .

    Args:
         maskLower (np.array)   : lower bound of mask (used in cv2.inRange)
         maskUpper (np.array)   : upper bound of mask (used in cv2.inRange)
         img_hsv   (cv2.HSV)    : image in HSV domain
         kernel    (np.array)   : kernel to apply in morphological operations

    Returns:
        mask (binary image)     : the mask resulting from the masking operation.
     """
    def maskAndReplace(self, maskLower, maskUpper, img_hsv, kernel):
        mask = cv2.inRange(img_hsv, maskLower, maskUpper) # TODO some morphological operations to remove noise
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        mask = cv2.dilate(mask,kernel,iterations = 2)
        self.warpped[np.where(mask == [255])] = 255
        return mask





if __name__ == '__main__':
    myMap = MAP(cam = 1, show = True) #open camera nb 1
    myMap.initializeWarp()
    flag = True
    while flag:
        print('\n')
        flag = True
        ret, myMap.frame = myMap.cap.read()
        if ret :
            myMap.warpFrame()
            myMap.extractRobotPose()

            cv2.imshow('Output', myMap.warpped)
            cv2.imshow('Frame', myMap.frame)
            if cv2.waitKey(0) & 0xFF == ord('r'):
                continue

            elif cv2.waitKey(0) & 0xFF == ord('q'):
                variance = np.var(myMap.errorData)
                #myMap.file.write('{}\n'.format(variance))
                myMap.file.close()
                break

    # When everything done, release the capture
    myMap.cap.release()
    cv2.destroyAllWindows()















    #
