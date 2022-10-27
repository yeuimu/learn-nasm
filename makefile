# variable
AS = nasm
BIN_PATH = bin/
SRC_PATH = src/
BIN = $(patsubst %.asm,%.bin,$(subst src/,,$(wildcard $(SRC_PATH)*.asm)))

# file serch
vpath %.asm $(SRC_PATH)
#VPATH = src

all: $(BIN)

%.bin: %.asm
	$(AS) $< -o $@


.PHONY:clean

clean:
	-rm -rf *.bin bx_enh_dbg.ini
