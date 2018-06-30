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

foreach site [get_sites -of_objects [filter [roi_tiles] -filter {TYPE == "BRAM_L" || TYPE == "BRAM_R"}] -filter {SITE_TYPE == RAMB18E1 || SITE_TYPE == FIFO18E1}] {
	set cell [create_cell -reference RAMB18E1 ${site}_cell]
	lappend cells $cell
	set_property LOC $site $cell
	foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && NAME =~ "*CLK"} ] {
		connect_net -net $clk_net -objects $pin
	}
	foreach pin [get_pins -of_objects $cell -filter {DIRECTION == "IN" && NAME !~ "*CLK"} ] {
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

proc randhex2 {} {
	set s "[format %x [expr {int(rand()*4)}]]"
}

for {set i 10} {$i < 40} {incr i} {
	foreach cell $cells {
		set_property SRVAL_A "18'h[randhex2][randhex 4]" $cell
		set_property SRVAL_B "18'h[randhex2][randhex 4]" $cell
		set_property INIT_A "18'h[randhex2][randhex 4]" $cell
		set_property INIT_B "18'h[randhex2][randhex 4]" $cell
		set_property DOA_REG "[expr {int(rand()*2)}]" $cell
		set_property DOB_REG "[expr {int(rand()*2)}]" $cell
	}
	write_checkpoint -force design_${i}.dcp
	write_bitstream -force design_${i}.bit
	write_txtdata design_${i}.txt
}

