from PyQt5 import QtWidgets, QtCore, QtGui
from PyQt5.QtCore import Qt

from pyqtgraph import PlotWidget, plot
import networkx as nx

import math


def colorFromSemantics(inp,conf):
    """ Return color according to cell semantic meaning and confidence
        - input: semantic meaning
        - conf: condifence on value
    """
    if inp == "clear" :
        return QtGui.QColor(255*(1-conf) + conf*0, 255*(1-conf) + conf*255, 255*(1-conf) + conf*0)
    if inp == "explored" :
        return QtGui.QColor(255*(1-conf) + conf*255, 255*(1-conf) + conf*100, 255*(1-conf) + conf*100)
    if inp == "blocked" :
        return QtGui.QColor(255*(1-conf) + conf*255, 255*(1-conf) + conf*0, 255*(1-conf) + conf*0)
    if inp == "unexplored" :
        return QtGui.QColor(255*(1-conf) + conf*0, 255*(1-conf) + conf*0, 255*(1-conf) + conf*255)
    if inp == "unreachable" :
        return QtGui.QColor(255*(1-conf) + conf*80, 255*(1-conf) + conf*80,255*(1-conf) + conf*80)
    if inp == "forbidden" :
        return QtGui.QColor(255*(1-conf) + conf*255,255*(1-conf) + conf* 0,255*(1-conf) + conf*255)

def colorFromPotentials(pot):
    """ Adapt color value to potential on the map
        - pot: potential field value
    """
    if pot == -1:
        return QtGui.QColor(0 , 40, 40)
    return QtGui.QColor(255*(pot/20) , 40, 40)

def m_to_pixel(val,coord):
    """ Return meters converted to pixel coordinates
        - coord: string "x" or "y"
        - val: value in meters
    """
    if coord == "x":
        return 100 + val*100
    if coord == "y":
        return 300-val*100+100
    return None

def cm_to_pixel(val,coord):
    """ Return meters converted to pixel coordinates
        - coord: string "x" or "y" to select coordinate
        - val: value in pixels
    """
    if coord == "x":
        return 100 + val
    if coord == "y":
        return 300-val+100
    return None

class WorldDisplay(QtWidgets.QWidget):

    def __init__(self, d, *args, **kwargs):
        """ Initialize a resizeable world display
            - d: dictionary shared between two processes defined in main.py
            - others: Qt required arguments
        """
        super().__init__(*args, **kwargs)

        self.setSizePolicy(
            QtWidgets.QSizePolicy.MinimumExpanding,
            QtWidgets.QSizePolicy.MinimumExpanding
        )
        self.d = d

    def sizeHint(self):
        """ Default widget size """
        return QtCore.QSize(700,500)

    def paintEvent(self, e):
        """ Display world representation """

        painter = QtGui.QPainter(self)

        # set the background:
        brush = QtGui.QBrush()
        brush.setColor(QtGui.QColor(255, 255, 255))
        brush.setStyle(Qt.SolidPattern)
        rect = QtCore.QRect(0, 0, painter.device().width(), painter.device().height())
        painter.fillRect(rect, brush)


        if self.d['map'] is not None:
            # define constants, cell sizes
            nav = self.d['map']
            sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
            sy = (nav.height / nav.rows)  # spacing between nodes on the y axis

            # draw grid cells
            for node in nav.G.nodes:
                cx = cm_to_pixel(nav.G.nodes[node]['obj'].x,"x")
                cy = cm_to_pixel(nav.G.nodes[node]['obj'].y,"y")
                state = nav.G.nodes[node]['obj'].state
                if self.d['display']=="pot":
                    brush.setColor(colorFromPotentials(nav.G.nodes[node]['obj'].pot))
                else:
                    brush.setColor(colorFromSemantics(state,nav.G.nodes[node]['obj'].confidence))
                brush.setStyle(Qt.SolidPattern)
                rect = QtCore.QRect(cx-sx/2, cy-sy/2, sx, sy)
                painter.fillRect(rect, brush)

        painter.setPen(QtGui.QPen(Qt.black,  5, Qt.SolidLine))
        painter.drawRect(100, 100, 540, 300)

        if self.d['pose'] is not None:
            drone_x = m_to_pixel(self.d['pose'][0],"x")
            drone_y = m_to_pixel(self.d['pose'][1],"y")
            yaw = (self.d['pose'][-1]/180)*math.pi

            # draw drone
            path = QtGui.QPainterPath()
            path.moveTo(drone_x+8*math.cos(yaw+2*math.pi/3),drone_y+8*math.sin(yaw+2*math.pi/3))
            path.lineTo(drone_x+8*math.cos(yaw),drone_y+8*math.sin(yaw))
            path.lineTo(drone_x+8*math.cos(yaw-2*math.pi/3),drone_y+8*math.sin(yaw-2*math.pi/3))
            painter.setBrush(QtCore.Qt.blue)
            painter.drawPath(path)

            # draw ranger value lines
            if self.d['rangers'] is not None:
                painter.setPen(QtGui.QPen(Qt.red,  2, Qt.DotLine))

                if self.d['rangers'][0] is not None:
                    front_sensor = self.d['rangers'][0]*100
                    painter.drawLine(drone_x, drone_y, drone_x+ math.cos(yaw) * front_sensor, drone_y +math.sin(yaw) * front_sensor)
                if self.d['rangers'][1] is not None:
                    back_sensor = self.d['rangers'][1]*100
                    painter.drawLine(drone_x, drone_y, drone_x+ math.cos(yaw+math.pi) * back_sensor, drone_y +math.sin(yaw+math.pi) * back_sensor)
                if self.d['rangers'][2] is not None:
                    left_sensor = self.d['rangers'][3]*100
                    painter.drawLine(drone_x, drone_y, drone_x+ math.cos(yaw+math.pi/2) * left_sensor, drone_y +math.sin(yaw+math.pi/2) * left_sensor)
                if self.d['rangers'][3] is not None:
                    right_sensor = self.d['rangers'][2]*100
                    painter.drawLine(drone_x, drone_y, drone_x+ math.cos(yaw-math.pi/2) * right_sensor, drone_y +math.sin(yaw-math.pi/2) * right_sensor)

        painter.end()

    def _trigger_refresh(self):
        """ Update display screen """
        self.update()