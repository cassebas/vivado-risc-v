#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "common.h"
#include "kprintf.h"
#include "bootstrap.h"


static void sleep_ms(unsigned ms);
static void sync_with_host(void);


int main(void)
{
  uint8_t buffer[MAX_BUF];
  uint32_t word_buffer[MAX_BUF/4];

  // Clear buffer
  memset(buffer, 0, sizeof(buffer));
  memset(word_buffer, 0, sizeof(word_buffer));

  volatile uint32_t *reset_ctrl_reg = (uint32_t *) RESET_CTRL_BASE;
  *reset_ctrl_reg = 0;

  kprintf("BOOTSTRAP: initiate first sync with host..");
  sync_with_host();
  kprintf(".sync OK.\n");

  kprintf("BOOTSTRAP: start receiving configuration from host.\n");
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

  // Write the received bytes to the MMIO memory
  volatile uint32_t *bootstrap_cfg_mmio = (uint32_t *) BOOTSTRAP_CONF_ADDR;
  memcpy(word_buffer, buffer, BOOTSTRAP_CONF_BYTECNT);
  for (int i=0; i<BOOTSTRAP_CONF_PARAMCNT; i++) {
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

  kprintf("BOOTSTRAP: initiate second sync with host..");
  sync_with_host();
  kprintf(".sync OK.\n");

  const size_t nbytes = bootstrap_cfg_mmio[APPLICATION_ELF_SIZE];
  kprintf("BOOTSTRAP: start receiving %d bytes of the ELF binary.\n", nbytes);

  volatile uint32_t *application_elf_mmio = (uint32_t *) APPLICATION_BASE;
  int total = 0, loop = 0, start, end;
  cnt = 0;
  while (total < nbytes) {
    if (kdata_ready()) {
      c = kgetc();
      buffer[cnt++] = (uint8_t) c;
      total++;
    }

    if (cnt == MAX_BUF) {
      // Reached buffer's capacity, write the data to the block ram
      memcpy(word_buffer, buffer, MAX_BUF);
      start = loop * MAX_BUF / 4;
      for (int i = 0; i < MAX_BUF/4; i++) {
        application_elf_mmio[start + i] = word_buffer[i];
      }
      loop++;
      cnt = 0;
    }
  }
  // We have received all characters, copy the rest to MMIO
  memcpy(word_buffer, buffer, cnt);
  start = loop * MAX_BUF / 4;
  for (int i = 0; i < cnt; i++) {
    application_elf_mmio[i+start] = word_buffer[i];
  }

  kprintf("BOOTSTRAP: received %d bytes, ", total);
  kprintf("which have been written to BlockRAM.\n");
  if (DEBUG) {
    end = start + cnt / 4;
    kprintf("BOOTSTRAP: loop = %d, start = %d.\n", loop, start);
    for (int i = 0; i < 32; i += 4) {
      print_hex(application_elf_mmio[i], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+1], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+2], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+3], 8);
      kprintf("\n");
    }
    kprintf("------------------------------\n");
    for (int i = start-32; i < end; i += 4) {
      print_hex(application_elf_mmio[i], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+1], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+2], 8);
      kprintf(" ");
      print_hex(application_elf_mmio[i+3], 8);
      kprintf("\n");
    }

  }

  kprintf("BOOTSTRAP: initiate final sync with host..");
  sync_with_host();
  kprintf(".sync OK.\n");

  // Wait a bit for the UART buffers to be flushed
  sleep_ms(200);

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

static void sleep_ms(unsigned ms)
{
  uintptr_t cycles0, cycles1;
  asm volatile ("csrr %0, 0xB00" : "=r" (cycles0));
  for (;;) {
    asm volatile ("csrr %0, 0xB00" : "=r" (cycles1));
    if (cycles1 - cycles0 >= ms * 100000) break;
  }
}

static void sync_with_host(void)
{
  const int TIMEOUT = 100;
  int checks= 0;
  char c;
  bool done = false;

  // Send the synchronization request to the host
  kputc(ASCII_ENQ);

  while (!done) {
    // Now try to receive the ACK
    while (!done && checks++ < TIMEOUT) {
      if (kdata_ready()) {
        if ((c = kgetc()) == ASCII_ACK) {
          done = true;
        }
      }
    }
    if (!done) {
      // Wait a bit before trying again
      sleep_ms(1);
      // And reset checks for the next try
      checks = 0;
    }
  }
}
