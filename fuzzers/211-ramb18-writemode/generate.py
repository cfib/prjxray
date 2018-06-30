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

        ramb = "RAMB18_0" if loc[-1] in "02468" else "RAMB18_1"

        flags_a[write_mode_a] = 1
        flags_b[write_mode_b] = 1

        segmk.addtag(tile, "%s.WRITE_MODE_READ_FIRST_A" % ramb, flags_a["READ_FIRST"])

        segmk.addtag(tile, "%s.WRITE_MODE_READ_FIRST_B" % ramb, flags_b["READ_FIRST"])

        segmk.addtag(tile, "%s.WRITE_MODE_NO_CHANGE_A" % ramb, flags_a["NO_CHANGE"])

        segmk.addtag(tile, "%s.WRITE_MODE_NO_CHANGE_B" % ramb, flags_b["NO_CHANGE"])


segmk.compile()
segmk.write(suffix=sys.argv[1])
