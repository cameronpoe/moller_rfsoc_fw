# -------------------------------------------------------------------------------------------------
# gty_test.xdc: RFSoC4x2 QSFP / GTY bank 128 receive test
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# GTY reference clock: MGTREFCLK0_128, 156.25 MHz from Si5395 OUT9 (AC-coupled on the board)
# Only the _p pin is needed; Vivado places _n (AA34) automatically.
# -------------------------------------------------------------------------------------------------
set_property PACKAGE_PIN AA33 [get_ports gty_refclk_p]
create_clock -period 6.400 -name gty_refclk [get_ports gty_refclk_p]

# GTY serial pins (RX/TX of X0Y4..X0Y7) need no constraints here: gty_trig's own XDC
# places the GT channels (LOC), and GT pins are fixed to their channel.

# -------------------------------------------------------------------------------------------------
# QSFP sideband (bank 66, 1.8 V, through the NVT2008 level shifter); pins from Real Digital 4x2_QSFP.xdc
# -------------------------------------------------------------------------------------------------
set_property PACKAGE_PIN AL21 [get_ports qsfp_resetl]   ;# out: drive 1 (not in reset)
set_property PACKAGE_PIN AN22 [get_ports qsfp_lpmode]   ;# out: drive 0 (high-power mode)
set_property PACKAGE_PIN AK22 [get_ports qsfp_modsell]  ;# out: drive 0 (module selected for I2C)
set_property PACKAGE_PIN AL22 [get_ports qsfp_modprsl]  ;# in:  0 = module present
set_property PACKAGE_PIN AM22 [get_ports qsfp_intl]     ;# in:  0 = module interrupt
set_property IOSTANDARD LVCMOS18 [get_ports qsfp_*]
set_property PULLUP TRUE [get_ports {qsfp_modprsl qsfp_intl}]  ;# open-drain from the module

# Static or slow signals: no timing relationship
set_false_path -to   [get_ports {qsfp_resetl qsfp_lpmode qsfp_modsell}]
set_false_path -from [get_ports {qsfp_modprsl qsfp_intl}]

# -------------------------------------------------------------------------------------------------
# Clocks
# -------------------------------------------------------------------------------------------------
# pl_clk0 (125 MHz) is constrained by the PS IP. The 31.25 MHz BUFGCE_DIV clock is derived from it
# automatically. The GT TXOUTCLK/RXOUTCLK clocks are derived automatically from gty_refclk.
# There's deliberately no blanket set_clock_groups: cross clock domains only through xpm_cdc_* macros
# (they bring their own constraints), so the timing report flags any crossing you forgot.

# -------------------------------------------------------------------------------------------------
# Bitstream (from mts.xdc)
# -------------------------------------------------------------------------------------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
