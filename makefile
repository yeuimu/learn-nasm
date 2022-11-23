# variable
AS = nasm
BIN_PATH = bin/
SRC_PATH = src/
BIN = $(patsubst %.asm,%.bin,$(subst src/,,$(wildcard $(SRC_PATH)*.asm)))

# file serch
vpath %.asm $(SRC_PATH)
vpath %.bin $(BIN_PATH)
#VPATH = src

all: $(BIN)

%.bin: %.asm
	$(AS) $< -o $(BIN_PATH)$@ -O0

.PHONY:clean debug

clean:
	-rm -rf bin/*.bin bx_enh_dbg.ini

debug:
	@echo $(patsubst %.asm,%.bin,$(subst src/,,$(wildcard $(SRC_PATH)*.asm)))

dd:
	@dd if=bin/bootloaderOne_v3.bin of=master.img bs=512 count=1 conv=notrunc
	@dd if=bin/user_test_v3.bin of=master.img bs=512 count=3 seek=1 conv=notrunc
