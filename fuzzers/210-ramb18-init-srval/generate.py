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
        tile, loc, init_a, init_b, srval_a, srval_b, doa_reg, dob_reg = line.split()

        init_a  = int(init_a.replace("18'h", ""), 16)
        init_b  = int(init_b.replace("18'h", ""), 16)
        srval_a = int(srval_a.replace("18'h", ""), 16)
        srval_b = int(srval_b.replace("18'h", ""), 16)
        doa_reg = int(doa_reg)
        dob_reg = int(dob_reg)

        ramb = "RAMB18_0" if loc[-1] in "02468" else "RAMB18_1"

        for i in range(18):
            # Bits are inverted
            segmk.addtag(tile, "%s.SRVAL_A[%d]" %(ramb, i), 1 ^ ((srval_a >> i) & 1))
            segmk.addtag(tile, "%s.SRVAL_B[%d]" %(ramb, i), 1 ^ ((srval_b >> i) & 1))
            segmk.addtag(tile, "%s.INIT_A[%d]" %(ramb, i), 1 ^ ((init_a >> i) & 1))
            segmk.addtag(tile, "%s.INIT_B[%d]" %(ramb, i), 1 ^ ((init_b >> i) & 1))

        segmk.addtag(tile,"%s.DOA_REG" % ramb, doa_reg)
        segmk.addtag(tile,"%s.DOB_REG" % ramb, dob_reg)

segmk.compile()
segmk.write(suffix=sys.argv[1])
