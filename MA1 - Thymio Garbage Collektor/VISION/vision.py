import numpy as np
import cv2
import matplotlib.pyplot as plt
import imutils
from matplotlib import colors

cv2.namedWindow('Frame', cv2.WINDOW_NORMAL)
cv2.namedWindow('Map Matrix', cv2.WINDOW_NORMAL)

"""
Masks used to color-segment objects on frame.
"""
goalMaskLower = np.array([0,57,165])
goalMaskUpper = np.array([34,123,255])
objectLower = np.array([58,66,131])
objectUpper = np.array([82,188,202])
forkLower = np.array([150,82,0])
forkUpper = np.array([255,255,255])
robotLeftlower = np.array([64,66,50])
robotLeftUpper = np.array([86,255,147])
robotRightLower = np.array([95,161,0])
robotRightUpper = np.array([148,255,255])

class MAP(object):
    """
    To handle the frames, the map and the objects located on the map.
    """

    def __init__(self, cam: int, show: bool):
        #FRAMES
        self.cap = cv2.VideoCapture(cam)
        self.cap.set(cv2.CAP_PROP_FPS, 25)
        self.warpPoints = [] #store 4 points for the homography
        self.transformMatrix = 0
        self.frame = 0 #current frame of camera
        self.warpped = 0 #truncated frame = output of getPerspectiveTransformation
        self.newCameraMtx = None
        self.mtx = np.load('camera_param_mtx.npy')#camera parameters: calculated
            #with camera_calibration script
        self.dist = np.load('camera_param_dist.npy')
        self.frameShape = np.array([1080, 1920])

        #MAPPING
        self.mapWidth = 970 #use the same ratio as for the real map !!
        self.mapHeight = 770 #here 1 pixel = 1 mm on map
        self.mapResolution = 10 #warning : mapResolution should divide mapWidth and mapHeight
        self.mapRows = int(self.mapHeight/self.mapResolution)
        self.mapColumns = int(self.mapWidth/self.mapResolution)
        self.mapMatrix = np.zeros((self.mapRows, self.mapColumns), dtype = np.uint8)
        self.mapMatrixCompleted = False

        #PLOTTING
        self.fig, self.ax = self.create_empty_plot()
        self.cmap = colors.ListedColormap(['black', 'white'])

        #ROBOT
        self.goalPos = None
        self.exactGoal = None
        self.robotMatrixPos = None
        self.robotAngle = None
        self.robotGlobalPose = None #pos and angle packed together
        self.robotWidth = 170 #in image coordinates
        self.robotHeight = 72
        self.objectPos = None
        self.exactObject = None
        self.objectHeight = 5
        self.robotIsCatching = False


        #OTHER
        self.show = show
        self.error = False
        self.errorMessage = ''

    def click_event(self, event, x, y, flags, params):
        """
        Callback when the mouse is clicked. It helps defining the points for
        homography. May serve for debugging.
        """
        if event == cv2.EVENT_LBUTTONDOWN:
            if len(self.warpPoints) < 4:
                self.warpPoints.append([x, y])

    def initializeWarp(self):
        """
        Select the 4 points used for homography transform. With this selected 4
        points, get the transformation matrix.
        """
        print('Initializing Warp...')
        """ Uncomment this if you want to select the warpping points with the
        mouse ! May serve for debugging.
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
        """
        pts1 = [[561,266],[1418,215],[1577,896],[510,982]] #hardcode points because camera is not moving
        pts1 = np.float32(pts1)
        pts2 = np.float32([[0, 0], [self.mapWidth, 0], [self.mapWidth, self.mapHeight], [0, self.mapHeight]])
        self.transformMatrix = cv2.getPerspectiveTransform(pts1, pts2)

        h = self.frameShape[0]
        w = self.frameShape[1]
        self.newCameraMtx, _ = cv2.getOptimalNewCameraMatrix(self.mtx,self.dist,(w,h),1,(w,h))

    def warpFrame(self):
        """
        Applies homography transform on current frame. Also reset error flag and
        message since we are dealing with a new frame.
        """
        self.frame = cv2.undistort(self.frame, self.mtx, self.dist, None, self.newCameraMtx)
        self.warpped = cv2.warpPerspective(self.frame, self.transformMatrix, (self.mapWidth, self.mapHeight))
        self.error = False
        self.errorMessage = ''

    def drawGrid(self):
        """
        Draw a grid with nb rows and colums defined in constructor on current
        frame. This helps while debugging.
        """
        for k in range(self.mapRows):
            cv2.line(self.warpped, (0, k*self.mapResolution), (self.mapWidth, k*self.mapResolution), (255,0,0), 1)
        for k in range(self.mapColumns):
            cv2.line(self.warpped, (k*self.mapResolution, 0), (k*self.mapResolution, self.mapHeight), (255,0,0), 1)

    def correctPerspective(self, pos1, pos2, height):
        """
        Given a x and y positions, correct the perspective seen at the camera
        location. The correction is stronger if the object is higher, as the
        perspective would be stronger.

        Args:
             pos1               : position of the object we want to localize
             pos2               : position of the object we want to localize
             height             : height of the object we want to localize

        Returns:
            pos1                : corrected pos1
            pos2                : corrected pos2

        """
        pos1 += 42/839*(502.48 - pos1)*height/self.robotHeight #divide by robot height because we calculated the correction with the robot.
        pos2 += 43/683*(829.3 - pos2)*height/self.robotHeight
        return pos1, pos2

    def extractMeanPos(self, mask, type, height=0): #returns the centroid of the given mask in matrix or image coordinate
        """
        Computes the projected (=reduce perspective) centroid of the given mask.

        Args:
             mask (binary image): white pixel reprensents an object
             type (string)      : specifies if the centroid should be calculated
                                  in matrix or image coordinates
             height             : height of the object we want to localize

        Returns:
            Flag (bool)         : if the position computation was successful
            Position (np.array) : the calculated position
         """

        coordinates = np.where(mask == [255])
        if len(coordinates[0]) != 0 and len(coordinates[1]) != 0:
            meanX = np.mean(coordinates[0])
            meanY = np.mean(coordinates[1])
            meanY, meanX = self.correctPerspective(meanY, meanX, height)
            if type == 'matrix':
                meanX = int(meanX/self.mapResolution)
                meanY = int(meanY/self.mapResolution)
            return True, np.array([meanX, meanY])
        else:
            print('ERROR : did not find the mean !')
            return False, None

    def extractObstacles(self):
        """
        From current warpped frame, applies thresholding, extract black regions
        as obstacles and grows them with the robot dimension. Use those obstacles
        to construct the matrix representing the map.
        """
        gray = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2GRAY)
        ret, thresholded = cv2.threshold(gray,60,255,cv2.THRESH_BINARY) #maybe change to adaptative

        kernel = np.ones((15,15),np.uint8) #to remove NOISE !
        mask = cv2.bitwise_not(thresholded, mask=None)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)

        kernel = np.ones((self.robotWidth,self.robotWidth),np.uint8)
        dilated = cv2.dilate(mask, kernel, 1) #grow the obstacles by the kernel size
        res = cv2.bitwise_xor(dilated, mask, mask=None)
        #cv2.imshow('diff', res)
        self.warpped[np.where(res == [255])] = (255,255,0)
        output = cv2.bitwise_or(dilated, mask, mask=None)
        output = cv2.bitwise_not(output, mask=None)

        for k in range(self.mapRows):
            for j in range(self.mapColumns):
                temp = output[k * self.mapResolution:(k+1)*self.mapResolution, j * self.mapResolution:(j+1)*self.mapResolution] #scice over resolution's square
                if (np.mean(temp) > 127):
                    self.mapMatrix[k][j] = 255 #turns the cell white = it is free!
                else :
                    self.mapMatrix[k][j] = 0

        self.mapMatrixCompleted = True

        if self.show:
            cv2.imshow('thresholded from extractObstacles', thresholded)
            cv2.imshow('Thresoldbinary after morphologyEx', mask)
            cv2.imshow('Map Matrix', self.mapMatrix)
            cv2.imshow('output', output)

    def extractRobotPose(self):
        """
        Compute the centroids of the 2 lego colored plates on the robot. Use them
        to compute the robot mean position as well as its orientation in radians.
        """

        img_hsv = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2HSV)
        kernel = np.ones((5,5),np.uint8)

        rightMask = self.maskAndReplace(robotRightLower, robotRightUpper, img_hsv, kernel)
        foundRight, meanRight = self.extractMeanPos(rightMask, 'image', self.robotHeight)
        if not foundRight:
            self.error = True
            self.errorMessage += 'RIGHT_MEAN '

        leftMask = self.maskAndReplace(robotLeftlower, robotLeftUpper, img_hsv, kernel)
        foundLeft, meanLeft = self.extractMeanPos(leftMask, 'image', self.robotHeight)
        if not foundLeft:
            self.error = True
            self.errorMessage += 'LEFT_MEAN '

        if foundRight and foundLeft:
            meanPos = (meanRight + meanLeft)/2 #in image coordinates
            self.robotGlobalPos = meanPos

            meanPos = meanPos / self.mapResolution
            self.robotMatrixPos = meanPos.astype(int) #in matrix coordinates => useful for A_STAR

            self.robotAngle = -(np.arctan2(meanRight[1] - meanLeft[1], meanRight[0] - meanLeft[0]))
            self.robotGlobalPose = np.hstack((self.robotGlobalPos[1], self.robotGlobalPos[0], self.robotAngle))

        if self.show:
            cv2.imshow('right mask', rightMask)
            cv2.imshow('left mask', leftMask)

    def extractGoal(self):
        """
        From current warpped frame, extract goal in matrix and image coordinates.
        """
        img_hsv = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2HSV)
        kernel = np.ones((5,5),np.uint8)

        goalMask = self.maskAndReplace(goalMaskLower, goalMaskUpper, img_hsv, kernel)
        found, goalPos = self.extractMeanPos(goalMask, 'matrix')
        f1, temp = self.extractMeanPos(goalMask, 'image')
        if not found:
            self.error = True
            self.errorMessage += 'GOAL '

        self.goalPos = goalPos

        if f1:
            self.exactGoal = [int(round(i)) for i in temp]

        if self.show:
            cv2.imshow('Goal', goalMask)

    def extractObject(self):
        """
        From current warpped frame, extract object in matrix and image coordinates.
        """

        img_hsv = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2HSV)
        kernel = np.ones((5,5),np.uint8)

        objectMask = self.maskAndReplace(objectLower, objectUpper, img_hsv, kernel)
        found, objectPos = self.extractMeanPos(objectMask, 'matrix', self.objectHeight)
        f1, temp = self.extractMeanPos(objectMask, 'image')
        if not found:
            self.error = True
            self.errorMessage += 'OBJECT '

        self.objectPos = objectPos
        if f1:
            self.exactObject = [int(round(i)) for i in temp]
        if self.show:
            cv2.imshow('object', objectMask)

    def maskAndReplace(self, maskLower, maskUpper, img_hsv, kernel):
        """
        Applies masking on the image and some morphological operations. Then replaces
        the current warpped frame pixels located as in mask and replace them with
        white such that they won't be recognized as obstacles.

        Args:
             maskLower (np.array)   : lower bound of mask (used in cv2.inRange)
             maskUpper (np.array)   : upper bound of mask (used in cv2.inRange)
             img_hsv   (cv2.HSV)    : image in HSV domain
             kernel    (np.array)   : kernel to apply in morphological operations

        Returns:
            mask (binary image)     : the mask resulting from the masking operation.
        """

        mask = cv2.inRange(img_hsv, maskLower, maskUpper) # TODO some morphological operations to remove noise
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        mask = cv2.dilate(mask,kernel,iterations = 2)
        self.warpped[np.where(mask == [255])] = 255
        return mask

    def verifyCatch(self):
        """
        From current object position and fork position, veirfies if the object
        is in the fork.
        """

        #print('Verifying Catch...')
        img_hsv = cv2.cvtColor(self.warpped, cv2.COLOR_BGR2HSV)
        kernel = np.ones((5,5),np.uint8)

        #extract FORK
        forkMask = self.maskAndReplace(forkLower, forkUpper, img_hsv, kernel)
        found, forkMeanPos = self.extractMeanPos(forkMask, 'image')
        if not found:
            #self.error = True
            self.errorMessage += 'FORK '
        else:
            radius = 15
            if self.objectPos is not None:
                if np.linalg.norm(self.objectPos*self.mapResolution - forkMeanPos) < radius:
                    self.robotIsCatching = True
                else:
                    self.robotIsCatching = False

            center = (int(forkMeanPos[1]), int(forkMeanPos[0]))
            cv2.circle(self.warpped, center, radius, (0, 0, 255), 1)

    def create_empty_plot(self):
        """
        Set parameters for plotting the results : ticks, limit of axis, ...
        This method is useful for debugging.
        """
        print('Create Empty Plot...')
        fig, ax = plt.subplots(figsize=(7,7))
        major_ticks_Width = np.arange(0, self.mapWidth+1, 5)
        minor_ticks_Width = np.arange(0, self.mapWidth+1, 1)
        major_ticks_Height = np.arange(0, self.mapHeight+1, 5)
        minor_ticks_Height = np.arange(0, self.mapHeight+1, 1)
        ax.grid(which='minor', alpha=0.2)
        ax.grid(which='major', alpha=0.5)
        ax.set_ylim([self.mapRows, -1])
        ax.set_xlim([-1,self.mapColumns])
        ax.grid(True)
        return fig, ax

    def display(self):
        """
        Show the matrix representing the map.
        """

        self.ax.imshow(np.flip(self.mapMatrix, 0), cmap=self.cmap)
        plt.show()


class FINDPATH(object):
    """This class aims at handling A* algorithm : apply it to find a path in an
    occupancy grid, optimize this path and plot it."""

    def __init__(self, mapResolution):
        self.occupancyGrid = 0
        self.start = 0
        self.goal = 0
        self.closedSet = []
        self.totalPath = []
        self.matrixOptimizedPath = [] #in matrix coordinates
        self.robotOptimizedPath = [] #in image coordinates
        self.coords = 0
        self.h = 0
        self.mapResolution = mapResolution

        self.found = False
        self.robotAllowedDeviation = 5 #in matrix unit; 1 matrix unit = mapResolution
        self.robotPathMode = 'OBJECT'

        self.fig, self.ax = self.createPlot()
        self.cmap = colors.ListedColormap(['black', 'white'])

    def get_movements_8n(self):
        """
        Get all possible 8-connectivity movements. Equivalent to get_movements_in_radius(1)
        (up, down, left, right and the 4 diagonals).
        :return: list of movements with cost [(dx, dy, movement_cost)]
        """
        s2 = np.sqrt(2)
        return [(1, 0, 1.0),
                (0, 1, 1.0),
                (-1, 0, 1.0),
                (0, -1, 1.0),
                (1, 1, s2),
                (-1, 1, s2),
                (-1, -1, s2),
                (1, -1, s2)]

    def A_Star(self, grid, start, goal, exact):
        """
        Applies the A* algorithm from a starting point to a goal point through a
        matrix representing a map in order to find a path. The path is then given if __name__ == '__main__':
        matrix coordinates.

        Args:
             grid   (np.array)          : occupancy grid representing the map
             start  (tuple)             : starting point
             goal   (tuple)             : the point where to end the path
             exact  (np array)          : exact position in image coordinate of
                                          goal of A* (better alignment of robot).
        """

        self.occupancyGrid = grid
        self.start = start
        self.goal = goal
        self.coords, self.h = self.getCoordsAndH()
        self.found = False

        coords = self.coords
        h = self.h
        movements = self.get_movements_8n()
        openSet = [self.start]
        self.closedSet = []
        cameFrom = dict()
        gScore = dict(zip(coords, [np.inf for x in range(len(coords))]))
        gScore[self.start] = 0

        # For node n, fScore[n] := gScore[n] + h(n). map with default value of Infinity
        fScore = dict(zip(coords, [np.inf for x in range(len(coords))]))
        fScore[self.start] = h[self.start]

        self.found = False
        while len(openSet)!= 0: #find the unvisited node having the lowest fScore[] value
            min_val = np.inf
            for item in openSet:
                value = fScore[item]
                if value < min_val:
                    min_val = value
                    unvisited = item

            if unvisited == goal: #If the goal is reached, reconstruct and return the obtained path
                print("Reconstructing path...")
                self.totalPath = [unvisited]
                while unvisited in cameFrom:
                    unvisited = cameFrom[unvisited]
                    self.totalPath.append(unvisited)

                self.optimizePath(exact)
                self.found = True
                break

            self.closedSet.append(unvisited)

            # If the goal was not reached, for each neighbor of current:
            #print('openset ' , openSet)
            #print(unvisited)
            openSet.remove(unvisited)
            for dx, dy, deltacost in movements:
                neighbor = (int(unvisited[0] + dx), int(unvisited[1] + dy))

                # if the node is not in the map, skip
                error = False
                for k in range(2):
                    if neighbor[k]<0 or neighbor[k]>=self.occupancyGrid.shape[k]:
                        error = True
                if error:
                    continue

                # if the node is occupied or has already been visited, skip
                if self.occupancyGrid[neighbor] == 0 or neighbor in self.closedSet:
                    continue

                # compute the cost to reach the node through the given path
                tentative_gScore = gScore[unvisited] + deltacost

                # Add the neighbor list of nodes who's neighbors need to be visited
                if tentative_gScore < gScore[neighbor]:
                    cameFrom[neighbor] = unvisited
                    gScore[neighbor] = tentative_gScore
                    fScore[neighbor] = gScore[neighbor] + h[neighbor]
                    if neighbor not in openSet:
                        openSet.append(neighbor)

        if not self.found:
            print('WARNING : A* could not find any path !')
            self.robotOptimizedPath = [self.start]

    def RobotIsFarFromPath(self, robotPosition):
        """
        Check if the robot position is far from the path computed using A*.

        Args:
            robotPosition   (np.array)  : robot position in matrix coordinates

        Returns:
            (bool) : flag if the robot is indeed far from the computed path.
        """

        if len(self.totalPath) == 0:
            return False

        min = np.inf
        for p in self.totalPath:
            d = np.linalg.norm(p - robotPosition)
            if d < min:
                min = d

        if min > self.robotAllowedDeviation:
            return True
        else:
            return False

    def getCoordsAndH(self):
        """
        Creates a dictionnary for all the coordinates in an occupancy grid. Also
        creates a matrix of all heuristic values in the grid given a goal.

        Returns:
            coords  (dict)      : all the coordinates in map.
            h       (np.array)  : heuristic values according to a goal.
        """

        dim = self.occupancyGrid.shape

        x,y = np.mgrid[0:dim[0]:1, 0:dim[1]:1]
        pos = np.empty(x.shape + (2,))
        pos[:, :, 0] = x; pos[:, :, 1] = y
        pos = np.reshape(pos, (x.shape[0]*x.shape[1], 2))
        coords = list([(int(x[0]), int(x[1])) for x in pos])

        h = np.linalg.norm(pos - self.goal, axis=-1)
        h = dict(zip(coords, h))

        return coords, h

    def optimizePath(self, exact):
        """
        From a computed A* path, get rid of the redundant information in the
        path : that is, discards the non-major points. Also convert the path
        such that the robot can use it without more computations.

        Args:
            exact  (np array)          : exact position in image coordinate of
                                         goal of A* (better alignment of robot).
        """

        self.matrixOptimizedPath = []
        self.matrixOptimizedPath.append(self.totalPath[0])
        last = self.matrixOptimizedPath[len(self.matrixOptimizedPath) - 1]

        cnt = 1
        size = len(self.totalPath)
        while(self.start not in self.matrixOptimizedPath):
            for i in range(cnt, size):
                if not self.freePath(last, self.totalPath[i]):
                    self.matrixOptimizedPath.append(self.totalPath[i-1])
                    last = self.matrixOptimizedPath[len(self.matrixOptimizedPath) - 1]
                    cnt = i-1
                    break

                if i == size - 1:
                    self.matrixOptimizedPath.append(self.start)

        self.matrixOptimizedPath.reverse()
        self.robotOptimizedPath = [(x*self.mapResolution,y*self.mapResolution) for y,x in self.matrixOptimizedPath]
        self.robotOptimizedPath[-1] = np.flip(exact)

        print('Total path : ', self.totalPath)
        print('Matrix optimized path : ', self.matrixOptimizedPath)
        print('Robot optimized path : ', self.robotOptimizedPath)

    def freePath(self, a, b):
        """
        Check if the path between 2 points is empty or not.

        Args:
            a  (np.array)  : point to start the check from
            b  (np.array)  : point to end the check at

        Returns:
            (bool) : the state of the [a,b] segment : free or not
        """

        a = np.asarray(a)
        b = np.asarray(b)
        size = int(np.linalg.norm(a - b))
        for s in range(size):
            point = a + s/size * (b - a)
            point = tuple(point.astype(int))
            if self.occupancyGrid[point] == 0:
                return False

        return True

    def createPlot(self):
        """
        Create empty plot. Useful for debugging !
        """
        fig, ax = plt.subplots(figsize=(7,7))
        ax.grid(which='minor', alpha=0.2)
        ax.grid(which='major', alpha=0.5)
        ax.grid(True)
        return fig, ax

    def savePlot(self):
        """
        Creates plot ot the A* path, start and goal nodes as well as the visited
        ones ; auto-save this plot in the current directory.
        This method is for debugging.
        """
        self.ax.imshow(self.occupancyGrid, cmap=self.cmap)
        self.ax.scatter([i[1] for i in self.closedSet], [i[0] for i in self.closedSet], marker=".", color = 'orange'); #again swap X and Y since matplotlib and opencv are indexing differently
        self.ax.plot([i[1] for i in self.totalPath], [i[0] for i in self.totalPath], marker=".", color = 'blue');
        self.ax.plot([i[1] for i in self.matrixOptimizedPath], [i[0] for i in self.matrixOptimizedPath], marker=".", color = 'green');
        self.ax.scatter(self.start[1], self.start[0], marker="o", color = 'green', s=100);
        self.ax.scatter(self.goal[1], self.goal[0], marker="o", color = 'purple', s=100);
        plt.savefig('A_STAR_{}.png'.format(self.start[0]))









"""
Main function : useful when debugging. Not used directly in the main script.

"""

if __name__ == '__main__':
    myMap = MAP(cam = 1, show = True) #open camera nb 1
    myMap.initializeWarp()
    while True:
        print('\n')
        ret, myMap.frame = myMap.cap.read()
        if ret :
            myMap.warpFrame()
            out = myMap.warpped.copy()
            myMap.extractObject()
            myMap.extractGoal()
            myMap.extractRobotPose()
            myMap.extractObstacles()
            myMap.verifyCatch()
            #myMap.drawGrid()

            cv2.imshow('Output', myMap.warpped)

            cv2.line(myMap.frame, (100,410), (500,296), (255,0,0), 1)

            cv2.imshow('Frame', myMap.frame)
            #myMap.display()
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break


    start = (myMap.robotMatrixPos[0], myMap.robotMatrixPos[1]) #convert to tuples
    goal = (myMap.goalPos[0], myMap.goalPos[1])
    print('START', start, 'STOP', goal)

    myPath = FINDPATH(myMap.mapResolution)
    myPath.A_Star(myMap.mapMatrix, start, goal)
    if myPath.found:
        print('Path has been retrieved !')
        myMap.ax.imshow(myMap.mapMatrix, cmap=myMap.cmap)
        myMap.ax.scatter([i[1] for i in myPath.closedSet], [i[0] for i in myPath.closedSet], marker=".", color = 'orange'); #again swap X and Y since matplotlib and opencv are indexing differently
        myMap.ax.plot([i[1] for i in myPath.totalPath], [i[0] for i in myPath.totalPath], marker=".", color = 'blue');
        myMap.ax.plot([i[1] for i in myPath.matrixOptimizedPath], [i[0] for i in myPath.matrixOptimizedPath], marker=".", color = 'green');
        myMap.ax.scatter(myPath.start[1], myPath.start[0], marker="o", color = 'green', s=100);
        myMap.ax.scatter(myPath.goal[1], myPath.goal[0], marker="o", color = 'purple', s=100);
        plt.show()


    # When everything done, release the capture
    myMap.cap.release()
    cv2.destroyAllWindows()





















#
