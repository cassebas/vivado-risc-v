#include <stdint.h>
#include <stdlib.h>

#include "common.h"
#include "kprintf.h"

#define MAX_BUF 64

#define BOOT_MEM_PARAM_ADDR 0x200

/*
 * Print an integer in hexadecimal format.
 */
static void print_hex(uintptr_t h, uint8_t n) {
    // Maxixum digits to print is MAX_BUF-1 digits + \0
    char buf[MAX_BUF];
    buf[n] = '\0';
    char c;
    while (n--) {
        c = (char) (h & 0x0F);
        if (c < 10) {
            c = c + '0';
        } else {
            c = c + 'A' - 10;
        }
        buf[n] = c;
        h >>= 4;
    }
    kprintf("%s", buf);
}

static void usleep(unsigned us) {
    uintptr_t cycles0;
    uintptr_t cycles1;
    asm volatile ("csrr %0, 0xB00" : "=r" (cycles0));
    for (;;) {
        asm volatile ("csrr %0, 0xB00" : "=r" (cycles1));
        if (cycles1 - cycles0 >= us * 100) break;
    }
}

int main(void) {
    // Get the HART id of the running core
    uintptr_t mhartid;
    asm volatile("csrr %0, mhartid" : "=r"(mhartid));

    // The led register holds a simple state machine that has three
    // states, idle (no LEDs blinking), blinking (all LEDs blinking) and
    // counting (LEDs are counting in binary).
    volatile uint32_t *led_register = (uint32_t *)0x60040000;
    uint8_t state = 0;
    *led_register = state;

    // Test the block ram memory on the FPGA
    volatile uint32_t *boot_memory = (uint32_t *)0x60050000;
    kprintf("boot_memory[BOOT_MEM_PARAM_ADDR] == 0x");
    print_hex(boot_memory[BOOT_MEM_PARAM_ADDR], 8);
    kprintf("\n");

    // The 'constant' boot_num (changed by the program on each run),
    // tells us how many times we have booted. It is a constant present
    // in the binary boot.elf, but since we have the binary in the block
    // ram, we can alter its contents.
    volatile uint32_t boot_num = boot_memory[BOOT_MEM_PARAM_ADDR];
    kprintf("Bootnum is %d\n", boot_num);
    // Put the new 'constant' in the block ram where the boot.elf binary resides
    boot_num++;
    boot_memory[BOOT_MEM_PARAM_ADDR] = boot_num;

    char c;
    kprintf("Start of helloworld\n");
    kprintf("Press a random character to change state. ");
    kprintf("Press '/' to end program.\n");
    while ( (c = kgetc()) != '/' ) {
        if (++state == 3)
            state = 0;
        *led_register = state;
        kprintf("Hello World from core=%d!\n", mhartid);
        kprintf("Got character %c from UART. ", c);
        kprintf("State is now %d\n", state);
    }
    kprintf("Got character %c from UART, so stopping now.\n", c);
    kprintf("End of helloworld\n");

    usleep(1000000);
    *led_register = 0xffffffff;

    return 0;
}
