# Recreate the Vivado project ./gty_test from the files tracked in git.
# Run from this directory:  vivado -mode batch -notrace -source create_project.tcl

set_param board.repoPaths [list [file normalize ./board_files]]

create_project gty_test ./gty_test -part xczu48dr-ffvg1517-2-e
set_property board_part_repo_paths [file normalize ./board_files] [current_project]
set_property board_part realdigital.org:rfsoc4x2:part0:1.0 [current_project]

# Custom IP repository and sources
#set_property ip_repo_paths [file normalize ../../ip] [current_fileset]
#update_ip_catalog
#add_files [glob ../../ip/rtl/*.v]
add_files -fileset constrs_1 gty_test.xdc
#add_files -fileset sim_1 [glob ../../tb/*.v]
#set_property top adc_mux_v2_tb [get_filesets sim_1]

# Standalone IP (written by export.tcl), then the block design
foreach f [glob -nocomplain ip/*.tcl] { source $f }
source bd/gty_test.tcl

add_files -norecurse [make_wrapper -files [get_files gty_test.bd] -top]
set_property top gty_test_wrapper [current_fileset]

# Stamp the git hash into the bitstream USERID
set_property STEPS.WRITE_BITSTREAM.TCL.PRE [file normalize userid.tcl] [get_runs impl_1]
