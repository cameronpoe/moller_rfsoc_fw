# Write the block design and standalone IP of ./mts back to tracked Tcl files.
# Run from this directory:  vivado -mode batch -notrace -source export.tcl

open_project mts/mts.xpr
open_bd_design [get_files mts.bd]
write_bd_tcl -force bd/mts.tcl
foreach ip [get_ips -exclude_bd_ips] { write_ip_tcl -force $ip ip/[get_property NAME $ip].tcl }
