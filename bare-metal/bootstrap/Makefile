CROSS_COMPILE ?= ../../workspace/gcc/riscv/bin/riscv32-unknown-elf-
CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump

CFLAGS = -march=rv32imac -mabi=ilp32
CFLAGS += -Wall -std=gnu99 -MD
CFLAGS += -O2
CFLAGS += -mcmodel=medany -Wall
CFLAGS += -fno-pic -fno-common
CFLAGS += -Iinclude

LDFLAGS = -static -nostartfiles -T main.lds

BUILD_DIR = build

###############################################################################
## The bootstrap sources
###############################################################################
SRC_DIR = src
SRC_BOOTSTRAP = \
	$(SRC_DIR)/bootstrap.c \
	$(SRC_DIR)/kprintf.c

OBJ_BOOTSTRAP = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC_BOOTSTRAP))
###############################################################################


###############################################################################
## A utility that converts a binary file to a .COE file for filling a BRAM
###############################################################################
SRC_BIN2COE = $(SRC_DIR)/binary2coefficient.c
OBJ_BIN2COE = $(BUILD_DIR)/binary2coefficient.o
EXE_BIN2COE = $(BUILD_DIR)/binary2coefficient
###############################################################################


BOOTSTRAP  = bootstrap
TARGET_ELF = $(BUILD_DIR)/$(BOOTSTRAP).elf
TARGET_COE = $(BUILD_DIR)/$(BOOTSTRAP).coe
TARGET_TXT = $(BUILD_DIR)/$(BOOTSTRAP)-disassembly.txt
TARGET_DIR = ../../boot_device

.PHONY: default install clean bear


###############################################################################
## The targets
###############################################################################

# Do the build (default target)
default: $(BUILD_DIR) $(TARGET_ELF) $(TARGET_COE) $(TARGET_TXT)

# Link and create final binary
$(TARGET_ELF): $(OBJ_BOOTSTRAP)
	$(CC) -o $@ $^ $(LDFLAGS) $(SRC_DIR)/head.S -L$(BUILD_DIR)
	$(OBJDUMP) -h -p $@

# Create the disassembly file
$(TARGET_TXT): $(TARGET_ELF)
	$(OBJDUMP) -d -h -p $< > $@

# Create the COE file for use in Vivado
$(TARGET_COE): $(TARGET_ELF) $(EXE_BIN2COE)
	./$(EXE_BIN2COE) $< $@

# Copy the resulting .COE file to the boot_device directory
install: $(TARGET_COE)
	cp -p $< $(TARGET_DIR)

# Compile the benchmark's sources to object files
$(OBJ_BOOTSTRAP): $(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) -c $(CFLAGS) -o $@ $<
-include $(OBJ_BOOTSTRAP:.o=.d)


# Create build dir if not already present
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Clean the benchmark's specific object files and executable
# (Not touching the other benchmarks' files)
clean:
	@rm -f $(BUILD_DIR)/*

# Bear: create compile_commands.json for clangd running in the background
# (note: bear must be installed for this to work)
bear: clean
	bear -- make


###############################################################################
# Compile the utilities (for now just binary2coefficient)
###############################################################################
$(OBJ_BIN2COE): $(SRC_BIN2COE)
	gcc -c -Wall -O2  -o $@ $<

$(EXE_BIN2COE): $(OBJ_BIN2COE)
	gcc -o $@ $<
###############################################################################
