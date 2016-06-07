#ifndef BOOT1H
#define BOOT1H

#define SERIAL_DEBUG 0

#include "uuid.h"
#include "nvram.h"

#define NULL ((void*)0)

extern void uuid_to_ascii(uuid_t*, char[36]);
extern void devsetup();
extern int autoboot_prompt();
extern void transfer_stack_to_RAM();

extern void clear_screen();
/* must not end up longer than SCREEN_WIDTH-4 bytes! */
#define start_out_line() ((char*)(memory_bytes-4-ALIGN4(SCREEN_WIDTH)))
extern void put_out_line(char* endp);
extern void out_line(const char* p);
extern void setup_linebuf();
extern void boot();

extern uint32_t memory_bytes;
#define SCREEN_WIDTH 50
#define SCREEN_HEIGHT 16

#define have_ui() \
  ((nvram_flags & (NVRAM_FLAGS_BOOTGPU_VALID | NVRAM_FLAGS_BOOTSCREEN_VALID)) \
   == (NVRAM_FLAGS_BOOTGPU_VALID | NVRAM_FLAGS_BOOTSCREEN_VALID))

#if SERIAL_DEBUG
extern void dputs(const char* wat);
static inline void ddump() { asm volatile("CDP p7, #1, cr0, cr0, cr0, #0"); }
#else
#define dputs(wat) ((void)0)
#define ddump() ((void)0)
#endif

#define die(why) asm volatile("LDC p3, cr15, %0"::"m"(why))

#define flush_signals() \
  asm volatile("\n" \
               "1:\n\t" \
               "CDP p3, 6, cr0, cr0, cr0, #0\n\t" \
               "BVC 1b")

#define invoke(invoke_buf) \
  asm volatile("LDC p3, cr1, %0\n\t" \
               "CDP p3, 2, cr0, cr0, cr0, #1" \
               : /* no outputs */ \
               : "m"(invoke_buf)); \

#define ALIGN4(x) ((x)&3?(x)+(4-(x&3)):(x))

#endif
