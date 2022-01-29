
from .Thymio import Thymio, Message

import math
from threading import Lock

class _Navigation:
    ID_NEW_POSITION = 0
    ID_NEW_TARGET = 1
    ID_STOP = 2
    ID_VELOCITY = 3
    ID_TARGET_ACK = 4
    ID_STOP_ACK = 5
    ID_DEBUG = 6

    def __init__(self):
        self.t = None
        self.velocities = (0,0)
        self.callback = None
        self.path = []
        self.counter = 0
        self.targetAckPending = False
        self.stopAckPending = False
        self.lock = Lock()

    def setup(self, serialPort=None):
        """Open a serial link to the Thymio, if serialPort is not given it is guessed."""
        self.t = Thymio.serial(serialPort)
        self.t.register_callback(self.ID_VELOCITY, self._velocityCallback)
        self.t.register_callback(self.ID_TARGET_ACK, self._targetAckCallback)
        self.t.register_callback(self.ID_STOP_ACK, self._stopAckCallback)
        self.t.register_callback(self.ID_DEBUG, self._debugCallback)

    def newPosition(self, x, y, angle):
        """Sends a new position to the robot"""
        x = int(x)
        y = int(y)
        x %= 1<<16
        x %= 1<<16
        angle *= (1<<16)/math.tau
        angle = int(round(angle)) % (1<<16)
        self.t.send_event(self.ID_NEW_POSITION, [x,y,angle])

        with self.lock:
            if self.path :
                delta_x = x - self.path[0][0]
                delta_y = y - self.path[0][1]
                if math.sqrt(delta_x**2 + delta_y**2) < 20:
                    if len(self.path) > 1 :
                        self.targetAckPending = True
                    else:
                        self.stopAckPending = True
        if self.targetAckPending:
            self.newTarget(*self.path[1])
        if self.stopAckPending:
            self.t.send_event(self.ID_STOP, [])


    def newTarget(self, x, y):
        """Sends a new target to the robot."""
        x = int(x)
        y = int(y)
        if x < 0:
            x += 1<<16
        x %= 1<<16
        if y < 0:
            y += 1<<16
        y %= 1<<16
        print('newTarget : ', x,y)
        self.t.send_event(self.ID_NEW_TARGET, [x, y])

    def newPath(self, path):
        """Register the path that the robot should follow and send the first point to the Thymio."""
        with self.lock:
            self.path = path
            if path:
                self.path = [(0,0)] + self.path
                print(self.path)
                self.newTarget(*self.path[1])
                self.targetAckPending = True
            else:
                self.t.send_event(self.ID_STOP, [])

    def registerVelocityCallback(self, callback):
        """Register a callback to handle the velocity reading. It will be called from a different thread"""
        self.callback = callback

    def _velocityCallback(self, v_left, v_right):
        """Internal callback to handle the velocity reading.
           Also checks the buffer size to detect real-time problems"""
        if self.t.io.in_waiting > 20:
            print("Warning: buffer full")
        self.velocities = (v_left, v_right)
        self.counter += 1
        if self.counter == 10:
            self.counter = 0
            if self.callback:
                self.callback(v_left, v_right)

    def _targetAckCallback(self, x, y):
        with self.lock:
            print("New target ack: ",x,y)
            if self.path and len(self.path) > 1 and x == self.path[1][0] and y == self.path[1][1]:
                self.targetAckPending = False
                self.path = self.path[1:]

    def _stopAckCallback(self):
        print("Stop ack")
        self.stopAckPending = False

    def _debugCallback(self, *args, **kwargs):
        pass
        #print("Debug:")
        #print(args)

navigation = _Navigation()
