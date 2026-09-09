CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer -noixemul
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000 -noixemul

BUILD_DIR := build
OUTPUT_OBJ := $(BUILD_DIR)/common/output.o
AREXX_OBJ := $(BUILD_DIR)/common/arexx.o
REXXPORTS_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/rexxports/main.o
REXXPROBE_OBJS := $(OUTPUT_OBJ) $(AREXX_OBJ) $(BUILD_DIR)/rexxprobe/main.o

.PHONY: all clean rexxports rexxprobe check-config

all: rexxports rexxprobe

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 2.04+"

rexxports: $(BUILD_DIR)/RexxPorts

rexxprobe: $(BUILD_DIR)/RexxProbe

$(BUILD_DIR)/RexxPorts: $(REXXPORTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(REXXPORTS_OBJS)

$(BUILD_DIR)/RexxProbe: $(REXXPROBE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(REXXPROBE_OBJS)

$(BUILD_DIR)/common/%.o: src/common/%.c include/abbstools/common.h include/abbstools/arexx.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/rexxports/%.o: src/tools/rexxports/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/rexxprobe/%.o: src/tools/rexxprobe/%.c include/abbstools/common.h include/abbstools/arexx.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
