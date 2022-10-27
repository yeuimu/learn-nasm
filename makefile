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


.PHONY:clean syn

clean:
	-rm -rf *.bin bx_enh_dbg.ini

syn:
	-rm -rf /home/yoyoki/Documents/Obsidian\ Vault/CS/OperatingSystem/x86_nasm_md/x86Asm_FromRealModeToProtectMode.md
	-rm -rf /home/yoyoki/Documents/Obsidian\ Vault/CS/OperatingSystem/x86_nasm_md/pic/*
	-cp ./doc/x86Asm_FromRealModeToProtectMode.md /home/yoyoki/Documents/Obsidian\ Vault/CS/OperatingSystem/x86_nasm_md/
	-cp ./doc/pic/* /home/yoyoki/Documents/Obsidian\ Vault/CS/OperatingSystem/x86_nasm_md/pic/
