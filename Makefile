CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer -noixemul
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000 -noixemul

BUILD_DIR := build
COMMON_OBJS := $(BUILD_DIR)/common/output.o
REXXPORTS_OBJS := $(COMMON_OBJS) $(BUILD_DIR)/rexxports/main.o

.PHONY: all clean rexxports check-config

all: rexxports

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 2.04+"

rexxports: $(BUILD_DIR)/RexxPorts

$(BUILD_DIR)/RexxPorts: $(REXXPORTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(REXXPORTS_OBJS)

$(BUILD_DIR)/common/%.o: src/common/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/rexxports/%.o: src/tools/rexxports/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
