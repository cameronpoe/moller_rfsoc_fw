##################################################################
# CHECK VIVADO VERSION
##################################################################

set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
  return 1
}

##################################################################
# START
##################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source mts_MOLLER_fir_compiler_0.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./mts/mts.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project mts mts -part xczu48dr-fsvg1517-2-e
  set_property BOARD_PART xilinx.com:zcu208:part0:2.0 [current_project]
  set_property target_language VHDL [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:fir_compiler:7.2 }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# fir_compiler_0 FILES
##################################################################

proc write_fir_compiler_dec_8x_coeffs { fir_compiler_dec_8x_coeffs_filepath } {
  set fir_compiler_dec_8x_coeffs [open $fir_compiler_dec_8x_coeffs_filepath  w+]

  puts $fir_compiler_dec_8x_coeffs {RADIX=10;}
  puts $fir_compiler_dec_8x_coeffs {COEFDATA=37 35 28 16 0 -18 -35 -50 -59 -59 -50 -30 0 36 72 103 122 124 104 61 0 -73 -146 -207 -242 -242 -200 -117 0 136 270 379 440 436 357 207 0 -237 -468 -654 -757 -747 -611 -354 0 404 800 1120 1300 1290 1062 620 0 -726 -1458 -2079 -2469 -2517 -2142 -1300 0 1698 3684 5808 7893 9756 11228 12171 12496 12171 11228 9756 7893 5808 3684 1698 0 -1300 -2142 -2517 -2469 -2079 -1458 -726 0 620 1062 1290 1300 1120 800 404 0 -354 -611 -747 -757 -654 -468 -237 0 207 357 436 440 379 270 136 0 -117 -200 -242 -242 -207 -146 -73 0 61 104 124 122 103 72 36 0 -30 -50 -59 -59 -50 -35 -18 0 16 28 35 37;}

  flush $fir_compiler_dec_8x_coeffs
  close $fir_compiler_dec_8x_coeffs
}

##################################################################
# CREATE IP fir_compiler_0
##################################################################

set fir_compiler_0 [create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fir_compiler_0]

write_fir_compiler_dec_8x_coeffs  [file join [get_property IP_DIR [get_ips fir_compiler_0]] dec_8x_coeffs.coe]
set_property -dict { 
  CONFIG.CoefficientSource {COE_File}
  CONFIG.Coefficient_File {dec_8x_coeffs.coe}
  CONFIG.Coefficient_Sets {1}
  CONFIG.Filter_Type {Decimation}
  CONFIG.Interpolation_Rate {1}
  CONFIG.Decimation_Rate {8}
  CONFIG.Zero_Pack_Factor {1}
  CONFIG.Number_Channels {1}
  CONFIG.RateSpecification {Frequency_Specification}
  CONFIG.Sample_Frequency {125}
  CONFIG.Clock_Frequency {125}
  CONFIG.Coefficient_Sign {Signed}
  CONFIG.Quantization {Integer_Coefficients}
  CONFIG.Coefficient_Width {16}
  CONFIG.Coefficient_Fractional_Bits {0}
  CONFIG.Coefficient_Structure {Inferred}
  CONFIG.Data_Width {16}
  CONFIG.Output_Rounding_Mode {Truncate_LSBs}
  CONFIG.Output_Width {24}
  CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate}
  CONFIG.ColumnConfig {9}
  CONFIG.DATA_Has_TLAST {Not_Required}
  CONFIG.S_DATA_Has_FIFO {false}
  CONFIG.Has_ARESETn {true}
} [get_ips fir_compiler_0]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $fir_compiler_0

##################################################################

