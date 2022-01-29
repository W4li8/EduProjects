#!/usr/bin/env python3

import networkx as nx               # deals with the graph objects and all the graph-theoretic stuff
import matplotlib.pyplot as plt     # plots stuff, u know what pyplot is
import math                         # proves the stability of Navier stokes
import random

def random_color():
    color_list = ['green','red','blue','gray','purple']
    return random.choice(color_list)

def colorFromSemantics(inp):
    if inp == "clear" :
        return 'green'
    if inp == "explored" :
        return 'purple'
    if inp == "blocked" :
        return 'red'
    if inp == "unexplored" :
        return 'blue'
    if inp == "unreachable" :
        return 'gray'
    if inp == "forbidden" :
        return 'magenta'

def colorFromPotential(inp,vmax):
    if inp == -1 : 
        return (0,0,0)
    if inp == 0:
        return (0,1,0)
    else:
        return (0.1,0.1,inp/20)

def colorFromConfidence(inp):

    if inp == 0:
        return (0,0,0)
    else:
        return (0,inp,0)

def colorNodes(nav):
    color_map = []
    for node in nav.G:
        color_map.append(colorFromSemantics(nav.G.nodes[node]['obj'].state ))
    return color_map



class GlobalDisplay():

    # Plots the navigation graph (as a graph object)
    def showGraph(nav):
        fig = plt.figure(figsize=(12,8), dpi= 100)
        sp = fig.add_subplot(111)
        sp.axis('equal')
        color_map = colorNodes(nav)
        nx.draw(nav.G,ax=sp,pos=nav.pos,node_color=color_map,edge_color="black",node_size=40)
        plt.show()

    def showTiling(nav,level):
        sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
        sy = (nav.height / nav.rows)  # spacing between nodes on the y axis


        # iterating through cells, displaying the grid
        fig, ax = plt.subplots(figsize=(12,8))


        for node in nav.coarse_tilings[level].nodes:

            col = random_color()
            for subnode in nav.coarse_tilings[level].nodes[node]["subnodes"]:
                # print(list(nav.coarse_tilings[level].nodes[node]["subnodes"]))
                cx = nav.G.nodes[subnode]['obj'].x
                cy = -nav.G.nodes[subnode]['obj'].y
                state = nav.G.nodes[subnode]['obj'].state

                # grid area
                rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=1, edgecolor='k', facecolor=col)
                ax.add_patch(rect)

        ax.axis('equal')
        plt.show()
    
    def showLevel(nav,level):
        if level == 0:
            GlobalDisplay.showPotential(nav)
        else:
            sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
            sy = (nav.height / nav.rows)  # spacing between nodes on the y axis


            # iterating through cells, displaying the grid
            fig, ax = plt.subplots(figsize=(12,8))


            for node in nav.coarse_tilings[level].nodes:

                col = colorFromPotential(nav.potential_of_supernode(node,level),nav.cs)
                for subnode in nav.coarse_tilings[level].nodes[node]["subnodes"]:
                    cx = nav.G.nodes[subnode]['obj'].x
                    cy = -nav.G.nodes[subnode]['obj'].y
                    state = nav.G.nodes[subnode]['obj'].state

                    # grid area
                    rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=1, edgecolor='k', facecolor=col)
                    ax.add_patch(rect)

            ax.axis('equal')
            plt.show()

    def showNavGraph(nav):
        fig = plt.figure(figsize=(12,8), dpi= 100)
        sp = fig.add_subplot(111)
        sp.axis('equal')
        nx.draw(nav.nG,ax=sp,pos=nav.pos,node_color="blue",edge_color="black",node_size=40)
        plt.show()

    # Plots the potential field used by the epsilon* algorithm
    def showPotential(nav):
        sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
        sy = (nav.height / nav.rows)  # spacing between nodes on the y axis

        # iterating through cells, displaying the grid
        fig, ax = plt.subplots(figsize=(12,8))

        for node in nav.G.nodes:
                cx = nav.G.nodes[node]['obj'].x
                cy = -nav.G.nodes[node]['obj'].y
                pot = nav.G.nodes[node]['obj'].pot
                col = colorFromPotential(pot,nav.cs)

                # grid area
                rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=1, edgecolor='k', facecolor=col)
                ax.add_patch(rect)

        ax.axis('equal')
        plt.show()

    # Plots the confidence map on the grid
    def showConfidence(nav):
        sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
        sy = (nav.height / nav.rows)  # spacing between nodes on the y axis

        # iterating through cells, displaying the grid
        fig, ax = plt.subplots(figsize=(12,8))

        for node in nav.G.nodes:
                cx = nav.G.nodes[node]['obj'].x
                cy = -nav.G.nodes[node]['obj'].y
                conf = nav.G.nodes[node]['obj'].confidence
                col = colorFromConfidence(conf)

                # grid area
                rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=1, edgecolor='k', facecolor=col)
                ax.add_patch(rect)

        ax.axis('equal')
        plt.show()


    # Plots the navigation graph (as a grid plot, with continous elements)
    def showGrid(nav, sim = False, mapContours = False, confidenceAsAlpha = False, save=None):
            sx = (nav.width  / nav.cols)  # spacing between nodes on the x axis
            sy = (nav.height / nav.rows)  # spacing between nodes on the y axis


            # iterating through cells, displaying the grid
            fig, ax = plt.subplots(figsize=(12,8))



            for node in nav.G.nodes:
                cx = nav.G.nodes[node]['obj'].x
                cy = -nav.G.nodes[node]['obj'].y
                state = nav.G.nodes[node]['obj'].state
                col = colorFromSemantics(state)

                # grid area
                if confidenceAsAlpha:
                    rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=0, facecolor=col,alpha = nav.G.nodes[node]['obj'].confidence)
                else:
                    rect = plt.Rectangle((cx-sx/2, cy-sy/2), sx, sy, linewidth=0, facecolor=col)

                ax.add_patch(rect)

                #node center
                # circ = plt.Circle((cx, cy), 1, color='k')
                # ax.add_patch(circ)
                    
            for i in range(0,len(nav.trace)-1):
                x_values = [nav.trace[i][0], nav.trace[i+1][0]]
                y_values = [-nav.trace[i][1], -nav.trace[i+1][1]]
                ax.plot(x_values, y_values,color='k')
            
            for i in range(0,len(nav.dtrace)-1):
                p1 = nav.gridToSpace(nav.dtrace[i][0],nav.dtrace[i][1])
                p2 = nav.gridToSpace(nav.dtrace[i+1][0],nav.dtrace[i+1][1])
                x_values = [p1[0], p2[0]]
                y_values = [-p1[1], -p2[1]]
                ax.plot(x_values, y_values,color='b')

            for point in nav.navPoints:
                circ = plt.Circle((point[0],-point[1]), 2, color='w', fill=False)
                ax.add_patch(circ)

            for cell in nav.navCells:
                point = nav.gridToSpace(cell[0], cell[1])
                circ = plt.Circle((point[0],-point[1]), 2, color='w', fill=False)
                ax.add_patch(circ)

            # # plotting the robot's pose (if there is a robot)
            dx = nav.drone_x
            dy = -nav.drone_y

            if sim != False:
                for ob in sim.obstacles:
                    circ = plt.Circle((ob.x,-ob.y), ob.radius, color='r', alpha = 0.3)
                    ax.add_patch(circ)

                for det in sim.detections:
                    circ = plt.Circle((det[0],-det[1]), 1, color='k')
                    ax.add_patch(circ)
                
                for col in sim.collisions:
                    circ = plt.Circle((col[0],-col[1]), 3, color='k')
                    ax.add_patch(circ)

                for i in range(0,len(sim.intTrace)-1):
                    x_values = [sim.intTrace[i][0], sim.intTrace[i+1][0]]
                    y_values = [-sim.intTrace[i][1], -sim.intTrace[i+1][1]]
                    ax.plot(x_values, y_values,color='r')

            circ = plt.Circle((dx, dy), 4, color='y')
            ax.add_patch(circ)

            if mapContours:
                rect = plt.Rectangle((0, 0), 500, -300, linewidth=2, edgecolor='cyan', facecolor=col, fill=False)
                ax.add_patch(rect)
                rect = plt.Rectangle((0, 0), 150, -300, linewidth=2, edgecolor='cyan', facecolor=col, fill=False)
                ax.add_patch(rect)
                rect = plt.Rectangle((350, 0), 150, -300, linewidth=2, edgecolor='cyan', facecolor=col, fill=False)
                ax.add_patch(rect)
            ax.axis('equal')
            plt.show()

            if save is not None:
                plt.savefig(save)