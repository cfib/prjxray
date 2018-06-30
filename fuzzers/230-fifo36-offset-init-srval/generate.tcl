create_project -force -part $::env(XRAY_PART) design design

read_verilog ../top.v
synth_design -top top

set_property -dict "PACKAGE_PIN $::env(XRAY_PIN_02) IOSTANDARD LVCMOS33" [get_ports rce]
set_property -dict "PACKAGE_PIN $::env(XRAY_PIN_00) IOSTANDARD LVCMOS33" [get_ports i]
set_property -dict "PACKAGE_PIN $::env(XRAY_PIN_01) IOSTANDARD LVCMOS33" [get_ports o]

create_pblock roi
resize_pblock [get_pblocks roi] -add "$::env(XRAY_ROI)"

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]
set_param tcl.collectionResultDisplayLimit 0

place_design
route_design

write_checkpoint -force design.dcp

source ../../../utils/utils.tcl
set cells [list]

set gnd_net [create_net gnd_net]
set gnd_cell [create_cell -reference GND gnd_cell]
connect_net -net $gnd_net -objects [get_pins $gnd_cell/G]
set rce_net [get_nets -of_objects [get_ports rce]]

# disable some DRC errors:

set_property IS_ENABLED 0 [get_drc_checks {AVAL-14}]
set_property IS_ENABLED 0 [get_drc_checks {REQP-38}]

foreach site [get_sites -of_objects [filter [roi_tiles] -filter {TYPE == "BRAM_L" || TYPE == "BRAM_R"}] -filter {SITE_TYPE == RAMBFIFO36E1}] {
	set cell [create_cell -reference FIFO36E1 ${site}_cell]
	lappend cells $cell
	set_property LOC $site $cell
	foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && NAME !~ "*REGCE" && NAME !~ "*RSTREG"}] {
		connect_net -net $gnd_net -objects $pin
	}
	foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && (NAME =~ "*REGCE" || NAME =~ "*RSTREG")}] {
		connect_net -net $rce_net -objects $pin
	}
}

route_design

proc write_txtdata {filename} {
	upvar 1 cells cells
	puts "Writing $filename."
	set fp [open $filename w]
	foreach cell $cells {
		set loc [get_property LOC $cell]
		set almost_empty_offset [get_property ALMOST_EMPTY_OFFSET $cell]
		set almost_full_offset  [get_property ALMOST_FULL_OFFSET $cell]
		set srval  [get_property SRVAL $cell]
		set init   [get_property INIT $cell]
		set do_reg [get_property DO_REG $cell]
		set en_syn [get_property EN_SYN $cell]
		set fifo_mode [get_property FIFO_MODE $cell]
		set tile [get_tiles -of_objects [get_sites -filter "NAME == $loc"]]
		puts $fp "$tile $loc $almost_empty_offset $almost_full_offset $srval $init $do_reg $en_syn $fifo_mode"
	}
	close $fp
}

proc randhex {len} {
	set s ""
	for {set i 0} {$i < $len} {incr i} {
		set s "$s[format %x [expr {int(rand()*16)}]]"
	}
	return $s
}

proc rand_offset {} {
    return [format %x [expr {int(rand()*(8186-4))+4}]]
}

proc randhex2 {} {
	set s "[format %x [expr {int(rand()*4)}]]"
}

for {set i 10} {$i < 60} {incr i} {
	set FIFO_MODES [list "FIFO36" "FIFO36_72"]
	foreach cell $cells {
		set_property ALMOST_EMPTY_OFFSET "13'h[rand_offset]" $cell
		set_property ALMOST_FULL_OFFSET  "13'h[rand_offset]" $cell
		set_property SRVAL "72'h[randhex 18]" $cell
		set_property INIT  "72'h[randhex 18]" $cell
		set_property DO_REG "[expr {int(rand()*2)}]" $cell
		set_property EN_SYN "[expr {int(rand()*2)}]" $cell
		set_property FIFO_MODE "[lindex $FIFO_MODES [expr {int(rand()*[llength $FIFO_MODES])}]]" $cell
	}
	write_checkpoint -force design_${i}.dcp
	write_bitstream -force design_${i}.bit
	write_txtdata design_${i}.txt
}

