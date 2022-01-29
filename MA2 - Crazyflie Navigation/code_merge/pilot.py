import json
import time
import threading
import numpy as np
import copy
import math
import random

from drone import Drone
from global_nav import GlobalNav

def cm_to_m(val,coord):
    """ Convert centimeters to pixels
        - val: value to convert
        - coord: "x" or "y" index
    """
    if coord == "x":
        return val/100
    if coord == "y":
        return val/100
    return None


class Pilot:
    def __init__(self, mission_file):
        """ Read mission_file formatted in json as detailed in user_help.txt
            - mission_file: string with path to mission file
        """
        with open(mission_file, mode="r") as j_object:
            data = json.load(j_object)

        self.emergency_stop = False

        # flight settings
        self.drone_uri = data["drone_uri"]
        self.drone_pose = data["init_pose"]
        self.flight_altitude = data["flight_altitude"]
        self.cruise_speed = data["cruise_speed"]
        self.manoeuver_speed = data["manoeuver_speed"]
        self.safety_distance = data["safety_distance"]
        self.platform_dim = data["platform_dimensions"]

        self.land_pose = None

        # init drone
        self.drone = Drone(
            self.drone_uri,
            self.drone_pose,
            self.flight_altitude,
            self.cruise_speed
        )

        self.glonav = GlobalNav(
            width = 540,
            height = data["world_dimensions"][1]*100,
            cols = 18,
            rows = 10,
            drone_x = data["init_pose"][0]*100,
            drone_y = data["init_pose"][1]*100,
            diag = False,
            decay = 0.035,
            radius = 1
        )

        # environment analysis thread flags
        self.analyze_environment = None  # active or inactive, manipulated at takeoff and landing
        self.platform_edge_detected = None

        self.moving_dict = {"front" : self.drone.hlcontroller.forward,
                       "back"  : self.drone.hlcontroller.back,
                       "left"  : self.drone.hlcontroller.left,
                       "right" : self.drone.hlcontroller.right}

        self.reverse_dict = {"front" : "back",
                        "back"  : "front",
                        "left"  : "right",
                        "right" : "left"}

        self.d = None

        self.edgeList = []
        self.position = []

    def get_map_pose(self):
        """ Update and Return current pose estimate in real world coordinates """
        self.drone_pose = self.drone.get_pose()
        return self.drone_pose

    def take_off(self):
        """ Take off and start thread for environment analysis """

        if self.drone.get_multiranger() is None:
            print("Sensors are down, don't take")
            raise(AssertionError)

        self.drone.reset_estimator()

        self.drone.hlcontroller.take_off()
        self.drone_pose = self.drone.get_pose()

        self.analyze_environment = True
        time.sleep(2)
        threading.Thread(target=self.environment_analysis_thread).start()

    def land(self, centering=True):
        """ Center the drone above the platform and land it
            - centering : boolean, if the landing is done with centering or not.
        """

        def scan(start, direct, step, step_number):
            """ Scan the environment in a discrete manner from a start position toward a target position
                - start : array defining the start position
                - direct : direction of exploration
                - stepnumber : number of discrete steps to take during exploration
            """
            while self.platform_edge_detected:
                time.sleep(0.1)

            for i in range(1,int(step_number)+1):
                goal = start + direct * step * i
                self.drone.move_to(goal,self.manoeuver_speed)
                if min(self.drone.get_multiranger()) < 0.3:
                    break



        def centroid(edgeList):
            """ Return the centroid of points stored in a list
                - edgeList: list of points whose centroid is ot be determined
            """
            xs = [el[0] for el in edgeList]
            ys = [el[1] for el in edgeList]
            xc = (max(xs)-min(xs))/2 + min(xs)
            yc = (max(ys)-min(ys))/2 + min(ys)

            return np.array([xc,yc])

        def spread(edgeList):
            """ Compute the minimal spread between points
                - edgeList : list of points whose spread is to be determined
            """
            xs = np.array([el[0] for el in edgeList])
            ys = np.array([el[1] for el in edgeList])

            x_width = np.max(xs)-np.min(xs)
            y_width = np.max(ys)-np.min(ys)

            return min(x_width,y_width)

        def compute_direct(recursions):
            """ Return the direction for the landing centering pattern based on previous
                position in the global navigation module.
                - recursions : int, the number of iterations that was conducted until now.
            """

            waypoint_2 = np.array([cm_to_m(self.glonav.trace[-2][0],"x"),cm_to_m(self.glonav.trace[-2][1],"y")])
            waypoint_1 = np.array([cm_to_m(self.glonav.trace[-1][0],"x"),cm_to_m(self.glonav.trace[-1][1],"y")])
            direct = waypoint_2 - waypoint_1

            mv = recursions % 4
            if mv == 1:
                mv = 0
            elif mv == 2:
                mv = 1
            elif mv == 3:
                mv = 3
            elif mv == 0:
                mv = 2

            angle = (mv * np.pi/2) + np.arctan2(direct[1],direct[0]) - np.pi
            direct = np.array([np.cos(angle),np.sin(angle)])
            print("angle = " + str(angle*(180/np.pi)))
            return direct

        time.sleep(1)

        if centering and self.emergency_stop == False:
            step = 0.2
            scan_length = 0.6
            S = 0.3

            spread_data = []

            recursions = 0
            while (spread(self.edgeList) < S or recursions < 4) and recursions < 16:
                print("recursion : " + str(recursions))
                print("centering")

                if recursions%4 == 0 and recursions > 0:
                    self.drone.move_to(centroid(self.edgeList),self.manoeuver_speed)

                # wait to avoid double detection
                while self.platform_edge_detected:
                    time.sleep(0.1)

                virtual_direct = compute_direct(self.edgeList, recursions)*scan_length
                start = self.drone.get_pose()[:2]
                direct = (virtual_direct+centroid(self.edgeList))-start

                print("scan")
                scan(start,direct,step,np.linalg.norm(direct)//step,self.edgeList)
                recursions = recursions + 1

                spread_data.append(spread(self.edgeList))
                np.save("spread_data",spread_data)
                np.save("edgeList",self.edgeList)

            self.drone.move_to(centroid(self.edgeList),self.manoeuver_speed)

            print("Landing on platform (hopefully)")

        time.sleep(1)
        # logging data
        np.save('edge_list', self.edgeList)
        self.analyze_environment = False
        self.land_pose = self.drone.get_pose()
        self.drone.hlcontroller.land()
        self.drone_pose = self.drone.get_pose()
        self.platform_edge_detected = False

    def environment_analysis_thread(self):
        """ Analyze environment to detect platform edges, obstacles and the unknown """

        def isInLZ():
            """ Returns true if the drone is in the landing zone """
            return self.glonav.is_in_cover_area(self.glonav.dc,self.glonav.dr)

        # infinite loop scanning environment through multiranger measures
        k_z = self.drone.get_pose()[2]
        flt1 = k_z
        prev_flt1 = k_z
        flt2 = 0
        thresh = 0.001
        prev_detect = False

        alpha1 = 5e-2
        alpha2 = 0.1

        kalmanZ = []
        rangers = []
        cnt = 0
        while self.analyze_environment:
            cnt += 1
            rangers.append(self.drone.get_multiranger())
            self.position.append(self.drone.get_pose())
            # debug logging values
            if cnt%10 == 0:
                np.save("rangers",rangers)
                np.save("position",self.position)

            curr_altitude = self.drone.multiranger.down
            if curr_altitude is not None:
                # look for platform
                prev_flt1 = flt1
                flt1 = alpha1*curr_altitude + (1-alpha1)*flt1
                diff = np.abs(flt1 - prev_flt1)
                flt2 = alpha2 * diff + (1-alpha2)*flt2

                # debug
                k_z = self.drone.get_pose()[2]
                kalmanZ.append(k_z)
                np.save("kalmanZ", kalmanZ)

                prev_detect = self.platform_edge_detected
                if isInLZ():
                    if flt2 > thresh:
                        self.platform_edge_detected = True
                    else:
                        self.platform_edge_detected = False

                    #rising edge on the edge detection, add edge to list
                    if self.platform_edge_detected == True and prev_detect == False:
                        self.edgeList.append(self.drone.get_pose()[:2])
                        print(self.edgeList)

            # transmitting data to the other process
            if self.d is not None:
                self.d['pose'] = copy.deepcopy(self.drone.get_pose())
                self.d['rangers'] = copy.deepcopy(self.drone.get_multiranger())

            time.sleep(0.1)  # slow down refresh rate


    def fly_to_waypoint(self, waypoint):
        """ Fly to waypoint and update drone pose
            - waypoint: list [x, y] [m, m]
        """
        self.drone.move_to(waypoint)
        self.drone_pose = self.drone.get_pose()
        self.d['map'] = self.glonav

    def follow_navigation(self):
        """ Follow navigation waypoints until platform detected """

        data = []
        i = 0
        while not self.platform_edge_detected and not self.emergency_stop:
            i += 1
            waypoint_cm = self.glonav.get_waypoint(self.drone.get_pose(),self.drone.get_multiranger(),0.1)
            waypoint = (cm_to_m(waypoint_cm[0],"x"),cm_to_m(waypoint_cm[1],"y"))
            self.fly_to_waypoint(waypoint)
            data.append(self.drone.get_pose())
            self.emergency_stop = self.d['emergency_stop']
            if i % 2 == 0:
                np.save("data", data)


    def fly_mission(self, d):
        """ Crazyflie project main FSM, with safe exit in case of mishap
            d : shared dictionnary between the processes
        """
        wait = True
        self.d = d
        self.d['map'] = self.glonav

        self.glonav.cover_area(13,0,17,9)
        while wait:
            time.sleep(0.01)
            wait = bool(self.d["wait"])
        # try:
        print("Fly mission")
        # for mission_step in ("Go to destination", "Come back home"):
        if not self.emergency_stop:
            # print(mission_step)
            # perform flight
            print("before take off")
            self.take_off()

            print("before follow navigation")
            self.follow_navigation()
            print("before landing")
            self.land()
            # signal arrival


            self.glonav.cover_area(0,0,6,9)
            self.glonav.map_reset()
            self.edgeList = []

            self.drone.coords_offset = self.land_pose
            time.sleep(2)
            print("before take off")
            self.take_off()

            print("before follow navigation")
            self.follow_navigation()


            print("before landing")
            self.land()

    def skills_test(self):
        """ Try out pilot capabilities, autonomous mission, manual control, sensor readings, quit available """

        while True:
            cmd = input("skills test action ")

            if cmd == "FM":
                self.fly_mission()

            # manual control options
            elif cmd == "T":
                self.drone.hlcontroller.take_off()
                self.drone_pose = self.drone.get_pose()
            elif cmd == "W":
                self.drone.hlcontroller.forward(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "S":
                self.drone.hlcontroller.back(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "A":
                self.drone.hlcontroller.left(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "D":
                self.drone.hlcontroller.right(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "Y":
                self.drone.hlcontroller.up(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "X":
                self.drone.hlcontroller.down(0.1)  # , velocity=self.cruise_speed)
                self.drone_pose = self.drone.get_pose()
            elif cmd == "L":
                self.drone.hlcontroller.land()
                self.drone_pose = self.drone.get_pose()

            # specific algorithms
            elif cmd == "C1":
                self.take_off()
            elif cmd == "C2":  # platform centering
                self.land()

            # access variables
            elif cmd == "P":  # expected drone pose [x, y, z, yaw]
                print(self.drone_pose[:3], self.drone_pose[-1])
            elif cmd == "R":  # multiranger values
                print(
                    f"RangerU {self.drone.multiranger.up} RangerD {self.drone.multiranger.down}"
                    f"RangerL {self.drone.multiranger.left} RangerR {self.drone.multiranger.right}"
                    f"RangerF {self.drone.multiranger.front} RangerB {self.drone.multiranger.back}"
                )

            # quit skills test
            elif cmd == "Q":
                self.analyze_environment = False  # proper thread exit
                self.drone.hlcontroller.land()  # just in case
                break
            else:
                print("Invalid input")

            print(self.drone_pose[:3], self.drone_pose[-1])

    def exit(self):
        """ Properly exit the pilot class """
        self.emergency_stop = True
        self.analyze_environment = False
        self.drone.exit()
