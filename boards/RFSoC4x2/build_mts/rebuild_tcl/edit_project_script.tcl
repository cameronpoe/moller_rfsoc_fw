set input_script "mts_MOLLER.tcl"
set output_script "mts_MOLLER_edited.tcl"
set ip_script_to_source "./mts_MOLLER_fir_compiler_0.tcl"

set fp_in [open $input_script r]
set fp_out [open $output_script w]

set in_block "none"
set fir_source_injected 0    ;# guard: only inject the FIR source once

# Makes sure RFSoC4x2 board files are located
set _script_dir [file normalize [file dirname [info script]]]
set_param board.repoPaths [list [file normalize "$_script_dir/../board_files"]]

while {[gets $fp_in line] >= 0} {

    # --- Fix the polluted board_id: rewrite and skip the original line ---
    if {[regexp {platform\.board_id} $line]} {
        puts $fp_out {  set_property -name "platform.board_id" -value "rfsoc4x2" -objects $obj}
        continue
    }

    # Detect the start of the targeted blocks
    if {[string match "*# Import local files from the original project*" $line]} {
        set in_block "import_local"
    } elseif {[regexp {# Set '\w+' fileset file properties for local files} $line]} {
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

        # Inject the FIR source command ONLY on the first import block
        if {!$fir_source_injected} {
            puts $fp_out ""
            puts $fp_out "# Source the custom IP generation script"
            puts $fp_out "source $ip_script_to_source"
            puts $fp_out ""
            set fir_source_injected 1
        }

    } elseif {$in_block eq "set_properties" && \
              ([regexp {^\s*\}\s*$} $line] || [regexp {^\s*$} $line])} {
        set in_block "none"
    } elseif {$in_block eq "if_get_files" && [regexp {^\s*\}\s*$} $line]} {
        set in_block "none"
    }
}

close $fp_in
close $fp_out
puts "Successfully parsed the script, commented out local IP imports, injected a single source command, and corrected board_id."
