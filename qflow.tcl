# ------------ QFlow Tcl script for RTL2GDSII flow ------------
if {$argc != 2} {
    puts "Usage: tclsh qflow.tcl <top_module> <tech>"
    puts "\t<top_module>"
    puts "\t\t\ttop module name"
    puts "\t<tech>"
    puts "\t\t\ttech node to be used"
    puts ""
    puts "Example: tclsh qflow.tcl map9v3.v osu035"
    puts ""
    puts "Include the RTL files in /home/work/input directory."
    puts "The RTL files should be named after the modules included. "
    puts "Add a .fl file in the input directory (listing all files in hierarchical order) in case of multiple files."
    exit
}

# ------------ Project Details Initialization -------------
set input_dir   /home/work/input
set top_module  [lindex $argv 0]
set output_dir  /home/work/$top_module
set tech        [lindex $argv 1]

# ------------- Creating required directory structure for QFlow --------------
proc find_dir {dir_name} {
    set dir_path [glob -type d -nocomplain -- $dir_name]
    set dir_found [llength $dir_path]
    return $dir_found
}

proc find_file {file_dir file_name} {
    set file_path [glob -directory $file_dir -type f -nocomplain -- $file_name]
    set file_found [llength $file_path]
    return $file_found
}

# Input directory
set dir_found [find_dir $input_dir] 
if {$dir_found == 0} {error "Input directory unavailable"}

# Output directory
set dir_found [find_dir $output_dir] 
if {$dir_found == 0} {file mkdir $output_dir} 
set dir_found [find_dir $output_dir/source] 
if {$dir_found == 0} {file mkdir $output_dir/source} 
set dir_found [find_dir $output_dir/synthesis] 
if {$dir_found == 0} {file mkdir $output_dir/synthesis} 
set dir_found [find_dir $output_dir/layout] 
if {$dir_found == 0} {file mkdir $output_dir/layout}

# Input RTL File
set system_verilog 0
set fl_file ""
set file_found [find_file $input_dir $top_module.fl] 
if {$file_found == 1} {
    file copy -force $input_dir/$top_module.fl $output_dir/source/
    set src_list [open $input_dir/$top_module.fl r]              
    while {[gets $src_list line]>=0} {   
        file copy -force $input_dir/$line $output_dir/source/  
    }
    set fl_file $top_module.fl
} else { 
    set file_found [find_file $input_dir $top_module.v]
    if {$file_found == 1} {
        file copy -force $input_dir/$top_module.v $output_dir/source/
    } else { 
        set file_found [find_file $input_dir $top_module.sv]
        if {$file_found == 1} {
            set system_verilog 1
            file copy -force $input_dir/$top_module.sv $output_dir/source/
        } else { error "RTL file unavailable"}
    }
}

# Input CEL2 File (Optional)
set file_found [find_file $input_dir $top_module.cel2] 
if {$file_found == 1} {
    file copy -force $input_dir/$top_module.cel2 $output_dir/layout/
} 

# ------------- Creating qflow_vars.sh -------------
set  varsfile [open $output_dir/qflow_vars.sh w+]

puts $varsfile "#!/bin/tcsh -f"
puts $varsfile "#-------------------------------------------"
puts $varsfile [join [list "# qflow variables for project /home/work/" $top_module] ""]
puts $varsfile "#-------------------------------------------"

puts $varsfile "#-------------------------------------------"
puts $varsfile "set qflowversion=1.4.98"
puts $varsfile [join [list "set projectpath=" $output_dir] ""]
puts $varsfile [join [list "set techdir=/usr/local/share/qflow/tech/" $tech] ""]
puts $varsfile [join [list "set sourcedir=" $output_dir "/source"] ""]
puts $varsfile [join [list "set synthdir=" $output_dir "/synthesis"] ""]
puts $varsfile [join [list "set layoutdir=" $output_dir "/layout"] ""] 
puts $varsfile [join [list "set techname=" $tech] ""]
puts $varsfile "set scriptdir=/usr/local/share/qflow/scripts"
puts $varsfile "set bindir=/usr/local/share/qflow/bin"
puts $varsfile [join [list "set logdir=" $output_dir "/log"] ""]
puts $varsfile "#-------------------------------------------"

close $varsfile 

# ------------- Creating project_vars.sh -------------
set  projfile [open $output_dir/project_vars.sh w+]

puts $projfile "#!/bin/tcsh -f"
puts $projfile "#------------------------------------------------------------"
puts $projfile [join [list "# project variables for project " $output_dir] ""]
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# Flow options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# set synthesis_tool = yosys"
puts $projfile "# set placement_tool = graywolf"
puts $projfile "# set sta_tool       = vesta"
puts $projfile "# set router_tool    = qrouter"
puts $projfile "# set migrate_tool   = magic_db"
puts $projfile "# set lvs_tool       = netgen_lvs"
puts $projfile "# set drc_tool       = magic_drc"
puts $projfile "# set gds_tool       = magic_gds"
puts $projfile "# set display_tool   = magic_view"
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# Synthesis command options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# set hard_macros       =" 
puts $projfile "# set yosys_options     ="
puts $projfile "# set yosys_script      ="
puts $projfile "# set yosys_debug       ="
puts $projfile "# set abc_script        ="
puts $projfile "# set nobuffers         ="
puts $projfile "# set inbuffers         ="
puts $projfile "# set postproc_options  ="
puts $projfile "# set xspice_options    ="
puts $projfile "# set fill_ratios       ="
puts $projfile "# set nofanout          ="
puts $projfile "# set fanout_options    = \"-l 200 -c 30\""
puts $projfile [join [list "# set source_file_list  = " $fl_file] ""]
puts $projfile [join [list "# set is_system_verilog = " $system_verilog] ""]
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# STA command options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# Minimum period of the clock use \"--period value\" (value in ps)"
puts $projfile "# set vesta_options     = \"--summary reports --long\""
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# Placement command options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# set initial_density    ="
puts $projfile "# set graywolf_options   ="
puts $projfile "# set addspacers_options = \"-stripe 5 50 PG -nostretch\" "
puts $projfile "# set addspacers_power   ="
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# Router command options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# set qrouter_options   ="
puts $projfile "# set route_show        ="
puts $projfile "# set route_layers      ="
puts $projfile "# set via_use           ="
puts $projfile "# set via_stacks        ="
puts $projfile "# set qrouter_nocleanup ="
puts $projfile "#------------------------------------------------------------"

puts $projfile ""
puts $projfile "# Other options:"
puts $projfile "#------------------------------------------------------------"
puts $projfile "# set migrate_gdsview = "
puts $projfile "# set migrate_options = "
puts $projfile "# set lef_options     = "
puts $projfile "# set drc_gdsview     = "
puts $projfile "# set drc_options     = "
puts $projfile "# set gds_options     = "
puts $projfile "#------------------------------------------------------------"

close $projfile 

# ------------ Executing QFlow to generate command file ------------
# The qflow_exec.sh file will be dumped in output_dir, individual commands can be 
# uncommented and stepped through by executing :- tcsh qflow_exec.sh
cd $output_dir
set script [join [list "qflow " $top_module] ""]
puts [exec /usr/bin/sh -c $script] 
