#!/usr/bin/env python3
import math

# describes an obstacle in the simulation
# obstacles are modelled as infinite height cylinders

class SimObstacle():
    def __init__(self, x, y, radius):

        self.x = x              # x coordinate of the node in space
        self.y = y              # y coordinate of the node in space
        self.radius = radius    #radius of the obstacle

    def isInObstacle(self,sx,sy):
        if math.sqrt( math.pow(self.x-sx,2) + math.pow(self.y-sy,2) ) < self.radius :
            return True
        return False