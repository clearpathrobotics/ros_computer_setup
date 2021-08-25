#!/bin/bash -eu
# Software License Agreement (BSD)
#
# Author    Tony Baltovski <tbaltovski@clearpathrobotics.com>
# Copyright (c) 2020, Clearpath Robotics, Inc., All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that
# the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this list of conditions and the
#   following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#   following disclaimer in the documentation and/or other materials provided with the distribution.
# * Neither the name of Clearpath Robotics nor the names of its contributors may be used to endorse or
#   promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Usage: install.sh [-h|--help] [-n|--nvidia {nx|nano|agx|tx2}] [-r|--robot {dingo|husky|jackal|ridgeback}] [-y|--yes]

#set -x

prompt_option() {
  # ask the user to select from a numbered list of options & return their selection
  # $1 is the variable into which the result is returned
  # $2 should be the question to ask the user as a prompt
  # $3+ should be the available options

  local __resultvar=$1
  shift
  local __prompt=$1
  shift
  local __n_options=$#

  echo -e "\e[39m$__prompt\e[0m"
  for (( i=1; $i<=$__n_options; i++ ));
  do
    opt=${!i}
    echo -e "[$i] \e[32m$opt\e[0m"
  done

  read answer
  eval $__resultvar="'$answer'"
}

prompt_YESno() {
  # as the user a Y/n question
  # $1 is the variable into which the answer is saved as either "n" or "y"
  # $2 is the question to ask

  local __resultvar=$1
  local __prompt=$2

  echo -e "\e[39m$__prompt\e[0m"
  echo "Y/n: "

  if [[ $AUTO_YES == 1 ]];
  then
    echo "Automatically answering Yes"
    eval $__resultvar="y"
  else
    read answer
    if [[ $answer =~ ^[n,N].* ]];
    then
      eval $__resultvar="n"
    else
      eval $__resultvar="y"
    fi
  fi
}

prompt_yesNO() {
  # as the user a y/N question
  # $1 is the variable into which the answer is saved as either "n" or "y"
  # $2 is the question to ask

  local __resultvar=$1
  local __prompt=$2

  echo -e "\e[39m$__prompt\e[0m"
  echo "y/N: "

  if [[ $AUTO_YES == 1 ]];
  then
    echo "Automatically answering No"
    eval $__resultvar="n"
  else
    read answer
    if [[ $answer =~ ^[y,Y].* ]];
    then
      eval $__resultvar="y"
    else
      eval $__resultvar="n"
    fi
  fi
}

# 0/1 indicating if the user wants to run the script non-interactively
# if 1 we will always return the default Y/N answer to any such prompts
AUTO_YES=0

# available nvidia platforms; pre-load the user-choice with -1 to indicate undefined
PLATFORM_XAVIER_NX=1
PLATFORM_NANO=2
PLATFORM_AGX_XAVIER=3
PLATFORM_TX2=4
PLATFORM_RASPI=5
PLATFORM_DESKTOP=6
PLATFORM_CHOICE=-1

# available robots; pre-load the user-choice with -1 to indicate undefined
ROBOT_HUSKY=1
ROBOT_JACKAL=2
ROBOT_DINGO=3
ROBOT_RIDGEBACK=4
ROBOT_CHOICE=-1

# parse the command-line options
nargs=$#
for (( i=0; $i<$nargs; i++ ));
do
  arg=$1
  shift

  # show usage & exit
  if [[ $arg == "-h" || $arg == "--help" ]];
  then
    echo "Usage: bash install.sh [-h|--help] [-d|--device {nx|nano|agx|tx2|raspi|desktop}] [-r|--robot {dingo|husky|jackal|ridgeback}] [-y|--yes]"
    echo "    -h|--help           Show this message"
    echo "    -d|--device DEVICE  Specify the target computer (e.g. x86_64 desktop, Nvidia Jetson family, Raspberry Pi) you are running this script on"
    echo "    -r|--robot ROBOT    Specify the type of Clearpath robot you are setting up"
    echo "    -y|--yes            Use the default response for all yes/no inputs"
    echo ""
    echo "    To run the script fully non-interactively you must set the -n -r and -y flags"
    echo ""
    exit 0
  elif [[ $arg == "-y" || $arg == "--yes" ]];
  then
    AUTO_YES=1
  elif [[ $arg == "-d" || $arg == "--device" ]];
  then
    i=$((i+1))
    nvidia_target=$1
    shift
    case $nvidia_target in
      "nx" )
        PLATFORM_CHOICE=$PLATFORM_XAVIER_NX
      ;;
      "nano" )
        PLATFORM_CHOICE=$PLATFORM_NANO
      ;;
      "agx" )
        PLATFORM_CHOICE=$PLATFORM_AGX_XAVIER
      ;;
      "tx2" )
        PLATFORM_CHOICE=$PLATFORM_TX2
      ;;
      "raspi" )
        PLATFORM_CHOICE=$PLATFORM_RASPI
      ;;
      "desktop" )    # standard 64-bit desktop CPU
        PLATFORM_CHOICE=$PLATFORM_DESKTOP
      ;;
      *)
        echo -e "\e[31mERROR: Unknown target platform:\e[0m $nvidia_target"
        exit 1
    esac
  elif [[ $arg == "-r" || $arg == "--robot" ]];
  then
    i=$((i+1))
    robot_target=$1
    shift
    echo $@
    case $robot_target in
      "dingo" )
        ROBOT_CHOICE=$ROBOT_DINGO
      ;;
      "husky" )
        ROBOT_CHOICE=$ROBOT_HUSKY
      ;;
      "jackal" )
        ROBOT_CHOICE=$ROBOT_JACKAL
      ;;
      "ridgeback" )
        ROBOT_CHOICE=$ROBOT_RIDGEBACK
      ;;
      *)
        echo -e "\e[31mERROR: Unknown robot platform:\e[0m $robot_target"
        exit 1
    esac
  else
    echo -e "\e[31mERROR: Unknown parameter:\e[0m $arg"
    exit 1
  fi
done

echo "Starting ROS installion"

# Get Ubuntu version
ubuntu_version=`lsb_release -sc`

echo ""
echo -e "\e[39mChecking your Ubuntu version\e[0m"
echo -e "\e[39mDetected Ubuntu: $ubuntu_version\e[0m"
echo -e "\e[32m"
case $ubuntu_version in
  "xenial" )
    ros_version="kinetic"
    ;;
  "bionic" )
    ros_version="melodic"
    ;;
  "focal" )
    ros_version="noetic"
    ;;
  *)
    echo -e "\e[31mERROR: Unsupported Ubuntu version: $ubuntu_version\e[0m"
    exit 0
esac

# Sanity check; not all robots have support for all ROS versions; check specific cases
# and exit if we have an unsupported combination
if ([ "$robot_target" == "dingo" ] && [ "$ros_version" == "noetic" ]) ||
   ([ "$robot_target" == "ridgeback" ] && [ "$ros_version" == "noetic" ]);
then
  echo -e "\e[31mERROR: Ubuntu ${ubuntu_version} + ROS ${ros_version} is not supported on ${robot_target} (yet) \e[0m"
  exit 0
else
  echo -e "\e[32mUbuntu ${ubuntu_version} is supported on ${robot_target}, proceeding to install ROS ${ros_version}\e[0m"
fi

if [[ $PLATFORM_CHOICE -eq -1 ]];
then
  echo ""
  prompt_option PLATFORM_CHOICE "Which computing platform are you installing on?" "Nvidia Jetson Xavier NX" "Nvidia Jetson Nano" "Nvidia Jetson AGX Xavier" "Nvidia Jetson TX2" "Raspberry Pi 4" "Intel/AMD 64-bit desktop"
fi
case "$PLATFORM_CHOICE" in
  1)
    compute_type="jetson-xavier-nx"
    ;;
  2)
    compute_type="jetson-nano"
    ;;
  3)
    compute_type="jetson-xavier-agx"
    ;;
  4)
    compute_type="jetson-tx2"
    ;;
  5)
    compute_type="raspi"
    ;;
  6)
    compute_type="desktop"
    ;;
  *)
    echo -e "\e[31mERROR: Invalid selection"
    exit 1
    ;;
esac
echo "Selected ${compute_type}."
echo ""

if [[ $ROBOT_CHOICE -eq -1 ]];
then
  echo ""
  prompt_option ROBOT_CHOICE "Which robot are you installing?" "Clearpath Husky" "Clearpath Jackal" "Clearpath Dingo" "Clearpath Ridgeback"
fi
case "$ROBOT_CHOICE" in
  1)
    platform="husky"
    ;;
  2)
    platform="jackal"
    ;;
  3)
    platform="dingo"
    ;;
  4)
    platform="ridgeback"
    ;;
  * )
    echo -e "\e[31mERROR: Invalid selection"
    exit 1
    ;;
esac
echo "Selected ${platform}."
echo ""

echo "Summary: Installing ROS ${ros_version} on ${compute_type} in ${platform}"
echo ""
echo -e "\e[94mConfiguring Ubuntu repositories\e[0m"

sudo add-apt-repository -y universe
sudo add-apt-repository -y restricted
sudo add-apt-repository -y multiverse
sudo apt-get install -qq -y apt-transport-https apt-utils bash-completion git htop nano screen coreutils

echo -e "\e[32mDone: Configuring Ubuntu repositories\e[0m"
echo ""

echo -e "\e[94mSetup your apt sources\e[0m"


# Check if ROS sources are already installed
if [ -e /etc/apt/sources.list.d/ros-latest.list ]; then
  echo -e "\e[33mWarn: ROS sources exist, skipping\e[0m"
else
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/ros-latest.list ]; then
    echo -e "\e[31mError: Unable to add ROS sources, exiting\e[0m"
    exit 0
  fi
fi

# Check if CPR sources are already installed
if [ -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
  echo -e "\e[33mWarn: CPR sources exist, skipping\e[0m"
else
  wget https://packages.clearpathrobotics.com/public.key -O - | sudo apt-key add -
  sudo sh -c 'echo "deb https://packages.clearpathrobotics.com/stable/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/clearpath-latest.list'
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
    echo -e "\e[31mError: Unable to add CPR sources, exiting\e[0m"
    exit 0
  fi
fi

echo -e "\e[32mDone: Setup your apt sources\e[0m"
echo ""

echo -e "\e[94mUpdating packages\e[0m"
sudo apt -y -qq update
sudo apt -y -qq dist-upgrade
echo -e "\e[32mDone: Updating packages\e[0m"
echo ""

echo -e "\e[94mInstalling ROS prerequisites\e[0m"
sudo apt install -qq -y python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential
# ensure the correct tool for setting user permissions for the upstart job are present
if [ "$ubuntu_version" == "bionic" ];
then
  sudo apt-get install -qq -y setpriv
elif [ "$ubuntu_version" == "xenial" ];
then
  sudo apt-get install -qq -y daemontools
fi
echo -e "\e[32mDone: Installing ROS prerequisites\e[0m"
echo ""

echo -e "\e[94mInstalling ${platform} packages\e[0m"
sudo apt install -qq -y ros-${ros_version}-ros-base ros-${ros_version}-${platform}-robot
echo -e "\e[32mDone: Installing ${platform} packages\e[0m"
echo ""

echo -e "\e[94mConfiguring Robot environment\e[0m"

sudo mkdir -p /etc/ros

if [ -e /etc/profile.d/clearpath-ros-environment.sh ]; then
  echo -e "\e[33mWarn: CPR ROS environment exist, skipping\e[0m"
else
  sudo wget -q -O /etc/profile.d/clearpath-ros-environment.sh \
    https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/clearpath-ros-environment.sh
  # Check if was added
  if [ ! -e /etc/profile.d/clearpath-ros-environment.sh ]; then
    echo -e "\e[31mError: CPR ROS environment exist, exiting\e[0m"
    exit 0
  fi
fi

if [ -e /etc/ros/setup.bash ]; then
  echo -e "\e[33mWarn: CPR ROS robot environment exist, skipping\e[0m"
else
  sudo wget -q -O /etc/ros/setup.bash \
    https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/setup.bash
  sudo sed -i "s/UNKNOWN_ROS_DISTRO/${ros_version}/g" /etc/ros/setup.bash
  # Check if was added
  if [ ! -e /etc/ros/setup.bash ]; then
    echo -e "\e[31mError: CPR ROS robot environment exist, exiting\e[0m"
    exit 0
  fi
fi

echo "source /opt/ros/${ros_version}/setup.bash" >> $HOME/.bashrc
echo -e "\e[32mDone: Configuring Robot environment\e[0m"
echo ""

echo -e "\e[94mConfiguring rosdep\e[0m"
if [ -e /etc/ros/rosdep/sources.list.d/20-default.list ]; then
  echo -e "\e[33mWarn: rosdep was initalized, skipping\e[0m"
else
  sudo rosdep -q init
  if [ ! -e /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    echo -e "\e[31mError: rosdep failed to initalize, exiting\e[0m"
    exit 0
  fi
fi

if [ -e /etc/ros/rosdep/sources.list.d/50-clearpath.list ]; then
  echo -e "\e[33mWarn: CPR rosdeps exist, skipping\e[0m"
else
  sudo wget -q https://raw.githubusercontent.com/clearpathrobotics/public-rosdistro/master/rosdep/50-clearpath.list -O \
    /etc/ros/rosdep/sources.list.d/50-clearpath.list
  # Check if was added
  if [ ! -e /etc/ros/rosdep/sources.list.d/50-clearpath.list ]; then
    echo -e "\e[31mError: CPR rosdeps, exiting\e[0m"
    exit 0
  fi
fi
rosdep -q update
echo -e "\e[32mDone: Configuring rosdep\e[0m"
echo ""

echo -e "\e[94mConfiguring udev rules\e[0m"
sudo wget -q -O /etc/udev/rules.d/41-clearpath.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-clearpath.rules
sudo wget -q -O /etc/udev/rules.d/41-logitech.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-logitech.rules
sudo wget -q -O /etc/udev/rules.d/52-ftdi.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/52-ftdi.rules
sudo wget -q -O /etc/udev/rules.d/60-startech.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/60-startech.rules
echo -e "\e[32mDone: Configuring udev rules\e[0m"
echo ""

echo -e "\e[94mConfiguring system configs\e[0m"
wget -q -O $HOME/.screenrc \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/config/.screenrc
wget -q -O $HOME/.vimrc \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/config/.vimrc

# create /etc/rc.local if it doesn't exist yet
if [ ! -f /etc/rc.local ];
then
  sudo tee /etc/rc.local <<EOT
#!/bin/bash -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing."
EOT
fi
if [ ! -x /etc/rc.local ];
then
  sudo chmod +x /etc/rc.local
fi
echo -e "\e[32mDone: Configuring system configs\e[0m"
echo ""

echo -e "\e[94mConfiguring ${platform}\e[0m"
source /etc/ros/setup.bash
if [ "platform" == "jackal" ]; then
  sudo sh -c 'echo export JACKAL_WIRELESS_INTERFACE=wlan0 >> /etc/ros/setup.bash'
fi
rosrun ${platform}_bringup install
echo -e "\e[32mDone: Configuring ${platform}\e[0m"
echo ""

echo -e "\e[94mConfiguring Bluetooth\e[0m"
sudo apt install -qq -y bluez bluez-tools python-ds4drv
sudo rfkill unblock all
sudo rfkill unblock bluetooth
if [ "$PLATFORM_CHOICE" == "$PLATFORM_RASPI" ];
then
  # Additional Raspberry Pi 4 config steps -- see RP-2396
  sudo sed -i "s/enable_uart=1/#enable_uart=1/g" /boot/firmware/config.txt
  sudo sed -i "s/cmdline=nobtcmd.txt/#cmdline=nobtcmd.txt/g" /boot/firmware/config.txt
  echo "dtparam=krnbt=on" | sudo tee -a /boot/firmware/config/txt

  sudo sed -i "s/include nobtcfg.txt/#include nobtcfg.txt/g" /boot/firmware/sysconfig.txt
  echo "include btcfg.txt" | sudo tee -a /boot/firmware/sysconfig/txt

  sudo snap install pi-bluetooth
fi
echo -e "\e[32mDone: Configuring Bluetooth\e[0m"
echo ""

echo -e "\e[94mConfiguring Networking\e[0m"
sudo usermod -a -G netdev $USER
if [ "$ubuntu_version" == "xenial" ] || [ "$ubuntu_version" == "bionic" ];
sudo apt install -qq -y bridge-utils dhcpcd5
then
  sudo apt install -qq -y wicd-curses ifupdown
  sudo mv /etc/network/interfaces /etc/network/interfaces.bkup.$(date +"%Y%m%d%H%M%S")
  sudo tee /etc/network/interfaces > /dev/null <<EOT
auto lo br0 br0:0
iface lo inet loopback

# Bridge together physical ports on machine, assign standard Clearpath Robot IP.
iface br0 inet static
  bridge_ports regex (eth.*)|(en.*)
  address 192.168.131.1
  netmask 255.255.255.0
  bridge_maxwait 0

# Also seek out DHCP IP on those ports, for the sake of easily getting online,
# maintenance, ethernet radio support, etc.
# For Raspberry Pi 4, you may need to disable allow-hotplug br0:0
allow-hotplug br0:0
iface br0:0 inet dhcp
EOT
else
  sudo apt install -qq -y netplan.io

  # remove the default netplan configuration and replace it with the bridge
  if [ -f /etc/netplan/01-netcfg.yaml ];
  then
    rm /etc/netplan/01-netcfg.yaml
  fi
  sudo tee /etc/netplan/50-clearpath-bridge.yaml > /dev/null <<EOT
# Configure the wired ports to form a single bridge
# We assume wired ports are en* or eth*
# This host will have address 192.168.131.1
network:
version: 2
renderer: networkd
ethernets:
bridge_eth:
  dhcp4: no
  dhcp6: no
  match:
    name: eth*
bridge_en:
  dhcp4: no
  dhcp6: no
  match:
    name: en*
bridges:
br0:
  dhcp4: yes
  dhcp6: no
  interfaces: [bridge_en, bridge_eth]
  addresses:
    - 192.168.131.1/24
EOT
fi
sudo apt remove -qq -y network-manager

# apply the fix to prevent the networking from hanging for 5 minutes on boot
if [ "$ubuntu_version" == "bionic" ];
then
  if [ ! -d /etc/systemd/system/networking.service.d ];
  then
    sudo mkdir -p /etc/systemd/system/networking.service.d/
  fi
  sudo bash -c 'echo -e "[Service]\nTimeoutStartSec=5sec" > /etc/systemd/system/networking.service.d/timeout.conf'

  sudo systemctl mask systemd-networkd-wait-online.service
  sudo systemctl daemon-reload
fi

# We're using wicd, not network-manager so disable the interfaces accordingly
sudo tee --append /etc/NetworkManager/NetworkManager.conf <<EOT
[keyfile]
unmanaged-devices=interface-name:br*;interface-name:eth*;interface-name:wlan*;interface-name:wlp*
EOT

# Disable wifi power management to improve network performance & reduce latency
if [ "$PLATFORM_CHOICE" == "$PLATFORM_TX2" ];
then
  sudo tee --append /etc/rc.local <<EOT
# disable power management on a Jetson TX2
if ! iw dev wlan0 set power_save off;
then
  echo "[WARN][rc.local] Failed to disable wireless power management"
fi
EOT

elif [ "$PLATFORM_CHOICE" == "$PLATFORM_AGX_XAVIER" ];
then
  sudo tee --append /etc/rc.local <<EOT
# disable wireless power management on a regular computer
if ! iwconfig wlan0 power off;
then
  echo "[WARN][rc.local] Failed to disable wireless power management"
fi
EOT

elif [ "$PLATFORM_CHOICE" == "$PLATFORM_XAVIER_NX" ] || [ "$PLATFORM_CHOICE" == "$PLATFORM_NANO" ];
then
  sudo tee --append /etc/rc.local <<EOT
# disable wireless power management on a regular computer
if ! iwconfig wlp2s0 power off;
then
  echo "[WARN][rc.local] Failed to disable wireless power management"
fi
EOT

elif [ "$PLATFORM_CHOICE" == "$PLATFORM_RASPI" ];
then
  # Any additional Pi configuration needed goes here
  # For now there's nothing, but this section is still somewhat WIP while we evaluate the Pi on our various platforms
  echo -n
elif [ "$PLATFORM_CHOICE" == "$PLATFORM_DESKTOP" ];
then
  # Any additional Intel/AMD configuration needed goes here
  # For now there's nothing, but we may need to add changes for specific hardware revisions in the future
  echo -n
fi
echo -e "\e[32mDone: Configuring Networking\e[0m"
echo ""

echo -e "\e[94mRemoving unused packages\e[0m"
sudo apt-get -qq -y autoremove
echo -e "\e[32mDone: Removing unused packages\e[0m"
echo ""


STORAGE_DRIVE="/dev/nvme0n1"
if [ -e $STORAGE_DRIVE ]; then
  echo -e "\e[94mm2 drive detected\e[0m"
  prompt_yesNO drive_prompt "\e[94mAutomount m2 storage to /mnt/storage\e[0m"
  echo $drive_prompt
  if [[ $drive_prompt == "y" ]]; then

    # check if the storage drive has already been manually configured before formatting & configuring fstab
    if grep -qs '$STORAGE_DRIVE ' /proc/mounts; then
        echo -e "[33mWarn: $STORAGE_DRIVE is already mounted. Skipping.\e[0m"
    else
      sudo apt install -qq -y dosfstools
      sudo mkfs.ext4 $STORAGE_DRIVE
      sudo mkdir -p /mnt/storage
      echo "$STORAGE_DRIVE /mnt/storage ext4 auto,user,rw 1 2" | sudo tee -a /etc/fstab
      sudo mount /mnt/storage/
      sudo chmod -R a+rwx /mnt/storage/
      echo -e "\e[32mDone: Automount m2 storage\e[0m"
    fi
  else
    echo -e "\e[33mWarn: No selected for automouting drive, skipping\e[0m"
  fi
  echo ""
fi

echo -e "\e[94mVerifying install\e[0m"
if [ "$ros_version" == `rosversion -d` ]; then
    echo -e "\e[32mDone: Verifying install\e[0m"
else
    echo -e "\e[33mWarn: Verifying install might not be complete\e[0m"
fi
echo ""

echo -e "\e[32mDone: Installing ROS ${ros_version} on ${compute_type} in ${platform}\e[0m"

prompt_YESno reboot_prompt "\eWould you like to reboot to apply changes?\e[0m"
if [[ $reboot_prompt == "y" ]]; then
  echo "Going to reboot!"
  sudo reboot
else
  echo "No reboot selected, reboot to apply changes"
fi
