# ros_computer_setup
Simple script that makes all Clearpath specific changes to a as system that does not support the standard ISO image
(ie Jeton) to make it operate like our robot standard images.  Makes it work as a standard computer for Husky or Jackal.

## Supported Jetsons
* TX2 (Kinetic)
* Nano (Melodic)
* Xavier AGX (Melodic)
* Xavier NX (Melodic)

## Usage
```wget -c https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/install.sh && bash install.sh```

## What it Does
* Add ROS sources and key
* Add Clearpath sources and key
* Installs apt-transport-https
* Installs ROS Husky/Jackal robot packages
* Sets up /etc/ros/setup.bash environment (standard with CPR robots)
* Adds standard vim and screen config files
* Adds udev rules for Microstrain, Clearpath, Hokuyo, FTDI, and Startech
* Unblocks Bluetooth
