#include "common.h"

.section .text.start, "ax", @progbits
.globl _start
_start:
  li sp, BOOT_MEM_END
  addi sp, sp, -8
  sw ra, 0(sp)
  call main
  lw ra, 0(sp)
  addi sp, sp, 8
  ret
_hang:
  wfi
  j _hang
