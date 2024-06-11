#include <stdint.h>
#include <stdlib.h>

#include "common.h"
#include "kprintf.h"

#define MAX_BUF 64

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
    // First check return address that bootrom gives us
    uintptr_t ret_addr=0;
    /* asm volatile("lw %0, 0(ra)" : "=r"(ret_addr)); */
    kprintf("Bootrom's return address is ");
    print_hex(ret_addr, 8);
    kprintf("\n");

    // Get the HART id of the running core
    uintptr_t mhartid;
    asm volatile("csrr %0, mhartid" : "=r"(mhartid));

    volatile uint32_t *led_register = (uint32_t *)0x60040000;
    uint8_t state = 0;
    *led_register = state;
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
