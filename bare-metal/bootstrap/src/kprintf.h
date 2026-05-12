#ifndef _BOOT_KPRINTF_H
#define _BOOT_KPRINTF_H

#include <stdbool.h>

extern bool kdata_ready(void);
extern char kgetc(void);
extern void kputc(char ch);
extern void kputs(const char *);
extern void kprintf(const char *, ...);

#endif /* _BOOT_KPRINTF_H */
