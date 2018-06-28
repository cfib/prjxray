#!/usr/bin/env python3

import sys, os, re

sys.path.append("../../../utils/")
from segmaker import segmaker

segmk = segmaker("design_%s.bits" % sys.argv[1])

pipdata = dict()
ignpip = set()

wm = ["WRITE_FIRST","READ_FIRST","NO_CHANGE"]

print("Loading tags from design.txt.")
with open("design_%s.txt" % sys.argv[1], "r") as f:
    for line in f:
        tile, loc, write_mode_a, write_mode_b = line.split()

        flags_a = {}
        flags_b = {}
        for k in wm:
            flags_a[k] = 0
            flags_b[k] = 0

        flags_a[write_mode_a] = 1
        flags_b[write_mode_b] = 1

        segmk.addtag(tile, "RAMB36.WRITE_MODE_READ_FIRST_A_0", flags_a["READ_FIRST"])
        segmk.addtag(tile, "RAMB36.WRITE_MODE_READ_FIRST_A_1", flags_a["READ_FIRST"])

        segmk.addtag(tile, "RAMB36.WRITE_MODE_READ_FIRST_B_0", flags_b["READ_FIRST"])
        segmk.addtag(tile, "RAMB36.WRITE_MODE_READ_FIRST_B_1", flags_b["READ_FIRST"])

        segmk.addtag(tile, "RAMB36.WRITE_MODE_NO_CHANGE_A_0", flags_a["NO_CHANGE"])
        segmk.addtag(tile, "RAMB36.WRITE_MODE_NO_CHANGE_A_1", flags_a["NO_CHANGE"])

        segmk.addtag(tile, "RAMB36.WRITE_MODE_NO_CHANGE_B_0", flags_b["NO_CHANGE"])
        segmk.addtag(tile, "RAMB36.WRITE_MODE_NO_CHANGE_B_1", flags_b["NO_CHANGE"])


segmk.compile()
segmk.write(suffix=sys.argv[1])
