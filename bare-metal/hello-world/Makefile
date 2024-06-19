CROSS_COMPILE = ../../workspace/gcc/riscv/bin/riscv32-unknown-elf-

CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump

CFLAGS = -march=rv32imac -mabi=ilp32

CCFLAGS = $(CFLAGS)
CCFLAGS += -mcmodel=medany -O2 -Wall -g
CCFLAGS += -fno-pic -fno-common -g -I.

LFLAGS = -static -nostartfiles -T main.lds

BIN2COE_SRC = binary2coefficient.c
BIN2COE_BIN = binary2coefficient

TARGET     = boot
TARGET_ELF = $(TARGET).elf
TARGET_COE = $(TARGET).coe

all: $(TARGET_COE)

$(TARGET_COE): $(TARGET_ELF) $(BIN2COE_BIN)
	./$(BIN2COE_BIN) $< $@

$(BIN2COE_BIN):
	gcc -o $@ $(BIN2COE_SRC)

$(TARGET_ELF): head.S kprintf.c main.c
	make -C ../.. workspace/gcc/riscv
	$(CC) $(CCFLAGS) $(LFLAGS) -o $@ head.S kprintf.c main.c
	$(OBJDUMP) -h -p $@

clean:
	rm -f $(BIN2COE_BIN) $(TARGET_ELF) $(TARGET_COE)
