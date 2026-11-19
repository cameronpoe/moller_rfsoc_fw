# -------------------------------------------------------------------------------------------------
# Copyright (C) 2023 Advanced Micro Devices, Inc
# SPDX-License-Identifier: MIT
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --

set overlay_name [lindex $argv 0]
set design_name [lindex $argv 0]

# open block design
open_project ./${overlay_name}/${overlay_name}.xpr

# generate xsa
write_hw_platform -fixed -include_bit -force -file ./${overlay_name}.xsa
validate_hw_platform ./${overlay_name}.xsa

# move and rename bitstream to final location
file copy -force ./${overlay_name}/${overlay_name}.runs/impl_1/gty_test_top.bit ./${overlay_name}.bit
file copy -force ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hw_handoff/${design_name}.hwh ./${overlay_name}.hwh
