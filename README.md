# Using QFlow for RTL2GDSII Flow
This repository is created while working with QFlow to perform GDSII layout generation from RTL code. It includes the QFlow setup procedure and workflow.

## QFlow Setup

### Using Docker Image
The docker image can be found [here](https://hub.docker.com/r/shrutiprakashgupta/qflow).
Or accessed through CLI as follows:
```shell
docker pull shrutiprakashgupta/qflow
docker run -it --name qflow --privileged --net=host --expose 8887 -e DISPLAY=$DISPLAY -v $HOME/.Xauthority:/tmp/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev:/dev -v /home/shruti/Documents/work:/home/work shrutiprakashgupta/qflow:latest bash
```
Launch the Docker container with following steps
```shell
xhost +
docker exec -it qflow /bin/bash
```

### Docker Image Creation (Just for Reference)
Steps for docker image creation are listed below.
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
    apt install neovim -y
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
    cd ..
    ```
    Move to `~` directory and add the following line in .bashrc file and execute command `source .bashrc`
    ```
    PATH="/home/cmake-3.18.2/bin:$PATH"
    ```
5. Install Python and other libraries to support QFlow GUI

    ```shell
    apt install python3.8 -y
    apt install python3-tk -y
    apt install tcl-dev tk-dev -y
    ```
6. Install Iverilog (for RTL compilation)

    ```shell
    apt-get install -y iverilog
    ```
7. Gtkwave (for waveform viewing & debugging)

    ```shell
    apt-get install -y gtkwave
    ```
8. Install Yosys (for Synthesis)

    ```shell
    apt install yosys -y
    yosys -h
    ```
    The second command should print the help menu for yosys is it is installed properly.
9. Install Graywolf (for Placement)

    The latest release is from Aug 2018 - version 0.1.6
    ```shell
    git clone https://github.com/rubund/graywolf.git
    cd graywolf
    git checkout 0.1.6
    mkdir build
    cd build
    cmake ..
    make
    make install
    cd ../../
    ```
10. Install Qrouter (for Routing)

    ```shell
    git clone https://github.com/RTimothyEdwards/qrouter.git
    cd qrouter
    git checkout qrouter-1.4
    ./configure
    make
    make install
    cd ../
    ```
11. Install Magic (for working with GDSII Layout and performing Design Rule Check) 

    ```shell
    git clone https://github.com/RTimothyEdwards/magic.git
    cd magic
    git checkout magic-8.3
    ./configure
    make
    make install
    cd ../
    ```
12. Install Netgen (for Layout-Versus-Schematic (LVS) verification)

    ```shell
    git clone https://github.com/RTimothyEdwards/netgen.git
    cd netgen
    git checkout netgen-1.5
    apt-get install -y m4
    ./configure
    make
    make install
    cd ../
    ```
13. Install QFlow (for the complete toolchain)

    The tools (corresponding binary files) installed before need to be present in discoverable paths. 
    Usually they would be in `/usr/bin/` or `/usr/local/bin/` directories. 
    Otherwise, their path should be added in the `.bashrc` file and sourced (as mentioned before in case of cmake installation. 
    Notice that some of the tools would not be found after the configuration step, but these are optional (i.e. some other tool is present for the same task) and thus won't create any problem.
    ```shell
    git clone https://github.com/RTimothyEdwards/qflow.git
    cd qflow
    git checkout qflow-1.4
    ./configure
    make
    make install
    cd ../
    ```
14. Test the setup

    Close the docker container, and execute `xhost +` command on the local machine, to enable docker to access display. 
    Restart container with `docker exec -it qflow /bin/bash`. 
    Using map9v3.v file provided at [QFlow](http://opencircuitdesign.com/qflow/) to test the setup.
    Store the file in `work/` directory and lauch qflow with command `qflow gui`.
15. Creating Docker image

    ```shell
    docker commit <container-id> <hub-user>/<repo-name>[:<tag>]
    ```
    or
    ```shell
    docker commit <existing-container> <hub-user>/<repo-name>[:<tag>]
    ```

## Physical Design with QFlow
Once the RTL design and debugging is complete, the physical design procedure is performed with QFlow. To achieve this, store the RTL file(s) in the `/home/work/input/` directory. In case of multiple files, add a `.fl` file listing all of them in hierarchical order. </br>
A `qflow.tcl` script is included in the `/home/work` directory which automates the flow and can be modified as per the requirement. Make sure to specify parameters for special flavoured RTL2GDSII flow. The structure of this tcl script is explained below.

### qflow.tcl Script Structure
1. __Command line arguments__

    The top module name & technology to be used are provided to the tcl script as command-line arguments. Here, the file containing the top module should ideally be named as <top_module>.v or <top_module>.sv and in case of multiple files <top_module>.fl should also be included.

2. __Directory structure creation__

    The script performs a sanity check for the availability of input directory & RTL. It then creates the output directory with the <top_module> name and the `source`, `synthesis` & `layout` directories inside it. This is required for proper log and output dumping from QFlow, otherwise everything will be dumped in a common file and will be difficult to manage. 

3. __qflow_vars.sh file creation__

    QFlow requires the presence of qflow_vars.sh file specifying the various directories (including RTL, technology files & output). This is created through the tcl script.

4. __project_vars.sh file creation__

    This file is used by QFlow to run a specified flavour of physical design. In simpler words, it can be used to provide extra parameters to different tools (like Yosys, Qrouter & others). The tcl script writes this file and contains several variables controlling the values being dumped in `project_vars.sh` file. Supporting all of these variables through command-line would not be easy to manage & thus they are defined inside the `qflow.tcl` script itself. They can be modified as required. </br>
    The [following section](https://github.com/shrutiprakashgupta/QFlow-for-RTL2GDSII#project_varssh-file-structure) explains the parameters in this file, for better understanding of the flexibility provided by QFlow.

5. __Execution__
    
    ```tclsh
    tclsh qflow.tcl <top_module> <tech_node>
    # example : tclsh qflow.tcl map9v3 osu035
    ```
    The qflow.tcl script runs `qflow <top_module>` command at the end, which creates a file `qflow_exec.sh` in the `output_dir`. User can move to the output_dir after executing qflow.tcl & uncomment one command at a time in the `qflow_exec.sh` file to step through the processes. Use the following command 

    ```tcsh
    tcsh qflow_exec.sh
    ```

6. __RTL2GDSII Flow Steps__

    I am adding the paths for script files for quick reference (to understand the interface of each tool)
    1. **Synthesis** (/usr/local/share/qflow/scripts/yosys.sh)
    2. **Placement** (/usr/local/share/qflow/scripts/graywolf.sh)
    3. **Prelayout** STA (/usr/local/share/qflow/scripts/vesta.sh)
    4. **Routing** (/usr/local/share/qflow/scripts/qrouter.sh)
    5. **Postlayout** STA (/usr/local/share/qflow/scripts/vesta.sh) with extra flag -d 
    6. **Migration** (/usr/local/share/qflow/scripts/magic_db.sh) used to extract the circuit in Magic and Ngspice formats. By default the abstract view is created, i.e. all cells and subcells are shown as boxes with i/o pins, while their internal circuitary is not shown.  
    7. **Design Rule Check** (/usr/local/share/qflow/scripts/magic_drc.sh) the script dump at stdout shows drc = num, where num is the number of drc violations.
    8. **Layout vs Schematic Check** (/usr/local/share/qflow/scripts/netgen_lvs.sh) currently it only performs pin-to-pin mtching. 
    9. **GDS Generation** (/usr/local/share/qflow/scripts/magic_gds.sh) generates GDS file
    10. **Clean up** (/usr/local/share/qflow/scripts/cleanup.sh)
    11. **Open Magic View** (/usr/local/share/qflow/scripts/magic_view.sh)

7. __Step by Step Execution__

    1. Yosys creates a `<top_module>.ys` module in the `output_dir/source` folder. Any changes or addition to the synthesis commands can be made in this file and synthesis can be rerun with these settings.
    2. Graywolf can be provided with a file `<top_module>.cel2` in `output_dir/layout` folder, which holds the pin placement hints. A sample file is provided in the `input` directory here. For more information check [this link](http://opencircuitdesign.com/qflow/tutorial.html#Pins). 
    3. It is always a good idea to run placement & routing without pin constraints (or hint) file first and then rerun with it. This helps in making sure that no errors occur due to overconstraint on pin placements. 
    4. STA (Static Timing Analysis) is performed twice, once after placement and then after routing. The difference between both of these cases is that the previous one is just for sanity check. However, once routing is performed, the delays of cells and wires used for routing is also added. This gives higher accuracy in the timing details. 
    5. Two important components to be monitored in the STA reports are - maximum frequency at which design would work, and wether the design meets hold timings. In case it does not meet hold timings, additional buffers need to be added in failing design routes.
    6. QFlow uses vesta for STA, and itself generates the delay files (spef & sdf files) consulting the verilog netlist and the technology files. The extra flag `-d` provided to vesta directs it to use annotated delay values while performing the timing analysis.
    7. The mazimum frequency would decrease in post_sta report as compared to the sta report, due to additional delay from the routing components. 



### project_vars.sh File Structure
1. Flow Options

    Lists the tools to be used for various steps. Should not be modified.
    ```shell
    # Flow options:
    #------------------------------------------------------------
    # set synthesis_tool = yosys
    # set placement_tool = graywolf
    # set sta_tool       = vesta
    # set router_tool    = qrouter
    # set migrate_tool   = magic_db
    # set lvs_tool       = netgen_lvs
    # set drc_tool       = magic_drc
    # set gds_tool       = magic_gds
    # set display_tool   = magic_view
    #------------------------------------------------------------
    ```
2. Synthesis Command Options

    Includes the options for Synthesis and Fanout(load) balancing steps
    ```shell
    # Synthesis command options:
    #------------------------------------------------------------
    # set hard_macros       = (in case macros/predefined modules are to be used) path to the directory containing macro definitions, i.e. the corresponding lib file
    # set yosys_options     = extra options to be passed to yosys (yosys -h lists them)
    # set yosys_script      = created automatically if not provided (yosys commands listed in a .ys file)
    # set yosys_debug       =
    # set abc_script        = created automatically if not provided
    # set nobuffers         = to ignore buffers at output (usually this should be left empty)
    # set inbuffers         = to introduce input buffers
    # set postproc_options  =
    # set xspice_options    =
    # set fill_ratios       = (specify the ratio of various types of fill cells to use)
    # set nofanout          = to not consider the fanout at each node after synthesis
    # set fanout_options    = `"-l 200 -c 30"` (-l for maximum allowable latency & -c for load capacitance at each node, i.e. gate i/o)
    # set source_file_list  = `$top_module.fl` (in case multiple files are present)
    # set is_system_verilog = `1` (1 if system verilog constructs are used. However, Iverilog supports only limited SV constructs)
    #------------------------------------------------------------
    ```
3. STA (Static Timing Analysis) Command Options

    Vesta is used to perform STA. The following paramaters are included
    ```shell 
    # STA command options:
    #------------------------------------------------------------
    # Minimum period of the clock use "--period value" (value in ps)
    # set vesta_options     = `"--summary reports --long"` (for specifying minimum expected clock period as 5ps, add --period 5)
    #------------------------------------------------------------
    ```
4. Placement Command Options

    Includes options for Graywolf
    ```shell
    # Placement command options:
    #------------------------------------------------------------
    # set initial_density    = (this value can be atmost 1, and should be set to lower values for big designs, as at 100% density routing congestion may occur)
    # set graywolf_options   = (check with graywolf -h)
    # set addspacers_options = "-stripe 5 50 PG -nostretch" (to specify Power and Gate alternate strips of 5 microns spaced at 50 microns)
    # set addspacers_power   =
    #------------------------------------------------------------
    ```
5. Router Command Options

    Options specified for Qrouter 
    ```shell
    # Router command options:
    #------------------------------------------------------------
    # set qrouter_options   =
    # set route_show        = `1` (set to 1 for running router with view ON)
    # set route_layers      = (specify the number of layers to use)
    # set via_use           = (list of available vias)
    # set via_stacks        = (number of vias which can be stacked over each other)
    # set qrouter_nocleanup =
    #------------------------------------------------------------
    ```
6. Other Options

    These options relate to other steps like DRC, LVS & Others.
    ```shell 
    # Other options:
    #------------------------------------------------------------
    # set migrate_gdsview =
    # set migrate_options =
    # set lef_options = `-hide` (this command-line argument can be used to dump abstract blocks in case of very big designs and thus reduce the size of LEF file)
    # set drc_gdsview = (set this to use GDS-view of cells instead of abstracted views for DRC, this would increase DRC reliability but will increase time & complexity as well)
    # set drc_options =
    # set gds_options =
    #------------------------------------------------------------
    ```

The parameters which are not explained in detail can be left as it is for general use case. However, more details on 
project_vars.sh parameters can be found [here](http://opencircuitdesign.com/qflow/reference.html#GUI). 

## References
1. [Muchen He's Blog](https://www.muchen.ca/documents/ELEC402/t0-qflow.html)
2. [QFlow Github Repo](https://github.com/RTimothyEdwards/qflow.git)
3. [QFlow Website](http://opencircuitdesign.com/qflow/)
4. [Tcl cheat sheet](http://www.cheat-sheets.org/saved-copy/TclTk_quickref.pdf)
