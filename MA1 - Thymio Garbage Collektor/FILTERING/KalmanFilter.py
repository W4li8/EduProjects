import math
import numpy as np

import time
import threading

from LOCAL_NAVIGATION.navigation import navigation

## using https://bit.ly/kalman_filter

class KalmanFilter:
    """
    Kalman filter for the state [x,y,θ] of the Thymio robot.
    Considering data from two sources: an external camera and onboard sensors.
    """
    def __init__(self, xi: np.ndarray) -> None:
        self.lock = threading.Lock()
        self.this_predict_time = None
        self.prev_predict_time = None

        self.Tsu2mm_s = 0.3268  # ——  Tsu (Thymio speed units) to mm/s conversion factor
        self.wheel_dist = 93    # mm  Thymio wheels' separation distance

        self.varThymioSpeed = np.eye(2) * 122.7979 * self.Tsu2mm_s**2  #* Measure Jean Tsu^2 -> mm^2/s^2
        self.varCameraPose = np.diag([6.5922, 6.5922, 1.0177 * (math.pi/180)**2])  #* Measures Jean [mm^2, mm^2, deg^2 -> rad^2]

        self.x = xi  # [x,y,θ] set to initial pose as seen by camera [mm, mm, rad]
        self.x[2] %= math.tau  # restrict θ to [0,2π]
        self.P = self.varCameraPose


    def predict(self, lspeed: int, rspeed: int) -> None:
        """
        Predicts the state of the Thymio from its speed input:
          - compute dt for integration of the speed
          - project actuator effect on the state
          - predict the state
        Send the state to Thymio.
        """
        with self.lock:
            self.this_predict_time = time.time()
            if self.prev_predict_time is not None:
                dt = self.this_predict_time - self.prev_predict_time

                hcostheta = dt * 0.5*math.cos(self.x[2])
                hsintheta = dt * 0.5*math.sin(self.x[2])
                inv_wdist = dt / self.wheel_dist

                B = np.array([[hcostheta, hcostheta], [hsintheta, hsintheta], [inv_wdist, -inv_wdist]])
                u = np.array([lspeed, rspeed]) * self.Tsu2mm_s

                self.x = self.x + B @ u  # predicted state estimate
                self.x[2] %= math.tau    # restrict θ to [0,2π]
                self.P = self.P + B @ self.varThymioSpeed @ B.T  # predicted error covariance

            self.prev_predict_time = self.this_predict_time

        # print(f'thymio state prediction: {self.x*np.array([1,1,180/np.pi])}')
        navigation.newPosition(*self.x)


    def update(self, z: np.ndarray) -> None:
        """
        Updates the state of the Thymio from camera measures:
          - minimise jump angle between measures
          - compute state error and Kalman gain
          - update the state
        Send the state to Thymio.
        """
        with self.lock:
            z[2] %= math.tau  # redefine measured angle between [0,2π]
            # handling cases where the angle between z and x jumps by more than PI
            if abs(z[2]-self.x[2]) > math.pi:
                z[2] += np.sign(self.x[2] - z[2])*math.tau

            y = z - self.x  # measurement residual
            K = self.P @ np.linalg.inv(self.P + self.varCameraPose)  # Kalman gain

            self.x = self.x + K @ y       # updated state estimate
            self.x[2] %= math.tau         # restrict θ to [0,2π]
            self.P = self.P - K @ self.P  # updated error covariance

        # print(f'camera state update: {self.x*np.array([1,1,180/np.pi])}')
        navigation.newPosition(*self.x)


if __name__ == '__main__':
    print(f'FYI: {__file__} is main :')
""" TESTS
    kf = KalmanFilter(np.array([0,0,0.1]))
    kf.update(np.array([0,0,np.pi-np.pi/10]))

    samples = np.array([0,0,0])
    for i in range(5_000_000):
        np.concatenate((samples, np.random.normal(0, 10, 3)))

    start = time.time()
    for s in samples:
        wait = time.time()
        kf.predict(100,100)
        kf.update(kf.x+s)
        time.sleep(0.001-(time.time()-wait))
    print(kf.x)
    print(start-time.time())
"""
