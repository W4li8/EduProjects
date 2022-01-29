#!/usr/bin/env python3

import random
from simulation.sim_obstacle import SimObstacle

class Simulator():
    def __init__(self, nav, sigma_flight, sigma_sense = 0.2, int_error = 0):
        self.nav = nav          # global nav object
        self.sigma_flight = sigma_flight    # variance of gaussian noise in modeled flight
        self.sigma_sense = sigma_sense      # variance of gaussian noise in modeled flight
        self.int_error = int_error          # variance of integrated gaussian noise in modeled flight
        self.obstacles = []     # empty obstacle list when initializing the simulation
        self.detections = []
        self.collisions = []
        self.intTrace = []
        self.adx = 0
        self.ady = 0
        self.bx = random.gauss(0,self.int_error/10)
        self.by = random.gauss(0,self.int_error/10)

    #simulates robot movement and adds random noise
    def waypoint_line(self,wx,wy):
        self.adx = self.adx + random.gauss(self.bx,self.int_error) 
        self.ady = self.ady + random.gauss(self.by,self.int_error) 
        ox = random.gauss(wx,self.sigma_flight)
        oy = random.gauss(wy,self.sigma_flight)
        self.intTrace.append((ox - self.ady, oy - self.ady))
        return ox, oy

    def add_obstacle(self,x,y,r):
        self.obstacles.append(SimObstacle(x,y,r))

    def sense(self):
        sample_nb = 50
        dist = 2

        for dir in range(4):
            for di in range(sample_nb):
                flag = False
                d = di * dist
                sx = self.nav.drone_x+self.adx
                sy = self.nav.drone_y+self.ady

                if dir == 0:
                    sx = sx + d
                if dir == 1:
                    sx = sx - d
                if dir == 2:
                    sy = sy + d
                if dir == 3:
                    sy = sy - d
                if len(self.obstacles) > 0:
                    for ob in self.obstacles:
                        smx = random.gauss(sx,self.sigma_sense)-self.adx
                        smy = random.gauss(sy,self.sigma_sense)-self.ady
                        if ob.isInObstacle(sx,sy):    
                            self.detections.append((smx,smy))
                            flag = True
                            [c,r] = self.nav.spaceToGridRound(smx-self.adx,smy-self.ady)
                            self.nav.block(c,r)
                        else :
                                
                            [c,r] = self.nav.spaceToGridRound(smx-self.adx,smy-self.ady)
                            self.nav.sense_clear(c,r)
                else :
                    smx = random.gauss(sx,self.sigma_sense)+self.adx
                    smy = random.gauss(sy,self.sigma_sense)+self.ady
                        
                    [c,r] = self.nav.spaceToGridRound(smx-self.adx,smy-self.ady)
                    self.nav.sense_clear(c,r)
                if flag:
                    break
        
    def check_collisions(self):
        for ob in self.obstacles:
                if ob.isInObstacle(self.nav.drone_x-self.adx,self.nav.drone_y-self.ady):
                    self.collisions.append((self.nav.drone_x-self.adx,self.nav.drone_y-self.ady))
                        