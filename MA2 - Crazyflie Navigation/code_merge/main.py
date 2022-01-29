#!/usr/bin/env python3

import argparse, time
from functools import partial
from pilot import Pilot
from qt_main import instanciateGui
import multiprocessing as mp


def runPilot(args,d):
    Pilot(args).fly_mission(d)


if __name__ == '__main__':
    # get mission parameters from user setup
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True,
                        help="name of mission file formatted as explained in user_help.txt")
    # extract command line arguments
    cli_args = parser.parse_args()

    # create dictionnary common to both processes
    manager = mp.Manager()
    d = manager.dict()
    d['map'] = None
    d['pose'] = None
    d['rangers'] = None
    d['wait'] = True
    d['emergency_stop'] = False
    d['edge_list'] = False
    d['crash_flag'] = False
    d['display'] = "map"

    ti = time.time()
    # create application processes - PiloT and GUI
    pilotLoop = mp.Process(target=runPilot, args=(cli_args.input,d,))
    guiLoop = mp.Process(target=instanciateGui, args=(d,))
    pilotLoop.start()
    guiLoop.start()
    pilotLoop.join()
    guiLoop.join()

    tf = time.time()
    print(f"Done. Total mission time was {int(tf-ti)} s.")

# EOF