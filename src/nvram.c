#include "nvram.h"

void init_nvram() {
  if(nvram_check != -nvram_flags)
    nvram_flags = NVRAM_VERSION_CURRENT;
}

void save_nvram() {
  nvram_check = -nvram_flags;
  asm volatile("CDP p3, 4, cr0, cr0, cr0, #0"); // flush nvram
}
