#!/bin/bash
# -------------------------------------------------------------------------------------------------
# Copyright (C) 2023 Advanced Micro Devices, Inc
# SPDX-License-Identifier: MIT
# -------------------------------------------------------------------------------------------------

set -e  # stop on first real error so you don't chase cascading failures

# Build MTS necessary patch to xrfdc package
if [ ! -d "PYNQ" ]; then
    echo "Cloning the PYNQ repository"
    git clone https://github.com/xilinx/PYNQ
else
    echo "PYNQ already cloned, skipping"
fi

cd PYNQ

# git apply fails if patch is already applied; --check + reverse-check guards it
if git apply --check ../boards/patches/xrfdc_mts.patch 2>/dev/null; then
    echo "Applying xrfdc MTS patch"
    git apply ../boards/patches/xrfdc_mts.patch
elif git apply --reverse --check ../boards/patches/xrfdc_mts.patch 2>/dev/null; then
    echo "xrfdc MTS patch already applied, skipping"
else
    echo "WARNING: patch neither applies cleanly nor is already applied; check manually"
fi

pushd sdbuild/packages/xrfdc
. pre.sh
. qemu.sh
popd
cd ..

# Create a device-tree overlay to access PL-DRAM
sudo apt-get update -y
sudo apt-get install -y device-tree-compiler
cd boards/$BOARD/dts
make
cp ddr4.dtbo ../../../rfsoc_mts/
cd ../../..

# Install python package and notebook (pip reinstall is idempotent)
python3 -m pip install . --no-build-isolation
pynq-get-notebooks RFSoC-MTS -p $PYNQ_JUPYTER_NOTEBOOKS -f

# Clone and install the MOLLER RFSoC software package (rfsoc_moller)
if [ ! -d "moller_rfsoc_sw" ]; then
    echo "Cloning the MOLLER RFSoC software repository"
    git clone https://github.com/cameronpoe/moller_rfsoc_sw
else
    echo "moller_rfsoc_sw already cloned, updating"
    git -C moller_rfsoc_sw pull
fi
python3 -m pip install ./moller_rfsoc_sw   # <-- fixed: matches the cloned dir name

echo "$BOARD Ready..."