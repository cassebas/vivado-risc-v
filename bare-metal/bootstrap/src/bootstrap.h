#ifndef BOOTSTRAP_H
#define BOOTSTRAP_H


#include <stdint.h>
#include <stddef.h>

#define DEBUG 0

#define MAX_BUF 256

// The reset control register allows us to signal a CPU reset
#define RESET_CTRL_BASE         0x60040000

// The bootstrap application mmio region is reserved for configuration data
// concerning the benchmark application to be run.
#define BOOTSTRAP_BASE          0x60050000

// Bootstrap configuration bytes received from the host: each configuration
// parameter contains an unsigned integer of 4 bytes.
#define BOOTSTRAP_CONF_OFFSET   0x0000fc00
#define BOOTSTRAP_CONF_ADDR     (BOOTSTRAP_BASE + BOOTSTRAP_CONF_OFFSET)
#define BOOTSTRAP_CONF_BYTECNT  24
#define BOOTSTRAP_CONF_PARAMCNT 6
// Indices of the configuration parameters, using integer pointer arithmetic
#define APPLICATION_BOOTCNT     0
#define APPLICATION_BOOTCNT_MAX 1
#define APPLICATION_ELF_SIZE    2
#define INPUT_ARRAY_START       3
#define INPUT_ARRAY_END         4
#define INPUT_ARRAY_SIZE        5

// The benchmark application mmio region
#define APPLICATION_BASE        0x60080000

#define ASCII_ENQ 0x05 // From ASCII table: non-printable ENQuiry character
#define ASCII_ACK 0x06 // From ASCII table: non-printable ACKnowledge character

void print_hex(uintptr_t h, uint8_t n);
void usleep(unsigned us);

uint32_t get_word(uint8_t *buffer);

size_t read(uint8_t *buffer, size_t n);

#endif // BOOTSTRAP_H
