#!/usr/bin/env python3

import sys, os, re

sys.path.append("../../../utils/")
from segmaker import segmaker

segmk = segmaker("design_%s.bits" % sys.argv[1])

pipdata = dict()
ignpip = set()

print("Loading tags from design.txt.")
with open("design_%s.txt" % sys.argv[1], "r") as f:
    for line in f:
        tile, loc, almost_empty_offset, almost_full_offset, srval, init, do_reg, en_syn, fifo_mode = line.split()

        almost_empty_offset  = int(almost_empty_offset.replace("13'h", ""), 16)
        almost_full_offset   = int(almost_full_offset.replace("13'h", ""), 16)
        srval                = int(srval.replace("72'h", ""), 16)
        init                 = int(init.replace("72'h", ""), 16)
        do_reg               = int(do_reg)
        en_syn               = int(en_syn)

        if fifo_mode == "FIFO36_72":
            fifo_mode_36_72  = 1
        else:
            fifo_mode_36_72  = 0

        ramb = "FIFO36"

        for i in range(13):
            # Bits are inverted
            segmk.addtag(tile, "%s.ALMOST_EMPTY_OFFSET[%d]" %(ramb, i), 1 ^ ((almost_empty_offset >> i) & 1))
            segmk.addtag(tile, "%s.ALMOST_FULL_OFFSET[%d]" %(ramb, i), 1 ^ ((almost_full_offset >> i) & 1))

        for i in range(72):
            segmk.addtag(tile, "%s.SRVAL[%d]" %(ramb, i), 1 ^ ((srval >> i) & 1))
            segmk.addtag(tile, "%s.INIT[%d]" %(ramb, i), 1 ^ ((srval >> i) & 1))

        segmk.addtag(tile, "%s.DO_REG" % ramb, do_reg)
        segmk.addtag(tile, "%s.EN_SYN" % ramb, en_syn)
        segmk.addtag(tile, "%s.FIFO_MODE_36_72" % ramb, fifo_mode_36_72)

segmk.compile()
segmk.write(suffix=sys.argv[1])
