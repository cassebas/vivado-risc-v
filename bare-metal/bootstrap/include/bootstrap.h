#ifndef BOOTSTRAP_H
#define BOOTSTRAP_H


#include <stdint.h>
#include <stddef.h>

#define DEBUG 0

#define MAX_BUF 1024

#define WORD_SIZE 4

// The reset control register allows us to signal a CPU reset
#define RESET_CTRL_BASE         0x60040000

// The bootstrap application mmio region is reserved for configuration data
// concerning the benchmark application to be run.
#define BOOTSTRAP_BASE          0x60050000

// Bootstrap configuration bytes received from the host: each configuration
// parameter contains an unsigned integer of 4 bytes. The first 8 bytes are
// managed by the bootrom.
#define BOOTSTRAP_CONF_OFFSET   0x0000fc00
#define BOOTSTRAP_CONF_ADDR     (BOOTSTRAP_BASE + BOOTSTRAP_CONF_OFFSET)
#define BOOTSTRAP_CONF_BYTECNT  32
#define BOOTSTRAP_CONF_PARAMCNT 8
#define BOOTSTRAP_CONF_STARTIDX 1    // smaller indices are managed by bootrom
// Indices of the configuration parameters, using integer pointer arithmetic
#define APPLICATION_BOOTCNT     0    // offset 0x0000fc00 - managed by bootrom
#define APPLICATION_BOOTCNT_MAX 1    // offset 0x0000fc04 - set by bootstrap
#define APPLICATION_ELF_SIZE    2    // offset 0x0000fc08 - set by bootstrap
#define EXPERIMENT_NR           3    // offset 0x0000fc0c - set by bootstrap
#define EXPERIMENT_NR_MAX       4    // offset 0x0000fc10 - set by bootstrap
#define INPUT_ARRAY_START       5    // offset 0x0000fc14 - set by bootstrap
#define INPUT_ARRAY_END         6    // offset 0x0000fc18 - set by bootstrap
#define INPUT_ARRAY_SIZE        7    // offset 0x0000fc1c - set by bootstrap

// The benchmark application mmio region
#define APPLICATION_BASE        0x60080000


#define ASCII_SOH 0x01 // From ASCII table: non-printable Start Of Header (SOH)
#define ASCII_SOT 0x02 // From ASCII table: non-printable Start Of Text (SOT)
#define ASCII_ETX 0x03 // From ASCII table: non-printable End Of Text   (ETX)
#define ASCII_EOT 0x04 // From ASCII table: non-printable End Of Transmission (EOT)
#define ASCII_ENQ 0x05 // From ASCII table: non-printable ENQuiry
#define ASCII_ACK 0x06 // From ASCII table: non-printable ACKnowledge
#define ASCII_BEL 0x07 // From ASCII table: non-printable Bell (BEL)
#define ASCII_BS  0x08 // From ASCII table: non-printable Backspace (BS)


extern char magic_token[];


void print_hex(uintptr_t h, uint8_t n);
uint32_t get_word(uint8_t *buffer);
size_t read(uint8_t *buffer, size_t n);


#endif // BOOTSTRAP_H
