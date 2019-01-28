#### Tools ####

GBAGFX   := tools/gbagfx/gbagfx
CC1      := tools/agbcc/bin/agbcc
CC1_OLD  := tools/agbcc/bin/old_agbcc
CPP      := $(DEVKITARM)/bin/arm-none-eabi-cpp
AS       := $(DEVKITARM)/bin/arm-none-eabi-as
LD       := $(DEVKITARM)/bin/arm-none-eabi-ld
OBJCOPY  := $(DEVKITARM)/bin/arm-none-eabi-objcopy

CC1FLAGS := -mthumb-interwork -Wimplicit -Wparentheses -O2 -fhex-asm
CPPFLAGS := -Itools/agbcc/include -iquote include -nostdinc -undef
ASFLAGS  := -mcpu=arm7tdmi -march=armv4t -mthumb-interwork -Iasminclude


#### Files ####

ROM      := gba_bios.bin
ELF      := $(ROM:.bin=.elf)
MAP      := $(ROM:.bin=.map)
LDSCRIPT := ldscript.txt
SOURCES  := asm/bios.s
OFILES   := $(addsuffix .o, $(basename $(SOURCES)))
LD_DEPS  := sym_ewram.txt sym_iwram.txt

# Secondary expansion is required for dependency variables in object rules.
.SECONDEXPANSION:
# Clear the default suffixes
.SUFFIXES:
# Don't delete intermediate files
.SECONDARY:
# Delete files that weren't built properly
.DELETE_ON_ERROR:

#### Main Targets ####

compare: $(ROM)
	md5sum -c checksum.md5

clean:
	$(RM) $(ROM) $(ELF) $(MAP) $(OFILES) src/*.s

#### Recipes ####

# Get rid of the idiotic built-in rules
.SUFFIXES:

# Stop deleting my files
.PRECIOUS: %.4bpp

# Link ELF file
$(ELF): $(OFILES) $(LDSCRIPT) $(LD_DEPS)
	$(LD) -T $(LDSCRIPT) -Map $(MAP) $(OFILES) -o $@

# Build GBA ROM
%.bin: %.elf
	$(OBJCOPY) -S -O binary --gap-fill 0x00 --pad-to 0x4000 $< $@

# C source code
src/%.o: src/%.c
	$(CPP) $(CPPFLAGS) $< | $(CC1) $(CC1FLAGS) -o src/$*.s
	$(AS) $(ASFLAGS) $*.s -o $@

# Assembly source code
asm/%.o: ASM_DEPS = $(shell tools/scaninc/scaninc asm/$*.s)
asm/%.o: asm/%.s $$(ASM_DEPS)
	$(AS) $(ASFLAGS) $< -o $@

# Graphics files
%.4bpp: %.png
	$(GBAGFX) $< $@
%.gbapal: %.pal
	$(GBAGFX) $< $@
%.lz: %
	$(GBAGFX) $< $@
%.huff: %
	$(GBAGFX) $< $@

%.inc: ;

include gfxdep.mk
