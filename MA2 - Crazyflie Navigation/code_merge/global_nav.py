#!/usr/bin/env python3

import networkx as nx
from nav_node import NavNode
from copy import deepcopy
import sys
import math


class GlobalNav():
    def __init__(self, width, height, cols, rows, drone_x = 0, drone_y = 0, diag = False, decay = 0.025, radius = 2):
        """ Create a map and define parameters for global navigation
            - width: world map width [cm]
            - height: wolrd map height [cm]
            - cols: number of columns to divide width by
            - rows: number of columns to divide height by
            - drone_x: initial drone position x
            - drone_y: initial drone position y
            - diag: enable/disable diagonal path planning
            - decay: decay rate of the confidence value on contents of each cell
            - radius: obstacle influence cells: 1 or 2 only
        """

        self.width = width      # actual width of the arena (in cm)
        self.height = height    # actual height of the arena (in cm)
        self.cols = cols        # width of the arena (in # of collumns)
        self.rows = rows        # height of the arena (in # of collumns)

        # Covering path planner parameter
        self.init_cover = False # false until the cover area is initialized
        self.c1 = 0             # lower c bound of the cover area
        self.c2 = 0             # upper c bound of the cover area
        self.r1 = 0             # lower r bound of the cover area
        self.r2 = 0             # upper r bound of the cover area
        self.cs = 0             # max pot val (used for display)
        self.coarse_tilings = dict() # coarse tiling datastructure (used for global minimum)
        self.levels = 0 # coarse tiling datastructure (used for global minimum)
        self.nav_state = "init"
        self.nav_wp = None

        self.radius = radius

        # confidence decay parameters
        self.decay = decay

        self.next_waypoint= None
        self.goal_waypoint = None

        self.path = None

        # generating the map
        self.diag = diag
        self.map_reset()

        # position drone
        self.drone_x = drone_x  # actual position x of the robot (in cm)
        self.drone_y = drone_y  # actual position y of the robot (in cm)
        self.trace = [(drone_x,drone_y)]    # trace of the drone coordinates

        drone_grid = self.spaceToGrid(self.drone_x,self.drone_y)

        self.dc = drone_grid[0] # grid position x of the drone
        self.dr = drone_grid[1] # grid position y of the drone

        self.visit(self.dc, self.dr)


        self.dtrace = [(self.dc, self.dr)]    # trace of the drone coordinates

        self.navPoints = []
        self.navCells = []


    def gridToSpace(self, col, row):
        """ Converts grid coordinates to space coordinates
            - col: column index
            - row: row index
        """
        sx = (self.width  / self.cols)  # spacing between nodes on the x axis
        sy = (self.height / self.rows)  # spacing between nodes on the y axis

        x = col * sx + sx / 2
        y = row * sy + sy / 2
        return [x, y]

    def spaceToGrid(self, x, y, delta = 2):
        """ Converts space coordinates to grid coordinates
            - x: float x map coordinates [cm]
            - y: float y map coordinates [cm]
            - delta: search radius under blocking conditions (robustness you know)
        """
        sx = (self.width  / self.cols)  # spacing between nodes on the x axis
        sy = (self.height / self.rows)  # spacing between nodes on the y axis

        c = int(round(x/sx - 0.5))
        r = int(round(y/sy - 0.5))
        # if the rounding puts us in cell that exists and is not occupied then all good
        if self.nG.has_node((c,r)):
            return [c,r]
        # else choose the minimum distance cell satisfying the requirements
        else:
            minDist = sys.float_info.max
            mincoords = False
            for ci in range(c-delta,c+delta+1):
                for ri in range(r-delta,r+delta+1):
                    if ci != c or ri != r:
                        if self.nG.has_node((ci,ri)):
                            [cx,cy] = self.gridToSpace(ci,ri)
                            dist = math.sqrt( math.pow(x-cx,2)  + math.pow(y-cy,2) )
                            if dist < minDist:
                                minDist = dist
                                mincoords = [ci,ri]

            # if we couldnt map coordinates to a node at this point, call the panic function
            if mincoords == False:
                mincoords = self.panic(x,y)
            return mincoords

    def panic(self,x,y):
        """ Fallback option when out of bounds - no nearby cell corresponds
            - x: float x map coordinates [cm]
            - y: float y map coordinates [cm]
        """
        minDist = sys.float_info.max
        dest = None

        # try to assign current node to closes clear node (L2 norm)
        for node in self.G.nodes:
            if self.G.nodes[node]['obj'].state == "unexplored" or self.G.nodes[node]['obj'].state == "clear"  or self.G.nodes[node]['obj'].state == "explored":
                nx = self.G.nodes[node]['obj'].x
                ny = self.G.nodes[node]['obj'].y
                dist = math.sqrt( math.pow(nx-x,2) + math.pow(ny-y,2) )
                if dist < minDist:
                    minDist = dist
                    dest = node

        # the only way dest is still unassigned at this point is that every single node on the map is blocked
        if dest == None:
            print("Map blocked, reseting map")
            self.map_reset()

        return dest

    def map_reset(self):
        """ Create/overwrite search map """
        # Generating the networkx graph object that represents the space
        self.G = nx.Graph()
        self.pos = {}
        for c in range(self.cols):
            for r in range(self.rows):
                node = (c,r)
                coords = self.gridToSpace(c,r)
                self.G.add_node(node, obj=NavNode(coords[0],coords[1],'unexplored'))
                self.pos[node] = [coords[0],-coords[1]]
                if c>0 :
                    self.G.add_edge((c,r),(c-1,r))
                    self.G[(c,r)][(c-1,r)]['weight'] = 1
                    if r>0 :
                        if self.diag:
                            self.G.add_edge((c,r),(c-1,r-1))
                            self.G[(c,r)][(c-1,r-1)]['weight'] = math.sqrt(2)
                            self.G.add_edge((c-1,r),(c,r-1))
                            self.G[(c-1,r)][(c,r-1)]['weight'] = math.sqrt(2)
                if r>0 :
                    self.G.add_edge((c,r),(c,r-1))
                    self.G[(c,r)][(c,r-1)]['weight'] = 1

        self.nG = deepcopy(self.G)
        print("MAP RESET")


    def spaceToClear(self, x, y, delta = 2):
        """ Converts space coordinates to grid coordinates but ensure the position returned is reachable (clear)
            Designed to deal with the case where the goal waypoint is unreachable in contrast to spaceToGrid,
            which is used to recover a usable position for the drone, the behavior is a bit different when
            no clear cell exists in a nearby radius because we are not afraid of flying the waypoint into a wall (unlike the drone)
            - x: float x map coordinates [cm]
            - y: float y map coordinates [cm]
            - delta: search radius under blocking conditions (robustness you know)
        """
        sx = (self.width  / self.cols)  # spacing between nodes on the x axis
        sy = (self.height / self.rows)  # spacing between nodes on the y axis

        c = int(round(x/sx - 0.5))
        r = int(round(y/sy - 0.5))
        # if the rounding puts us in cell that exists and is not occupied then all good
        if self.nG.has_node((c,r)):
            return [c,r]
        # else choose the minimum distance cell satisfies the requirements
        else:
            minDist = sys.float_info.max
            mincoords = False
            for ci in range(max(c-delta,0),min(c+delta+1,self.cols)):
                for ri in range(max(r-delta,0),min(r+delta+1,self.rows)):
                    if ci != c or ri != r:
                        if self.G.nodes[(ci,ri)]['obj'].state == "clear" and self.nG.has_node((ci,ri)):
                            [cx,cy] = self.gridToSpace(ci,ri)
                            dist = math.sqrt( math.pow(x-cx,2)  + math.pow(y-cy,2) )
                            if dist < minDist:
                                minDist = dist
                                mincoords = [ci,ri]
            if mincoords == False:
                mincoords = self.spaceToGrid(x,y,10)
            return mincoords

    def spaceToGridRound(self, x, y):
        """ Converts space coordinates to grid coordinates does it in a really stupid way (simply rounding to nearest int)
            - x: float x map coordinates [cm]
            - y: float y map coordinates [cm]
        """
        sx = (self.width  / self.cols)  # spacing between nodes on the x axis
        sy = (self.height / self.rows)  # spacing between nodes on the y axis

        c = int(round(x/sx - 0.5))
        r = int(round(y/sy - 0.5))

        return [c,r]

    def visit(self, c, r):
        """ marks a node as semantically "clear"
            - c: column index
            - r: row index
        """
        node = (c,r)
        self.G.nodes[node]['obj'].state = "explored"
        self.G.nodes[node]['obj'].pot = 0 # "explored" cell have potential 0 for epsilon *
        self.G.nodes[node]['obj'].confidence = 1 # whenever we make a measurement, we update its confidence to 1

    def removeFromNavGraph(self,node):
        """ Remove node from the navigation graph, node has been blocked
            - node: tuple containing row, column
        """
        c = node[0]
        r = node[1]
        if self.nG.has_node(node):
            self.nG.remove_node(node)
        delEdges = [    ((c,r+1),(c+1,r)),
                        ((c+1,r),(c,r+1)),
                        ((c,r-1),(c+1,r)),
                        ((c+1,r),(c,r-1)),
                        ((c,r+1),(c-1,r)),
                        ((c-1,r),(c,r+1)),
                        ((c,r-1),(c-1,r)),
                        ((c-1,r),(c,r-1)) ]

        for ed in delEdges:
            if self.nG.has_edge(ed[0],ed[1]):
                self.nG.remove_edge(ed[0],ed[1])

    def sense_clear(self,c,r):
        """ Mark cell as "clear" to fly in
            - c: column index
            - r: row index
        """
        if self.G.has_node((c,r)):
            if self.G.nodes[(c,r)]['obj'].state != "blocked" and self.G.nodes[(c,r)]['obj'].state != "explored" and self.G.nodes[(c,r)]['obj'].state != "forbidden":
                self.G.nodes[(c,r)]['obj'].state = "clear"
                self.G.nodes[(c,r)]['obj'].confidence = 1

    def block(self, c, r):
        """ Marks a node as semantically "blocked" and create an "forbidden" boundary region around it
            - c: column index
            - r: row index
        """
        node = (c,r)
        if self.G.has_node(node) :
            self.G.nodes[node]['obj'].state = "blocked"     # set semantic state to blocked
            self.G.nodes[node]['obj'].pot = -1              # set potential to -1 (for epsilon*)

            self.G.nodes[node]['obj'].confidence = 1 # whenever we make a measurement, we update its confidence to 1
        adjNodes = []
        if self.radius == 1:
            adjNodes = [(c+1,r+1),(c+1,r),(c+1,r-1),(c,r+1),(c,r-1),(c-1,r+1),(c-1,r),(c-1,r-1)]
        if self.radius == 2:
            adjNodes = [(c+1,r+1),(c+1,r),(c+1,r-1),(c,r+1),(c,r-1),(c-1,r+1),(c-1,r),(c-1,r-1),
                        (c+2,r+1),(c+2,r),(c+2,r-1),(c-2,r+1),(c-2,r),(c-2,r-1),
                        (c+1,r+2),(c,r+2),(c-1,r+2),(c+1,r-2),(c,r-2),(c-1,r-2)]

        for adjNode in adjNodes:
            if self.G.has_node(adjNode) :
                # do not overwrite a blocked node as forbidden
                if self.G.nodes[adjNode]['obj'].state != "blocked" and \
                    self.G.nodes[adjNode]['obj'].state != "unreachable" and \
                    (self.dc,self.dr) != adjNode :    # set semantic state to blocked
                    self.G.nodes[adjNode]['obj'].state = "forbidden"     # set semantic state to forbidden
                    self.G.nodes[adjNode]['obj'].pot = -1              # set potential to -1 (for epsilon*)

                    self.G.nodes[adjNode]['obj'].confidence = 1 # whenever we make a measurement, we update its confidence to 1
                    self.removeFromNavGraph(adjNode)


        self.removeFromNavGraph(node)

        # if we locked ourselves in a really small area, reset the map
        if self.nG.number_of_nodes() < 10:
            self.map_reset()


        # check if we disconnected a part of the graph, if it is the case, set to unreachable areas inside of the disconnected graph
        # this means we maintain a navigation graph with a single connected component
        if nx.number_connected_components(self.nG) > 1: # should obtain only one connected component at a time
            for component in list(nx.connected_components(self.nG)):
                if (self.dc,self.dr) not in component:
                    for node in component:
                        self.nG.remove_node(node)
                        self.G.nodes[node]['obj'].state = "unreachable" # set semantic state to unreachable
                        self.G.nodes[node]['obj'].pot = -1              # set potential to -1 (for epsilon*)

                        self.G.nodes[node]['obj'].confidence = 1 # whenever we make a measurement, we update its confidence to 1

    def unexplore(self, c, r):
        """ Marks a node as semantically "unexplored"
            - c: column index
            - r: row index
        """
        node = (c,r)
        if self.G.has_node(node):
            self.G.nodes[node]['obj'].state = "unexplored"
            # regrow navgraph : if the node was blocked the navgraph edges were deleted
            if self.nG.has_node(node) == False:
                self.nG.add_node(node)

            addEdges = [    ((c,r),(c,r+1)),
                            ((c,r),(c,r-1)),
                            ((c,r),(c+1,r+1)),
                            ((c,r),(c+1,r-1)),
                            ((c,r),(c+1,r)),
                            ((c,r),(c-1,r+1)),
                            ((c,r),(c-1,r-1)),
                            ((c,r),(c-1,r)) ]

            for ed in addEdges:
                if ed[1][0] > 0 and ed[1][1] > 0 and ed[1][0] < self.cols and ed[1][1] < self.rows :
                    if self.nG.has_edge(ed[0],ed[1]) == False:
                        self.nG.add_edge(ed[0],ed[1])

    def update(self, drone_x, drone_y,delta_t=1):
        """ Update drone position and cell decay
            - drone_x: drone x position in world coordinates [cm]
            - drone_y: drone y position in world coordinates [cm]
            - delta_t: time since last update
        """
        self.drone_x = drone_x  # actual position x of the robot (in cm)
        self.drone_y = drone_y  # actual position y of the robot (in cm)

        drone_grid = self.spaceToGrid(self.drone_x,self.drone_y)

        self.dc = drone_grid[0] # grid position x of the drone
        self.dr = drone_grid[1] # grid position y of the drone
        self.trace.append((self.drone_x,self.drone_y))
        self.dtrace.append((self.dc,self.dr))

        # mark node as explored
        self.visit(self.dc, self.dr)

        # decays the confidence map
        self.update_confidence(delta_t)

    def navTo(self,dest_x,dest_y):
        """ Proposes a navigation waypoint to go to some destination point
            dest_x: destination point x in world coordinates [cm]
            dest_y: destination point y in world coordinates [cm]
        """
        self.navPoints.append((dest_x,dest_y))                      # keep history on destination waypoints
        if self.spaceToGrid(dest_x,dest_y, delta=4) is not None:
            [dest_c,dest_r] = self.spaceToGrid(dest_x,dest_y, delta=4)  # map the destination to a free cell on the grid (if occupied find near cell using spaceToGrid)
        else:
            [dest_c,dest_r] = [None, None]

        self.navCells.append((dest_c,dest_r))                       # keep history on grid destination waypoints

        # if we are on an existing node, solve shortest path
        pos = (self.dc,self.dr)
        if self.nG.has_node(pos):
            # additional constraint : start path from a clear neighbor
            neighbors = self.nG.neighbors(pos)
            opt_len = sys.maxsize
            opt_path = [pos]
            for node in neighbors:
                if self.G.nodes[node]['obj'].state == "clear" or self.G.nodes[node]['obj'].state == "explored":
                    path = nx.shortest_path(self.nG, source=node, target=(dest_c,dest_r), method='dijkstra')
                    path.insert(0,pos)
                    if len(path) < opt_len:
                        opt_len = len(path)
                        opt_path = path
            path = opt_path
            self.path = opt_path

        # if we are not on an existing node, something is wrong, go to a clear node nearby
        else:
            [self.dc,self.dr] = self.spaceToClear(self.drone_x,self.drone_y,delta = 3)
            dest = self.gridToSpace(self.dc,self.dr)
            return [dest[0],dest[1]]
        if len(path)> 1:
            nwx = path[1][0]
            nwy = path[1][1]
        else :
            nwx = path[0][0]
            nwy = path[0][1]
        [npx, npy] = self.gridToSpace(nwx, nwy)
        return [npx, npy]

    def cover_area(self,c1,r1,c2,r2):
        """ initializes an epsilon* potential field over a given area bounded by c1 <= c <= c2 and r1 <= r <= r2
            - c1: lower column bound index
            - r1: lower row bound index
            - c2: upper column bound index
            - r2: lower row bound index
        """
        if c2 > self.cols:
            print("c2 higher than number of collumns")
        if r2 > self.rows:
            print("r2 higher than number of rows")
        if c1 < 0:
            print("c1 lower than 0")
        if r2 < 0:
            print("r1 lower than 0")
        if r2 <= r1:
            print("r2 <= r1")
        if c2 <= c1:
            print("c2 <= c1")

        self.c1 = c1
        self.c2 = c2
        self.r1 = r1
        self.r2 = r2
        # reset the MAPS
        self.nav_state = "nav_cover"
        self.nav_wp = self.gridToSpace(c1,r2)
        self.coarse_tilings = dict() # coarse tiling datastructure (used for global minimum)
        self.levels = 0 # coarse tiling datastructure (used for global minimum)
        for node in self.G.nodes:
            self.G.nodes[node]['obj'].pot = -1

        # start by defining a potential for every cell in the area
        self.cs = self.r2 - self.r1 + 1
        for c in range(c1,c2+1):
            for r in range(r1,r2+1):
                node = (c,r)
                if self.G.has_node(node)  :
                    if self.G.nodes[node]['obj'].state == "blocked" or self.G.nodes[node]['obj'].state == "unreachable"  or self.G.nodes[node]['obj'].state == "forbidden" :
                        self.G.nodes[node]['obj'].pot = -1
                    else:
                        self.G.nodes[node]['obj'].pot = r - r1 + 2

        # defining the coarser tilings :
        self.recursive_area_splitting(c1,r1,c2,r2)

    def is_in_cover_area(self,c,r):
        """ Return true if (c,r) is in cover area
            - c: column index
            - r: row index
        """
        if c >= self.c1 and c <= self.c2:
            if r >= self.r1 and r <= self.r2:
                return True
        return False

    def recursive_area_splitting(self,c1,r1,c2,r2):
        """ Generates coarse tilings each level is twice as corser as the previous level, to see
            why this makes sense just read that : 10.1109/TRO.2017.2780259
            - c1: lower column bound index
            - r1: lower row bound index
            - c2: upper column bound index
            - r2: lower row bound index
        """
        level_dict = dict()

        nc = c2-c1
        rc = r2-r1
        L0 = math.ceil(max(nc,rc)/2)
        # iterate over all levels
        self.levels = math.ceil(math.log(L0,2))
        for level in range(1,self.levels + 1):
            levelGraph = nx.Graph()

            #iterate over all nodes and assign them to a supernode
            for c in range(math.ceil(nc/math.pow(2,level))):

                for r in range(math.ceil(rc/math.pow(2,level))):

                    levelGraph.add_node((c,r))
                    if(c > 0):
                        levelGraph.add_edge((c,r),(c-1,r))
                    if(r > 0):
                        levelGraph.add_edge((c,r),(c,r-1))
                        if(c > 0):
                            levelGraph.add_edge((c,r-1),(c-1,r))
                            levelGraph.add_edge((c,r),(c-1,r-1))
                    levelGraph.nodes[(c,r)]["subnodes"] = []
                    for delta_c in range(int(math.pow(2,level))):
                        for delta_r in range(int(math.pow(2,level))):

                            subnode_c = c1 + c * math.pow(2,level) + delta_c
                            subnode_r = r1 + r * math.pow(2,level) + delta_r
                            if subnode_c < c2 and subnode_r < r2:
                                levelGraph.nodes[(c,r)]["subnodes"].append((int(subnode_c),int(subnode_r)))


            level_dict[level] = levelGraph

        self.coarse_tilings =  level_dict

    def super_node_id(self,node, level):
        """ Returns the id of the supernode on a given level that contains the node "node"
            - node: (c,r) node in level0 graph
            - level: coarseness level
        """
        # basically check all nodes, no clever datastructure tricks
        for supernode in self.coarse_tilings[level].nodes:
            for subnode in self.coarse_tilings[level].nodes[supernode]["subnodes"]:
                if subnode == node:
                    return supernode

    def no_go(self, node):
        """ Returns true if the drone isn't allowed to go in a node
            - node: (c,r) node in level0 graph
        """
        if self.G.has_node(node) == False:
            return True
        if self.G.nodes[node]['obj'].state == "blocked" or \
            self.G.nodes[node]['obj'].state == "unreachable" or \
            self.G.nodes[node]['obj'].state == "forbidden" or \
            self.nG.has_node(node) == False:
            return True
        return False

    def potential_of_supernode(self,supernode,level):
        """ Returns the potential value of a coarse tiling node (supoernode)
            Computation as described in Song & Gupta's paper for epsilon*
            - supernode: node in a graph of coarseness level > 0
            - level: int coarseness level
        """
        pot_acc = 0
        pot_d = 0
        for subnode in self.coarse_tilings[level].nodes[supernode]["subnodes"]:
            if self.G.has_node(subnode):
                if self.G.nodes[subnode]['obj'].pot > 0:
                    pot_d = pot_d + 1
                    pot_acc = pot_acc + self.G.nodes[subnode]['obj'].pot
        if pot_acc == 0:
            return 0
        else :
            return pot_acc/pot_d

    def potential_of_field(self):
        """ Returns the total potential of the potential field, if 0 field is covered """
        pot_acc = 0
        for node in self.G.nodes:
            if self.G.has_node(node):
                if self.G.nodes[node]['obj'].pot > 0:
                    pot_acc = pot_acc + self.G.nodes[node]['obj'].pot
        if pot_acc == 0:
            return 0
        else :
            return pot_acc

    def pick_min_subnode_in_supernode(self,supernode,level):
        """ Returns minimal weight node in supernode
            - supernode: node in a graph of coarseness level > 0
            - level: int coarseness level
        """
        minVal = sys.maxsize
        minNode = None

        for subnode in self.coarse_tilings[level].nodes[supernode]["subnodes"]:
            if self.G.nodes[subnode]['obj'].pot > 0:
                if self.G.nodes[subnode]['obj'].pot < minVal:
                    minVal = self.G.nodes[subnode]['obj'].pot
                    minNode = subnode
        return minNode

    def cover(self):
        """ Computes the next waypoint using an algorithm heavily inspired from the epsilon*
            described by Song & Gupta's paper -> 10.1109/TRO.2017.2780259
        """
        if self.potential_of_field() == 0:
            self.cover_area(self.c1,self.r1,self.c2,self.r2)

        # if we are out of the cover area, navigate back into it
        if self.is_in_cover_area(self.dc,self.dr) == False and self.nav_state != "nav_cover":
            print( "out of area, coordinates are" +str((self.dc,self.dr))  )
            pot = 0
            dest = None
            for node in self.G.nodes:
                if self.G.nodes[node]['obj'].pot > pot:
                    pot = self.G.nodes[node]['obj'].pot
                    dest = node
            if dest == None:
                return self.gridToSpace(self.dc,self.dr)
                # and return something to signal the FSM


            wp0 = self.gridToSpace(dest[0],dest[1])
            # print(dest,wp0)
            self.nav_state = "nav_cover"
            self.nav_wp = (wp0[0],wp0[1])
            wp0 = self.gridToSpace(dest[0],dest[1])

            move =  self.navTo(dest[0],dest[1])

            # print((self.drone_x,self.drone_y))
            # print(move)
            return move


        # handles waypoint navigation
        if self.nav_state =="nav_cover":
            # print("NAV COVER to "+str((self.nav_wp[0],self.nav_wp[1])))
            grid_node = self.spaceToGrid(self.nav_wp[0],self.nav_wp[1])
            node = (grid_node[0],grid_node[1])
            if node == (self.dc,self.dr):
                self.nav_state = "cover"
            elif self.no_go(node) :
                self.nav_state = "cover"
            else:
                return self.navTo(self.nav_wp[0],self.nav_wp[1])

        pos = (self.dc,self.dr)
        maxPot = 0
        wp = pos
        for node in self.G.neighbors(pos):
            if self.G.nodes[node]['obj'].pot > maxPot:
                maxPot = self.G.nodes[node]['obj'].pot
                wp = node
                self.nav_state = "cover"

        #detect local minimums:
        if wp == pos:
            #if detected : gradually go up coarse tiling levels util either something is found or space is covered
            for level in range(1,self.levels+1):

                maxPot = 0
                superpos = self.super_node_id(pos,level) # find super node containing our position on that level, evaluate the potential of our neighbors
                if self.coarse_tilings[level].has_node(superpos):
                    neighbors = self.coarse_tilings[level].neighbors(superpos)

                    for neighbor in neighbors :
                        if self.potential_of_supernode(neighbor,level) > maxPot:
                            maxPot = self.potential_of_supernode(neighbor,level)
                            swp = neighbor
                    if maxPot > 0: # if we are not in a local minimum at that level, navigate to neighbor
                        wp = self.pick_min_subnode_in_supernode(swp,level)
                        wp0 = self.gridToSpace(wp[0],wp[1])
                        self.nav_state = "nav_cover"
                        self.nav_wp = (wp0[0],wp0[1])
                        return self.navTo(wp0[0],wp0[1])

        if wp == pos:
            print( "local min " +str((self.dc,self.dr))  )
            pot = 0
            dest = None
            for node in self.G.nodes:
                if self.G.nodes[node]['obj'].pot > pot:
                    pot = self.G.nodes[node]['obj'].pot
                    dest = node
            if dest == None:
                return self.gridToSpace(self.dc,self.dr)
                # and return something to signal the FSM


            wp0 = self.gridToSpace(dest[0],dest[1])
            # print(dest,wp0)
            self.nav_state = "nav_cover"
            self.nav_wp = (wp0[0],wp0[1])
            wp0 = self.gridToSpace(dest[0],dest[1])

            move =  self.navTo(dest[0],dest[1])

            # print((self.drone_x,self.drone_y))
            # print(move)
            return move

        return self.gridToSpace(wp[0],wp[1])

    def update_conf(self,node,delta_t):
        """ Decays confidence value on a single node
            - node: graph node
            - delta_t: time step
        """
        self.G.nodes[node]['obj'].confidence = (1-self.decay) * self.G.nodes[node]['obj'].confidence
        if self.G.nodes[node]['obj'].confidence < 0.1:
            self.unexplore(node[0],node[1])

    def update_confidence(self,delta_t):
        """ Iterates over all cells to update confidence values
            - node: graph node
            - delta_t: time step
        """
        for node in self.G.nodes:
            self.update_conf(node,delta_t)
    def sense(self,pos,sensor):
        """ Gather sensor values and update map accordingly
            - pos: current drone position vector
            - sensor: multiranger values - front, back , left, right
        """
        sx = (self.width  / self.cols)

        drone_x = pos[0]*100
        drone_y = pos[1]*100
        yaw = (pos[-1]/180)*math.pi
        sensor_angle = [0, math.pi, math.pi/2, -math.pi/2]

        for i in range(4):
            dist = 0
            uvx = math.cos(sensor_angle[i]+yaw)
            uvy = math.sin(sensor_angle[i]+yaw)
            while dist <60 and dist < sensor[i]*100:
                dist = dist + sx
                sense_x = drone_x + uvx * dist
                sense_y = drone_y + uvy * dist
                [c,r] = self.spaceToGridRound(sense_x,sense_y)
                self.sense_clear(c,r)
            if dist >= sensor[i]*100:
                sense_x = drone_x + uvx * dist
                sense_y = drone_y + uvy * dist
                [c,r] = self.spaceToGridRound(sense_x,sense_y)
                self.block(c,r)

    def get_waypoint(self,pos,sensor,delta_t):
        """ Wrapper function for the entire update step including sensors
            - pos: current drone position vector
            - sensor: multiranger values - front, back , left, right
            - delta_t: update time step
        """
        measured_x = pos[0] * 100
        measured_y = pos[1] * 100
        self.update(measured_x,measured_y,delta_t)
        self.sense(pos,sensor)
        # return self.cover()
        # if self.goal_waypoint != None:
        #     goal = self.gridToSpace(self.goal_waypoint[0],self.goal_waypoint[1])
        # else:
        #     goal = (self.drone_x,self.drone_y)
        return self.cover()

