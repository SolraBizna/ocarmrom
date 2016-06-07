#include "boot1.h"

#if SERIAL_DEBUG
void dputs(const char* wat) {
  while(*wat)
    asm("MCR p7, #0, %0, cr0, cr0"::"r"(*wat++));
  asm("CDP p7, #0, cr0, cr0, cr0, #0");
}
#endif
