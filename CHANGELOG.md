# Changelog

# Version 1.X.X

Version 1.X.X of the firmware is the first operable firmware that includes external triggering. It is meant to be used for the August 2026 beam test at Jefferson lab.

### Version 1.0.1

First functioning version of the firmware. It includes the ability to toggle between internal trigger or external trigger via the PMod interface; the ADCs sample at 5 GSamp/sec and are decimated down to 15.625 MSamp/sec; all four ADCs are read out as I/Q data to the PL DDR4; the external trigger time stamps are read out to contiguous memory in the PS DDR4. 

### Version 1.0.2

Same as `v1.0.1`, but it includes an integrated logic analyzer (ILA) to debug the external trigger. The associated pins are:
- probe0 [0:0]: the external trigger signal after it goes through the `trigger_timestamp` module's `xpm_cdc_single`, which is a single-bit clock domain crossing logic block. 
- probe1 [0:0]: the external trigger signal directly from the FPGA pin AH17. 
- probe2 [0:0]: `trigger_select` bit. 
- probe3 [31:0]: `num_triggers` word.
  
The reason for putting this in was a bug that was seen when the waveform generator was on and connected to the RFSoC, but no triggers were registered. It turned out to be a cabling issue, not a firmware issue. 
