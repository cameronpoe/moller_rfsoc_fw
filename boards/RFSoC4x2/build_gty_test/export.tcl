# Write the block design and standalone IP of ./gty_test back to tracked Tcl files.
# Run from this directory:  vivado -mode batch -notrace -source export.tcl

open_project gty_test/gty_test.xpr
open_bd_design [get_files gty_test.bd]
write_bd_tcl -force bd/gty_test.tcl
foreach ip [get_ips -exclude_bd_ips] { write_ip_tcl -force $ip ip/[get_property NAME $ip].tcl }
