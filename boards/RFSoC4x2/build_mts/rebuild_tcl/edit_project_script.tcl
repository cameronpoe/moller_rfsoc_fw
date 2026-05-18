set input_script "mts_MOLLER.tcl"
set output_script "mts_MOLLER_edited.tcl"
set ip_script_to_source "./mts_MOLLER_fir_compiler_0.tcl"

set fp_in [open $input_script r]
set fp_out [open $output_script w]

set in_block "none"

# Makes sure RFSoC4x2 board files are located
set _script_dir [file normalize [file dirname [info script]]]
set_param board.repoPaths [list [file normalize "$_script_dir/../board_files"]]

while {[gets $fp_in line] >= 0} {
    
    # Detect the start of the targeted blocks
    if {[string match "*# Import local files from the original project*" $line]} {
        set in_block "import_local"
    } elseif {[string match "*# Set 'sources_1' fileset file properties for local files*" $line]} {
        set in_block "set_properties"
    } elseif {[regexp {^\s*if\s*\{\s*\[get_files.*\.xci\]} $line]} {
        set in_block "if_get_files"
    }

    # Prepend a comment hash if we are currently inside a targeted block
    if {$in_block ne "none"} {
        puts $fp_out "# $line"
    } else {
        puts $fp_out $line
    }

    # Detect the end of the targeted blocks to resume normal operation
    if {$in_block eq "import_local" && [regexp {^\s*set imported_files \[import_files} $line]} {
        set in_block "none"
        
        # Inject the new source command right after this block finishes
        puts $fp_out ""
        puts $fp_out "# Source the custom IP generation script"
        puts $fp_out "source $ip_script_to_source"
        puts $fp_out ""
        
    } elseif {$in_block eq "set_properties" && [regexp {^\s*\}\s*$} $line]} {
        set in_block "none"
    } elseif {$in_block eq "if_get_files" && [regexp {^\s*\}\s*$} $line]} {
        set in_block "none"
    }
}

close $fp_in
close $fp_out
puts "Successfully parsed the script, commented out local IP imports, and inserted the source command."
