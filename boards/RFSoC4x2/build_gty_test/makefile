# -------------------------------------------------------------------------------------------------
# Copyright (C) 2023 Advanced Micro Devices, Inc
# SPDX-License-Identifier: MIT
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --

.PHONY: project export

gty_test: board_files project bitstream
	@echo
	@tput setaf 2 ; echo "Built gty_test overlays successfully!!"; tput sgr0;
	@echo

board_files:
	wget "https://www.realdigital.org/downloads/9d2af32116d5420d25da904f6a06bb1f.zip" --no-check-certificate -O bf.zip && \
	unzip bf.zip -d board_files && rm bf.zip

project:
	vivado -mode batch -notrace -source create_project.tcl

bitstream: export
	vivado -mode batch -source build_bitstream.tcl -notrace -tclargs mts

check_timing:
	vivado -mode batch -source check_timing.tcl -notrace -tclargs mts

handoff:
	vivado -mode batch -source handoff.tcl -notrace -tclargs mts

export:
	vivado -mode batch -notrace -source export.tcl

clean:
	rm -rf mts *.jou *.log NA .Xil *.xsa *.hwh *.bit
