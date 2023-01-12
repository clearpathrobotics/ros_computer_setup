# ros_computer_setup
Contains a simple install script that makes all Clearpath specific changes to a system that does not support the standard Clearpath ISO image
(e.g. ARM64 NVIDIA Jetson computers), and make the system operate as if the standard Clearpath ISO image had been installed. The system will effectively be setup as a standard computer for support Clearpath robot platforms.

## Supported Jetsons
* TX2 (Kinetic)
* Nano (Melodic, Noetic)
* AGX Xavier (Melodic, Noetic)
* Xavier NX (Melodic, Noetic)
* AGX Orin (Melodic, Noetic)

## Supported Clearpath Robot Platforms
* Husky
* Jackal
* Dingo
* Ridgeback

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
