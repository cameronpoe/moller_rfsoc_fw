# Configuration variables
set origin_dir ".."
set project_name "mts.xpr"
set ip_name "fir_compiler_0"
set ip_tcl_file "mts_MOLLER_fir_compiler_0.tcl"
set project_tcl_file "mts_MOLLER.tcl"
set editing_script "../rebuild_tcl_new/edit_project_script.tcl"

# Makes sure RFSoC4x2 board files are located
set _script_dir [file normalize [file dirname [info script]]]
set_param board.repoPaths [list [file normalize "$_script_dir/../board_files"]]

# Open the Vivado project
open_project $project_name

# Resets impl/synth
reset_run impl_1
reset_run synth_1
set_property incremental_checkpoint "" [get_runs synth_1]
set_property auto_incremental_checkpoint 0 [get_runs synth_1]

# Generate the Tcl scripts for the IP and the project
write_ip_tcl -force [get_ips $ip_name] ${origin_dir}/${ip_tcl_file}
write_project_tcl -force ${origin_dir}/${project_tcl_file}

# Close the project to ensure file writing is complete and locks are released
close_project

# Call the secondary script to parse and edit the generated project script
#puts "Sourcing ${editing_script} to modify the project script..."
#source $editing_script
