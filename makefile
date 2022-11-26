# variable
AS = nasm
BIN_PATH = bin/
SRC_PATH = src/*
SRC_DIR = $(wildcard $(SRC_PATH)*)

OBJS = $(foreach dir, $(SRC_DIR), $(wildcard $(dir)/*.asm))
TARGET = $(patsubst %.asm, %.bin, $(notdir $(OBJS)))

# file serch
vpath %.asm $(SRC_DIR)
vpath %.bin $(BIN_PATH)
#VPATH = src

all: $(TARGET)

%.bin: %.asm
	$(AS) $< -o $(BIN_PATH)$@

.PHONY:clean debug

clean:
	-rm -rf bin/*.bin bx_enh_dbg.ini

debug:
	@echo $(TARGET)
