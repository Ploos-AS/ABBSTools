CC ?= m68k-amigaos-gcc
CFLAGS ?= -O2 -Wall -Wextra -m68000 -fomit-frame-pointer -noixemul
CPPFLAGS ?= -Iinclude
LDFLAGS ?= -m68000 -noixemul

BUILD_DIR := build
OUTPUT_OBJ := $(BUILD_DIR)/common/output.o
AREXX_OBJ := $(BUILD_DIR)/common/arexx.o
ABBS_OBJ := $(BUILD_DIR)/common/abbs.o
ABBS_USER_OBJ := $(BUILD_DIR)/common/abbs_user.o
ABBS_CONF_OBJ := $(BUILD_DIR)/common/abbs_conf.o
REXXPORTS_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/rexxports/main.o
REXXPROBE_OBJS := $(OUTPUT_OBJ) $(AREXX_OBJ) $(BUILD_DIR)/rexxprobe/main.o
NODEINFO_OBJS := $(OUTPUT_OBJ) $(ABBS_OBJ) $(BUILD_DIR)/nodeinfo/main.o
NODEWATCH_OBJS := $(OUTPUT_OBJ) $(ABBS_OBJ) $(BUILD_DIR)/nodewatch/main.o
NODECHECK_OBJS := $(OUTPUT_OBJ) $(ABBS_OBJ) $(BUILD_DIR)/nodecheck/main.o
ASSIGNCHECK_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/assigncheck/main.o
BBSDOCTOR_OBJS := $(OUTPUT_OBJ) $(ABBS_OBJ) $(BUILD_DIR)/bbsdoctor/main.o
LASTCALLS_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/lastcalls/main.o
LOGINFO_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/loginfo/main.o
USERINFO_OBJS := $(OUTPUT_OBJ) $(ABBS_USER_OBJ) $(BUILD_DIR)/userinfo/main.o
CONFINFO_OBJS := $(OUTPUT_OBJ) $(ABBS_CONF_OBJ) $(BUILD_DIR)/confinfo/main.o
DOORINFO_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/doorinfo/main.o
DOORCHECK_OBJS := $(OUTPUT_OBJ) $(BUILD_DIR)/doorcheck/main.o

.PHONY: all clean rexxports rexxprobe nodeinfo nodewatch nodecheck assigncheck bbsdoctor lastcalls loginfo userinfo confinfo doorinfo doorcheck check-config

all: rexxports rexxprobe nodeinfo nodewatch nodecheck assigncheck bbsdoctor lastcalls loginfo userinfo confinfo doorinfo doorcheck

check-config:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "Target baseline: Motorola 68000 / AmigaOS 2.04+"

rexxports: $(BUILD_DIR)/RexxPorts
rexxprobe: $(BUILD_DIR)/RexxProbe
nodeinfo: $(BUILD_DIR)/NodeInfo
nodewatch: $(BUILD_DIR)/NodeWatch
nodecheck: $(BUILD_DIR)/NodeCheck
assigncheck: $(BUILD_DIR)/AssignCheck
bbsdoctor: $(BUILD_DIR)/BBSDoctor
lastcalls: $(BUILD_DIR)/LastCalls
loginfo: $(BUILD_DIR)/LogInfo
userinfo: $(BUILD_DIR)/UserInfo
confinfo: $(BUILD_DIR)/ConfInfo
doorinfo: $(BUILD_DIR)/DoorInfo
doorcheck: $(BUILD_DIR)/DoorCheck

$(BUILD_DIR)/RexxPorts: $(REXXPORTS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(REXXPORTS_OBJS)
$(BUILD_DIR)/RexxProbe: $(REXXPROBE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(REXXPROBE_OBJS)
$(BUILD_DIR)/NodeInfo: $(NODEINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(NODEINFO_OBJS)
$(BUILD_DIR)/NodeWatch: $(NODEWATCH_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(NODEWATCH_OBJS)
$(BUILD_DIR)/NodeCheck: $(NODECHECK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(NODECHECK_OBJS)
$(BUILD_DIR)/AssignCheck: $(ASSIGNCHECK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(ASSIGNCHECK_OBJS)
$(BUILD_DIR)/BBSDoctor: $(BBSDOCTOR_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(BBSDOCTOR_OBJS)
$(BUILD_DIR)/LastCalls: $(LASTCALLS_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(LASTCALLS_OBJS)
$(BUILD_DIR)/LogInfo: $(LOGINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(LOGINFO_OBJS)
$(BUILD_DIR)/UserInfo: $(USERINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(USERINFO_OBJS)
$(BUILD_DIR)/ConfInfo: $(CONFINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(CONFINFO_OBJS)
$(BUILD_DIR)/DoorInfo: $(DOORINFO_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(DOORINFO_OBJS)
$(BUILD_DIR)/DoorCheck: $(DOORCHECK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(DOORCHECK_OBJS)

$(BUILD_DIR)/common/%.o: src/common/%.c include/abbstools/common.h include/abbstools/arexx.h include/abbstools/abbs.h include/abbstools/abbs_user.h include/abbstools/abbs_conf.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/rexxports/%.o: src/tools/rexxports/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/rexxprobe/%.o: src/tools/rexxprobe/%.c include/abbstools/common.h include/abbstools/arexx.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/nodeinfo/%.o: src/tools/nodeinfo/%.c include/abbstools/common.h include/abbstools/abbs.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/nodewatch/%.o: src/tools/nodewatch/%.c include/abbstools/common.h include/abbstools/abbs.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/nodecheck/%.o: src/tools/nodecheck/%.c include/abbstools/common.h include/abbstools/abbs.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/assigncheck/%.o: src/tools/assigncheck/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/bbsdoctor/%.o: src/tools/bbsdoctor/%.c include/abbstools/common.h include/abbstools/abbs.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/lastcalls/%.o: src/tools/lastcalls/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/loginfo/%.o: src/tools/loginfo/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/userinfo/%.o: src/tools/userinfo/%.c include/abbstools/common.h include/abbstools/abbs_user.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/confinfo/%.o: src/tools/confinfo/%.c include/abbstools/common.h include/abbstools/abbs_conf.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/doorinfo/%.o: src/tools/doorinfo/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
$(BUILD_DIR)/doorcheck/%.o: src/tools/doorcheck/%.c include/abbstools/common.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
