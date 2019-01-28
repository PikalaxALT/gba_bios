data/unk_332C.bin.lz: %.lz: %
	$(GBAGFX) $< $@ -search 1 -overflow 4
