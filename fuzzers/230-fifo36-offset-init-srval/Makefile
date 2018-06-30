
N := 1
SPECIMENS := $(addprefix specimen_,$(shell seq -f '%03.0f' $(N)))
SPECIMENS_OK := $(addsuffix /OK,$(SPECIMENS))

database: $(SPECIMENS_OK)
	${XRAY_SEGMATCH} -o seg_bram_l.segbits $(addsuffix /segdata_bram_l_*.txt,$(SPECIMENS))
	${XRAY_SEGMATCH} -o seg_bram_r.segbits $(addsuffix /segdata_bram_r_*.txt,$(SPECIMENS))

pushdb:
	${XRAY_MERGEDB} bram_l seg_bram_l.segbits
	${XRAY_MERGEDB} bram_r seg_bram_r.segbits
	${XRAY_DBFIXUP}

$(SPECIMENS_OK):
	bash generate.sh $(subst /OK,,$@)
	touch $@

run:
	$(MAKE) clean
	$(MAKE) database
	$(MAKE) pushdb
	touch run.ok

clean:
	rm -rf specimen_[0-9][0-9][0-9]/ seg_bram_l.segbits seg_bram_r.segbits run.ok

.PHONY: database pushdb run clean

