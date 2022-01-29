#!/usr/bin/env python3

from PyQt5 import QtWidgets, QtCore, QtGui
from pyqtgraph import PlotWidget, plot
import sys

import numpy as np

from enum import Enum, auto
from drone import Drone

from pilot import Pilot
from world_display import WorldDisplay

class MainWindow(QtWidgets.QMainWindow):
    def __init__(self, d):
        """ Initialize main window and keep a trace of common data dictionary in between processes
            - d: common dictionary as defined in main
        """

        super(MainWindow, self).__init__()

        self.d = d

        #defining our main widget and layout
        self.main_widget = QtWidgets.QWidget(self)
        self.setCentralWidget(self.main_widget)
        self.layout = QtWidgets.QVBoxLayout(self.main_widget)
        self.setWindowTitle("Mission controller")

        #define our world plotting widget
        self.displayWidget = WorldDisplay(d)
        self.layout.addWidget(self.displayWidget)

        # define our text output widget
        self.out_text = QtWidgets.QLabel("drone position")
        self.layout.addWidget(self.out_text)

        self.auto_update = False    # if True, live update the map
        self.nav_autority = False   # if True follow global nav waypoints, if False, fly manual (only follows waypoints when computed, so when auto_update is true)

        # set labels update timer
        self.timer = QtCore.QTimer()
        self.timer.setInterval(50)
        self.timer.timeout.connect(self.labelUpdate)
        self.timer.start()

    def printPose(self):
        """ Return string with drone's kalman state """

        pose = self.d['pose']
        out = "None pose\n"
        if pose is not None:
            out = "x = " + str(round(pose[0],3)) + "\n"
            out = out + "y = " + str(round(pose[1],3)) + "\n"
            out = out + "z = " + str(round(pose[2],3)) + "\n"
            out = out + "roll = " + str(round(pose[3],3)) + "\n"
            out = out + "pitch = " + str(round(pose[4],3)) + "\n"
            out = out + "yaw = " + str(round(pose[5],3))
        return out

    def labelUpdate(self):
        """ Display kalman state of drone in the window and global nav status """
        try:
            if self.d['map'] is not False and self.d['map'] is not None:
                state = self.d['map'].nav_state
            else:
                state = "None"
            self.out_text.setText("drone state : \n" + self.printPose() + "\nState = " + state )
            self.displayWidget._trigger_refresh()
        except:
            sys.exit()

    def keyPressEvent(self, event):  # reads keyboard events
        """ Handle key presses """
        key = event.key()

        if key == QtCore.Qt.Key_T:
            self.d['wait'] = False
            print("Take-off")

        if key == QtCore.Qt.Key_X:
            self.d['emergency_stop'] = True
            print("Emergency Stop")

        if key == QtCore.Qt.Key_M:
            self.d['display'] = "map"
            print("Map display")

        if key == QtCore.Qt.Key_P:
            self.d['display'] = "pot"
            print("Potential display")

def instanciateGui(d):
    """ Summons graphical user interface """
    sys.argv
    app = QtWidgets.QApplication(sys.argv)
    window = MainWindow(d)
    window.show()

    #crazypilot.skills_test()
    sys.exit(app.exec_())