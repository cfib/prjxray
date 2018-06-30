create_project -force -part $::env(XRAY_PART) design design

read_verilog ../top.v
synth_design -top top

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

foreach site [get_sites -of_objects [filter [roi_tiles] -filter {TYPE == "BRAM_L" || TYPE == "BRAM_R"}] -filter {SITE_TYPE == RAMB18E1 || SITE_TYPE == FIFO18E1}] {
	set cell [create_cell -reference RAMB18E1 ${site}_cell]
	lappend cells $cell
	set_property LOC $site $cell
	foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN"}] {
		connect_net -net $gnd_net -objects $pin
	}
}

route_design

proc write_txtdata {filename} {
	upvar 1 cells cells
	puts "Writing $filename."
	set fp [open $filename w]
	foreach cell $cells {
		set loc [get_property LOC $cell]
		set write_mode_a [get_property WRITE_MODE_A $cell]
		set write_mode_b [get_property WRITE_MODE_B $cell]
		set tile [get_tiles -of_objects [get_sites -filter "NAME == $loc"]]
		puts $fp "$tile $loc $write_mode_a $write_mode_b"
	}
	close $fp
}

proc rand_write_mode {} {
	set write_modes [list "WRITE_FIRST" "READ_FIRST" "NO_CHANGE"]
	set s "[lindex $write_modes [expr {int(rand()*[llength $write_modes])}]]"
	return $s
}



for {set i 10} {$i < 30} {incr i} {
	foreach cell $cells {
		set_property WRITE_MODE_A "[rand_write_mode]" $cell
		set_property WRITE_MODE_B "[rand_write_mode]" $cell
	}
	write_checkpoint -force design_${i}.dcp
	write_bitstream -force design_${i}.bit
	write_txtdata design_${i}.txt
}

