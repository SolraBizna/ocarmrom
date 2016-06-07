#ifndef NVRAMH
#define NVRAMH

#include "uuid.h"

#define NVRAM_VERSION_MASK 0xFF
#define NVRAM_VERSION_CURRENT 0x01
#define NVRAM_FLAGS_BOOTFS_VALID 0x100
#define NVRAM_FLAGS_BOOTSCREEN_VALID 0x200
#define NVRAM_FLAGS_BOOTGPU_VALID 0x400
extern uint32_t nvram_flags __attribute__((section(".nvram")));
extern uint32_t nvram_check __attribute__((section(".nvram")));
extern uuid_t nvram_bootfs __attribute__((section(".nvram")));
extern uuid_t nvram_bootscreen __attribute__((section(".nvram")));
extern uuid_t nvram_bootgpu __attribute__((section(".nvram")));

void init_nvram();
void save_nvram();

#endif
