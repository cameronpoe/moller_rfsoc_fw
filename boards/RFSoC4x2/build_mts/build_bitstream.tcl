# -------------------------------------------------------------------------------------------------
# Copyright (C) 2023 Advanced Micro Devices, Inc
# SPDX-License-Identifier: MIT
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --

set overlay_name [lindex $argv 0]
set design_name [lindex $argv 0]

# Open project
open_project ./${overlay_name}/${overlay_name}.xpr

# Call implement
launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1

