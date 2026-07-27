# MOLLER BCM Receiver Project

This repo forks the RFSoC-PYNQ Multi-Tile Synchronization Overlay to provide firmware and software for use in the receiver for BCM readout in MOLLER. The repo contains everything needed to a) work on the firmware and create the bitstream and b) create a board image. Currently, only option a) is at a working stage right now.

## Firmware

The firmware lives in the `boards` directory. For the RFSoC4x2, the project directory is `boards/RFSoC4x2/build_mts/`. From that directory you can run various `make` commands. The main ones to know are `make rebuild_tcl`, which recreates necessary `.tcl` files if you edit the project in the GUI (these are what you store in version control), and `make moller`, which creates the bitstream. I will update this section more later with more instructions.

## License 
[MIT](./LICENSE)
