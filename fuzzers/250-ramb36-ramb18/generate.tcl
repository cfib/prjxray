create_project -force -part $::env(XRAY_PART) design design

read_verilog ../top.v
synth_design -top top

set_property -dict "PACKAGE_PIN $::env(XRAY_PIN_02) IOSTANDARD LVCMOS33" [get_ports clk]
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

set clk_net [get_nets -of_objects  [get_ports clk]]



proc write_txtdata {filename} {
	upvar 1 cells cells
	puts "Writing $filename."
	set fp [open $filename w]
	foreach cell $cells {
		set loc [get_property LOC $cell]
		set srval_a [get_property SRVAL_A $cell]
		set srval_b [get_property SRVAL_B $cell]
		set init_a  [get_property INIT_A $cell]
		set init_b  [get_property INIT_B $cell]
		set doa_reg  [get_property DOA_REG $cell]
		set dob_reg  [get_property DOB_REG $cell]
		set tile [get_tiles -of_objects [get_sites -filter "NAME == $loc"]]
		puts $fp "$tile $loc $init_a $init_b $srval_a $srval_b $doa_reg $dob_reg"
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



for {set i 10} {$i < 40} {incr i} {

	set cells []
	set fp [open design_${i}.txt w]
	foreach tile [filter [roi_tiles] -filter {TYPE == "BRAM_L" || TYPE == "BRAM_R"}] {
		set modes [list "RAMB36" "RAMB18_0" "RAMB18_1"]
		set mode [lindex $modes [expr {int(rand()*[llength $modes]}]]
		if { $mode == "RAMB36" } {
			set cell [create_cell -reference RAMB36E1 ${tile}_cell]
			lappend cells $cell
			set loc [get_sites $tile RAMB36*]
		} elseif { $mode == "RAMB18_0" } {
			set cell [create_cell -reference RAMB18E1 ${tile}_cell]
			lappend cells $cell
			set loc [get_sites $tile -regex { RAMB18.*[02468] } ]
		} elseif { $mode == "RAMB18_1" } {
			set cell [create_cell -reference RAMB18E1 ${tile}_cell]
			lappend cells $cell
			set loc [get_sites $tile -regex { RAMB18.*[^02468] } ]
		}
		lappend cells $cell
		set_property LOC $loc $cell
		foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && NAME =~ "*CLK"} ] {
			connect_net -net $clk_net -objects $pin
		}
		foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && NAME !~ "*CLK"} ] {
			connect_net -net $gnd_net -objects $pin
		}
		puts $fp "$tile $loc $mode"
	}
	close $fp

	route_design
	write_checkpoint -force design_${i}.dcp
	write_bitstream -force design_${i}.bit
	foreach cell $cells {
		remove_cell $cell
	}
}


