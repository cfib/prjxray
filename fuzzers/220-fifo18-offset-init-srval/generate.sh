#!/bin/bash

source ${XRAY_GENHEADER}

vivado -mode batch -source ../generate.tcl

for i in {10..59}; do
	${XRAY_BITREAD} -F $XRAY_ROI_FRAMES -o design_${i}.bits -z -y design_${i}.bit
	python3 ../generate.py $i
done

