import cflib.crtp
from logger import Logger
from cflib.crazyflie.syncCrazyflie import SyncCrazyflie
from cflib.positioning.position_hl_commander import PositionHlCommander
from cflib.utils.multiranger import Multiranger

import time
import numpy as np


class Drone:
    def __init__(self, drone_uri, init_pose, flight_altitude, cruise_speed):
        """ Setup drone modules with given default values
            - drone_uri: string with the drone's raw uniform resource identifier
            - init_pose: list [x, y, z, roll, pitch, yaw] [m, m, m, rad, rad, rad]
            - flight_altitude: float [m]
            - cruise_speed: float [m/s]
        """
        cflib.crtp.init_drivers()
        try:
            self.crazyflie = SyncCrazyflie(drone_uri)
            self.logger = Logger(self.crazyflie.cf)
            self.crazyflie.open_link()  # auto closes upon program exit
        except:
            print("Connection to drone failed")

        # setup position controller - have to init at origin and offset afterwards to avoid crashes
        self.hlcontroller = PositionHlCommander(
            self.crazyflie, x=0, y=0, z=0,
            default_height=flight_altitude,
            default_velocity=cruise_speed,
        )
        self.coords_offset = np.array(init_pose)

        # setup sensors
        self.multiranger = Multiranger(self.crazyflie)
        self.multiranger.start()

    def move_to(self, coords, speed=None):
        """ Move drone to the desired world coordinates, considering the initial starting point offset
            - coords: list [x, y] [m, m]
            - speed : float, flight speed, [m/s]
        """

        x, y = np.array(coords) - self.coords_offset[:2]
        self.hlcontroller.go_to(x, y,velocity=speed)


        self.hlcontroller._x = np.array(self.logger.estimated_pose)[0]
        self.hlcontroller._y = np.array(self.logger.estimated_pose)[1]
        self.hlcontroller._z = np.array(self.logger.estimated_pose)[2]

    def get_pose(self):
        """ Return best drone pose estimate in world coordinates [m] """

        onboard_estimate_world = np.array(self.logger.estimated_pose) + self.coords_offset

        return onboard_estimate_world

    def get_multiranger(self):
        """ Return side sensor readings, distance to object [m] """
        return (
            self.multiranger.front,
            self.multiranger.back,
            self.multiranger.left,
            self.multiranger.right,
        )

    def get_battery_voltage(self):
        """ Return the batter voltage """
        return round(self.logger.battery_voltage, 2)

    def reset_estimator(self):
        """ This is a copy of the private estimator reset called upon take_off in the cflib library,
            for some magic reason it helps to call this separately for better yaw control.
        """
        self.hlcontroller._cf.param.set_value("kalman.resetEstimation", "1")
        time.sleep(0.1)
        self.hlcontroller._cf.param.set_value("kalman.resetEstimation", "0")
        time.sleep(2)

    def exit(self):
        """ Close the drone's link. """
        self.crazyflie.close_link()
