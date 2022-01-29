# crazy-practical
Crazyflie hardware practical for the Aerial Robots course at EPFL.

In this practical, you will learn how to program a [Crazyflie](https://www.bitcraze.io/) to find and precisely land on a platform with the help of minimal sensory information. Additionally, you will use sensor readings to avoid the obstacles present in the environment.

<p align="center">
<img width=700 src="https://github.com/dronecourse-epfl/crazy-practical/blob/master/docs/pictures/crazyfly_objective_figure.png"/>
</p>

For more details on the task, submission, schedule and grading, please refer to the [moodle](https://moodle.epfl.ch/course/view.php?id=15799) page of the course.

## Requirements
For this practical, each team is required to use one of their personal laptops. Bitcraze supports the installation of the software on Windows, Linux, OS X and Virtual Machines. However, we tested the installation process only on:
1. Windows 10
2. Ubuntu 16.04
3. Ubuntu 18.04

## 1. Unpacking
<a name="unpacking"></a>
At the beginning of the practical, every team will receive a box with the necessary hardware. This includes:
1. One [Crazyflie package](https://store.bitcraze.io/collections/kits/products/crazyflie-2-1)
  * 1 x Crazyflie 2.1 with all components mounted
  * 1 x Crazy-radio dongle
  * 2 x LiPo battery (240mAh)
  * 1 x Battery charger
  * 1 x Battery deck
  * 1 x USB cable
2. One spare parts set
  * 1 x spare motor
  * 2 x spare motor mounts
  * 3 x spare propellers CW 
  * 3 x spare propellers CCW
4. One [flow deck v2](https://store.bitcraze.io/collections/decks/products/flow-deck-v2)
5. One [multi-ranger deck](https://www.bitcraze.io/products/multi-ranger-deck/)
6. 4 x pattern carpet piecs of 60x60cm

## 2. Assembling
Assembling your Crazyflie 2.X will probably take less than 10 minutes, but there are a few pitfalls. So make sure to follow the instructions [here](https://www.bitcraze.io/getting-started-with-the-crazyflie-2-0/#assembling).

## 3. Installing the Pyhon library
For developing the code for the practical, you will need to clone this repository with its submodules via the following commands:

```git clone https://github.com/dronecourse-epfl/crazy-practical/```

```cd crazy-practical```

```git submodule update --init --recursive```

Then install the Crazyflie Python library with the command:

```pip install -e crazyflie-lib-python```

## 4. Installing the Crazyflie Client
Follow the instructions [here](https://www.bitcraze.io/getting-started-with-the-crazyflie-2-0/#inst-comp) to install the Crazyflie Client and connect to your Crazyflie. To install it from source on Ubuntu, follow these steps:

The client requires Python3, pip and pyqt5 to be installed using the system package manager. For example on Ubuntu/Debian, do:

```
sudo apt-get install python3 python3-pip python3-pyqt5 python3-pyqt5.qtsvg
```

Then, clone the `crazyflie-clients-python` repository with:

```git clone https://github.com/bitcraze/crazyflie-clients-python.git```

Then, checkout to commit `07603f7` with:

```
cd crazyflie-clients-python/
git checkout 07603f7
```
And, finally, install the client with:

```pip3 install -e .```

This will build the client in the subfolder `bin` and you can run it with:
```
./bin/cfclient
```


## 5. Setting up the radio interface
You need to make sure that you have the right usb permission for the radio interface. You can find extensive instructions [here](https://github.com/bitcraze/crazyflie-lib-python#setting-udev-permissions).
On your terminal issue the following commands:
```
sudo groupadd plugdev
sudo usermod -a -G plugdev $USER
```
Then log out and log back in to update the plugdev group.

Create the following file (you may need `sudo` permissions):
```
touch /etc/udev/rules.d/99-crazyradio.rules
```

Then edit it with the text editor of your preference, and add the following lines:
```
# Crazyradio (normal operation)
SUBSYSTEM=="usb", ATTRS{idVendor}=="1915", ATTRS{idProduct}=="7777", MODE="0664", GROUP="plugdev"
# Bootloader
SUBSYSTEM=="usb", ATTRS{idVendor}=="1915", ATTRS{idProduct}=="0101", MODE="0664", GROUP="plugdev"
```


## 6. Configuring the Crazyradio and the Crazyflie address
Every team will be assigned a unique radio channel and Crazyflie address. All you need to do is:
* Plug the Crazyradio in your pc
* Power on the Crazyflie
* Start the Crazyflie Client (with the command `cfclient`)
* Select your Crazyradio and 'Scan'
* Connect to your Crazyfie (default address is 0xE7E7E7E7E7)
* In the 'Connect' tab on top, select 'Configure 2.X'
* In the window that openned up, enter the channel number and radio address that have been assigned to your team. Then, click 'Write'.
* Restart the Crazyflie and the client
* Connect to your Crazyfie using your assigned address

## 7. Testing the Crazyflie library
To test that the Python library has been installed properly, you can run one example from the `crazyflie-lib-python`. First, be sure that the crazyflie is on, the radio plugged and the address of the crazyflie is the default one. Then, type one of the following in your terminal:

```
python examples/basiclog.py
```

or

```
python examples/position_commander_demo.py
```

# Coding your algorithm
Now it's your time to code!
You will find example scripts for this practical in `crazyflie-lib-python/cp_examples`.

Several scrips are available: `position_commander.py` illustrates how to issue simple position commands, while `basiclog.py` 
shows how to acquire and log roll, pitch, and yaw angle estimates from the Crazyflie and save them in a `csv` file. Your logs are saved in the `logs` folder and you can analyze them in a Python notebook, as shown in the example `logs_analyzer.ipynb`.
Finally, `logandfly.py` combines the two previous examples into one script, where your drone will fly through a simple maneuver and log its position estimated and sensor data. Again, you can visualized the acquired dataset with the `logs_analyzer.ipynb` script.

To run the examples, call them from the `crazyflie-lib-python` folder like this:

```
python cp_examples/position_commander.py
```
## Connect to your Crazyflie
Before launching an example, i.e. `position_commander.py`, be sure that you updated the Crazyflie URI [here](https://github.com/dronecourse-epfl/crazyflie-lib-python/blob/c7aa5b66a2a0c43e2988e27b858e5e20f0ebbd76/cp_examples/position_commander.py#L41) with the one of your drone. The default one is:

```uri = 'radio://0/80/2M/E7E7E7E7E7'```

## Sending commands
To send position commands to your Crazyflie, follow the example `position_commander.py`.

## Reading and saving sensor measurements
The file `basiclog.py` shows how to log your Crazyflie data. Add the variables to log in the `_connected` function [here](https://github.com/dronecourse-epfl/crazy-practical/blob/master/crazyflie-lib-python/cp_examples/basiclog.py#L77).

A visualization of the multi-ranger measurements is available in [multiranger_pointcloud.py](https://github.com/dronecourse-epfl/crazy-practical/blob/master/crazyflie-lib-python/cp_examples/multiranger_pointcloud.py). In this file, you can see how to adjust the distance threshold of your sensors, i.e. the distance within which you want to consider measurements.

## Flight analysis
The script `logandfly.py` allows to perform a simple manevuer and log position estimates and sensor readings.

## Visualizing logs
For visualizing the logs content, follow the example `logs_analyzer.ipynb`.
