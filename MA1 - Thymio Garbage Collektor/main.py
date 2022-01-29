import cv2
import matplotlib.pyplot as plt
import numpy as np

from VISION.vision import MAP
from VISION.vision import FINDPATH
from FILTERING.KalmanFilter import KalmanFilter
from LOCAL_NAVIGATION.navigation import navigation


if __name__ == '__main__' :
    myMap = MAP(cam = 1, show = True) #open camera nb 1, show all frames and masks
    myMap.initializeWarp()

    myPath = FINDPATH(myMap.mapResolution)

    myKF = None

    navigation.setup()

    #to store data in order to plot stuffs
    timeline = []
    plot_cam_x = []
    plot_cam_y = []
    plot_cam_angle = []
    plot_state_x = []
    plot_state_y = []
    plot_state_angle = []
    cnt = 0
    list_KF = []
    list_robot = []

    #auto save the video stream
    fourcc = cv2.VideoWriter_fourcc(*'X264')
    cameraOutput = cv2.VideoWriter('output.mkv', fourcc, 20., (970,770))
    mapOutput = cv2.VideoWriter('output_map.mkv', fourcc, 20., (970,770))

    while True:
        ret, myMap.frame = myMap.cap.read()
        if ret :
            # Setup Vision
            myMap.warpFrame()
            out = myMap.warpped.copy()
            myMap.extractObject()
            if myMap.goalPos is None: #goal pose is not supposed to be moved
                myMap.extractGoal()
            myMap.extractRobotPose()
            myMap.verifyCatch()
            # if myMap.mapMatrixCompleted is False:  #obstacles are not supposed to be moved
            myMap.extractObstacles()
            myMap.drawGrid()

            # Initialize Kalman filter
            cnt += 1  # plot timeline
            if myKF is None:
                if myMap.robotGlobalPose is not None:
                    myKF = KalmanFilter(myMap.robotGlobalPose)
                    navigation.registerVelocityCallback(myKF.predict)
                else:
                    continue

            # Go to target
            if myMap.error:
                print(myMap.errorMessage) #debugging
            else:
                if myPath.robotPathMode == 'OBJECT':
                    print('Going to object')
                    if not myPath.found or myPath.RobotIsFarFromPath(myMap.robotMatrixPos):
                        # print(tuple(myMap.robotMatrixPos), tuple(myMap.objectPos))
                        cv2.imshow('matrix', myMap.mapMatrix)
                        myPath.A_Star(myMap.mapMatrix, tuple(myMap.robotMatrixPos), tuple(myMap.objectPos), tuple(myMap.exactObject))
                        myPath.savePlot()
                        navigation.newPath(myPath.robotOptimizedPath[1:]) #giving the path from the next point

                    if myMap.robotIsCatching:
                        print('Changing Robot Path Mode to GOAL !')
                        myPath.robotPathMode = 'GOAL'
                        myPath.found = False #force to recompute path at next loop

                elif myPath.robotPathMode == 'GOAL':
                    print('Going to goal')
                    if not myPath.found or myPath.RobotIsFarFromPath(myMap.robotMatrixPos):
                        # print(tuple(myMap.robotMatrixPos), tuple(myMap.goalPos))
                        myPath.A_Star(myMap.mapMatrix, tuple(myMap.robotMatrixPos), tuple(myMap.goalPos), tuple(myMap.exactGoal))
                        myPath.savePlot()
                        navigation.newPath(myPath.robotOptimizedPath[1:])

            # Update robot pose if detected
            if 'LEFT_MEAN' not in myMap.errorMessage and 'RIGHT_MEAN' not in myMap.errorMessage:
                myKF.update(myMap.robotGlobalPose)


            # Kalman filter state vs camera state plot
            list_KF.append((int(myKF.x[0]),int(myKF.x[1])))
            list_robot.append((int(myMap.robotGlobalPose[0]), int(myMap.robotGlobalPose[1])))

            for p in list_KF:
                cv2.circle(out, p, 5, (255,0,0), -1)
            for p in list_robot:
                cv2.circle(out, p, 5, (0,255,0), -1)
            for i in range(len(myPath.robotOptimizedPath)-1):
                cv2.line(out, (myPath.robotOptimizedPath[i][0], myPath.robotOptimizedPath[i][1]), (myPath.robotOptimizedPath[i+1][0], myPath.robotOptimizedPath[i+1][1]), (255,0,255), 2)

            cameraOutput.write(out)
            mapOutput.write(myMap.warpped)
            cv2.imshow('Output', myMap.warpped)
            cv2.imshow('Frame', out)

            timeline.append(cnt)
            plot_cam_x.append(myMap.robotGlobalPose[0])
            plot_cam_y.append(myMap.robotGlobalPose[1])
            plot_cam_angle.append(np.rad2deg(myMap.robotGlobalPose[2])%360)
            plot_state_x.append(myKF.x[0])
            plot_state_y.append(myKF.x[1])
            plot_state_angle.append(np.rad2deg(myKF.x[2]))

            if cv2.waitKey(1) & 0xFF == ord('q'):
                cam_x, = plt.plot(timeline, plot_cam_x, label='Camera X', color='r')
                kal_x, = plt.plot(timeline, plot_state_x, label='Kalman X', color='m')
                cam_y, = plt.plot(timeline, plot_cam_y, label='Camera Y', color='b')
                kal_y, = plt.plot(timeline, plot_state_y, label='Kalman Y', color='c')
                cam_angle, = plt.plot(timeline, plot_cam_angle, label='Camera Angle', color='g')
                kal_angle, = plt.plot(timeline, plot_state_angle, label='Kalman Angle', color='y')

                plt.legend(handles=[cam_x, kal_x, cam_y, kal_y, cam_angle, kal_angle], loc='upper right')
                plt.show()
                #plt.savefig('kalman_test/kalman{}.png'.format(cnt))

    cameraOutput.release()
    cv2.destroyAllWindows()


