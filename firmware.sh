sudo add-apt-repository ppa:clearpath-robotics/stm32
sudo apt -y -qq update
sudo wget https://raw.githubusercontent.com/clearpathrobotics/public-rosdistro/master/rosdep/50-clearpath.list \
          -O /etc/ros/rosdep/sources.list.d/50-clearpath.list
rosdep -q update

mkdir -p $HOME/firmware_ws/src
cd $HOME/firmware_ws/src
git clone https://gitlab.clearpathrobotics.com/research/dingo_firmware_components.git
cd dingo_firmware_components
git checkout dingo_1_5
cd ..
git clone https://gitlab.clearpathrobotics.com/research/dingo_firmware.git
cd dingo_firmware/
git checkout dingo_1_5
cd ..
git clone https://github.com/dingo-cpr/dingo.git
cd dingo/
git checkout rkreinin/dingo_1_5
cd ../..
rosdep install --from-paths src --ignore-src --rosdistro=$ROS_DISTRO -r -y
catkin_make
source devel/setup.bash
