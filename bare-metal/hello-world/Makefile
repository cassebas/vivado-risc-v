CROSS_COMPILE = ../../workspace/gcc/riscv/bin/riscv32-unknown-elf-

CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump

CFLAGS = -march=rv32imac -mabi=ilp32

CCFLAGS = $(CFLAGS)
CCFLAGS += -mcmodel=medany -O2 -Wall -g
CCFLAGS += -fno-pic -fno-common -g -I.

LFLAGS = -static -nostartfiles -T main.lds

all: boot.elf

boot.elf: head.S kprintf.c main.c
	make -C ../.. workspace/gcc/riscv
	$(CC) $(CCFLAGS) $(LFLAGS) -o $@ head.S kprintf.c main.c
	$(OBJDUMP) -h -p $@

clean:
	rm -f *.elf
