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
# source gty_trig.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./gty_test/gty_test.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project gty_test gty_test -part xczu48dr-ffvg1517-2-e
  set_property BOARD_PART realdigital.org:rfsoc4x2:part0:1.0 [current_project]
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:gtwizard_ultrascale:1.7 }
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
# CREATE IP gty_trig
##################################################################

set gty_trig [create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gty_trig]

set_property -dict { 
  CONFIG.CHANNEL_ENABLE {X0Y7 X0Y4}
  CONFIG.RX_MASTER_CHANNEL {X0Y7}
  CONFIG.RX_PPM_OFFSET {100}
  CONFIG.INS_LOSS_NYQ {3}
  CONFIG.TX_LINE_RATE {1.25}
  CONFIG.TX_PLL_TYPE {QPLL0}
  CONFIG.TX_REFCLK_FREQUENCY {156.25}
  CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK}
  CONFIG.RX_LINE_RATE {1.25}
  CONFIG.RX_PLL_TYPE {QPLL0}
  CONFIG.RX_REFCLK_FREQUENCY {156.25}
  CONFIG.RX_EQ_MODE {LPM}
  CONFIG.RX_JTOL_FC {0.74985}
  CONFIG.RX_CB_NUM_SEQ {0}
  CONFIG.RX_CB_MAX_SKEW {1}
  CONFIG.RX_CB_VAL_0_0 {00000000}
  CONFIG.RX_CB_K_0_0 {false}
  CONFIG.RX_CC_NUM_SEQ {0}
  CONFIG.RX_CC_LEN_SEQ {1}
  CONFIG.RX_CC_VAL {00000000000000000000000000000000000000000000000000000000000000000000000000000000}
  CONFIG.RX_CC_VAL_0_0 {00000000}
  CONFIG.RX_CC_K_0_0 {false}
  CONFIG.RX_CC_VAL_0_1 {00000000}
  CONFIG.RX_CC_K_0_1 {false}
  CONFIG.ENABLE_OPTIONAL_PORTS {loopback_in rxcdrhold_in rxpolarity_in rxprbscntreset_in rxprbssel_in txpolarity_in txprbsforceerr_in txprbssel_in qpll0lock_out rxbufstatus_out rxcdrlock_out rxprbserr_out rxprbslocked_out txbufstatus_out}
  CONFIG.RX_REFCLK_SOURCE {}
  CONFIG.TX_REFCLK_SOURCE {}
  CONFIG.PRESET {GTY-Aurora_8B10B}
  CONFIG.TXPROGDIV_FREQ_SOURCE {QPLL0}
  CONFIG.TXPROGDIV_FREQ_VAL {62.5}
  CONFIG.FREERUN_FREQUENCY {31.25}
} [get_ips gty_trig]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $gty_trig

##################################################################

