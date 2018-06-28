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
        tile, loc, init_a, init_b, srval_a, srval_b = line.split()

        init_a  = int(init_a.replace("36'h", ""), 16)
        init_b  = int(init_b.replace("36'h", ""), 16)
        srval_a = int(srval_a.replace("36'h", ""), 16)
        srval_b = int(srval_b.replace("36'h", ""), 16)

        for i in range(36):
            segmk.addtag(tile, "RAMB36.SRVAL_A[%d]" % i, 1 ^ ((srval_a >> i) & 1))
            segmk.addtag(tile, "RAMB36.SRVAL_B[%d]" % i, 1 ^ ((srval_b >> i) & 1))
            segmk.addtag(tile, "RAMB36.INIT_A[%d]" % i, 1 ^ ((init_a >> i) & 1))
            segmk.addtag(tile, "RAMB36.INIT_B[%d]" % i, 1 ^ ((init_b >> i) & 1))

segmk.compile()
segmk.write(suffix=sys.argv[1])
