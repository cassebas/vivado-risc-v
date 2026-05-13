#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include "common.h"
#include "kprintf.h"
#include "bootstrap.h"



int main(void)
{
  uint8_t buffer[MAX_BUF];
  // Clear buffer
  memset(&buffer, 0, sizeof(buffer));

  volatile uint32_t *reset_ctrl_reg = (uint32_t *) RESET_CTRL_BASE;
  *reset_ctrl_reg = 0;

  kprintf("BOOTSTRAP: start receiving configuration from host.\n");
  kputc(ASCII_ENQ);

  // Configuration bytes
  // The write function on the host will send the most significant byte first,
  // since it runs a little endian system.
  int cnt = 0;
  char c = 0;
  while (cnt < BOOTSTRAP_CONF_BYTECNT) {
    if (kdata_ready()) {
      c = kgetc();
      buffer[cnt++] = (uint8_t) c;
    }
  }
  volatile uint32_t *bootstrap_cfg_mmio = (uint32_t *) BOOTSTRAP_CONF_ADDR;

  // Write the received bytes to the MMIO memory
  uint32_t *word_buffer = (uint32_t *) buffer;
  for (int i = 0; i < BOOTSTRAP_CONF_PARAMCNT; i++) {
    bootstrap_cfg_mmio[i] = word_buffer[i];
  }

  // Print the received parameters to stdout
  kprintf("BOOTSTRAP: application boot counter = 0x");
  print_hex(bootstrap_cfg_mmio[APPLICATION_BOOTCNT], 8);
  kprintf("\nBOOTSTRAP: application boot counter max = 0x");
  print_hex(bootstrap_cfg_mmio[APPLICATION_BOOTCNT_MAX], 8);
  kprintf("\nBOOTSTRAP: application elf size = 0x");
  print_hex(bootstrap_cfg_mmio[APPLICATION_ELF_SIZE], 8);
  kprintf("\nBOOTSTRAP: input array start = 0x");
  print_hex(bootstrap_cfg_mmio[INPUT_ARRAY_START], 8);
  kprintf("\nBOOTSTRAP: input array end = 0x");
  print_hex(bootstrap_cfg_mmio[INPUT_ARRAY_END], 8);
  kprintf("\nBOOTSTRAP: input array size = 0x");
  print_hex(bootstrap_cfg_mmio[INPUT_ARRAY_SIZE], 8);
  kprintf("\n");

  // Send another ENQuiry character to request the bytes from the ELF file
  kputc(ASCII_ENQ);

  volatile uint32_t *application_elf_mmio = (uint32_t *) APPLICATION_BASE;
  int total = 0;
  cnt = 0;
  while (total < bootstrap_cfg_mmio[APPLICATION_ELF_SIZE]) {
    if (kdata_ready()) {
      c = kgetc();
      buffer[cnt++] = (uint8_t) c;
      total++;
    }
    if (cnt == MAX_BUF) {
      // Reached buffer's capacity, write the data to the block ram
      for (int i = 0; i < MAX_BUF/4; i++) {
        application_elf_mmio[i] = word_buffer[i];
      }
      cnt = 0;
    }
  }
  // We have received all characters, copy the rest to MMIO
  for (int i = (total-cnt)/4; i < total/4; i++) {
    application_elf_mmio[i] = word_buffer[i];
  }
  // Assume a multiple of 4 bytes, so we don't expect any residue bytes


  kprintf("BOOTSTRAP: received %d bytes for the ELF binary, ", total);
  kprintf("which have been written to the BlockRAM.\n");
  kprintf("BOOTSTRAP: performing reset.\n");
  // Send ACKnowledge character to signal that bootstrap has finished
  kputc(ASCII_ACK);

  // Wait a bit for the UART buffers to be flushed
  usleep(100000);

  // Perform the reset, repeatedly in a while loop to make sure
  // the reset will eventually happen
  while (1) {
    // Set the reset control register to all ones, signalling CPU reset.
    kprintf(".");
    *reset_ctrl_reg = 0xffffffff;

    // Wait a bit before trying again
    usleep(100000);
  }

  return 0;
}

/*
 * Print an integer in hexadecimal format.
 */
void print_hex(uintptr_t h, uint8_t n)
{
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

void usleep(unsigned us)
{
    uintptr_t cycles0;
    uintptr_t cycles1;
    asm volatile ("csrr %0, 0xB00" : "=r" (cycles0));
    for (;;) {
        asm volatile ("csrr %0, 0xB00" : "=r" (cycles1));
        if (cycles1 - cycles0 >= us * 100) break;
    }
}


uint32_t get_word(uint8_t *buffer)
{
  uint32_t word = 0;

  if (buffer != NULL) {
    word = (uint32_t) buffer[0];
    word <<= 8;
    word |= (uint32_t) buffer[1];
    word <<= 8;
    word |= (uint32_t) buffer[2];
    word <<= 8;
    word |= (uint32_t) buffer[3];
  }

  return word;
}
