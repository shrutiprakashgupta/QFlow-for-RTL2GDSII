# Using QFlow for RTL2GDSII Flow
This repository is created while working with QFlow to perform GDSII layout generation from RTL code. It includes the QFlow setup procedure and workflow.

## QFlow Setup
Steps for docker image creation are listed below. A pre-setup docker image can be found (here)[].
1. Create the docker container with Ubuntu 20.04 image

    ```shell
    docker run -it --name qflow --privileged --net=host --expose 8887 -e DISPLAY=$DISPLAY -v $HOME/.Xauthority:/tmp/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev:/dev -v /home/shruti/Documents/work:/home/work ubuntu:20.04 bash
    ```
    Expose port and enable X11 forwarding to allow GUI-based application usage from Docker container. Map a local directory (as `/home/shruti/Documents/work`) to the `/home/work` directory in the container for keeping project-related files.  
2. Move to the `/home` directory in the container for installing the QFlow dependencies

    ```shell
    cd /home
    ```
3. Update & install some basic requirements

    If `sudo` is not the default user, append `sudo` to the following commands. 
    ```shell
    apt-get update
    apt install csh tcsh -y
    apt install wget curl tar -y
    apt install build-essential -y
    apt install git -y
    apt install checkinstall zlib1g-dev libssl-dev libgsl-dev libx11-dev -y
    ```
4. Install Cmake for managing build processes

    Get the tarball and extract it
    ```shell
    wget https://github.com/Kitware/CMake/releases/download/v3.18.2/cmake-3.18.2.tar.gz
    tar -xvf cmake-3.18.2.tar.gz
    rm cmake-3.18.2.tar.gz
    ```
    Move to the `cmake-3.18.2/` directory and execute the following (this step will take a while)
    ```shell
    ./bootstrap
    make
    sudo make install
    ```
5. Install Python and other libraries to support QFlow GUI

    ```
    apt install python3.8 -y
    apt install python3-tk -y
    apt install tcl-dev tk-dev -y
    ```
6. Install Yosys (for Synthesis)
    
    ```
    apt install yosys -y
    yosys -v
    ```
    The second command should return the version number if yosys is installed properly.
7. Install Graywolf (for Placement)
    
    The latest release is from Aug 2018 - version 0.1.6
    ```
    git clone https://github.com/rubund/graywolf.git
    cd graywolf
    git checkout 0.1.6
    mkdir build
    cd build
    cmake ..
    make
    make install
    ```
8. 
