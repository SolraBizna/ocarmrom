#include "boot1.h"
#include "interchange.h"

#define BOOT_TIMEOUT 3

extern int key_was_pressed();

int autoboot_prompt() {
  int ret = 0;
  out_line("Automatic boot, press any key to override");
  /* Get the current world time */
  uint64_t worldTime, targetWorldTime;
  asm("MRRC p3, 0, %H0, %0, cr0":"=r"(worldTime):);
  targetWorldTime = worldTime;
  /* TEMPORARILY truncate interchange stores so we only get the part of the
     signal we care about */
  asm volatile("MCR p3, 0, %0, cr1, cr3"::"r"(3));
  /* ignore any signals from before we display the message */
  flush_signals();
  char buf[5] = "X...";
  for(int n = BOOT_TIMEOUT; n > 0; --n) {
    buf[0] = '0'+n;
    out_line(buf);
    targetWorldTime += 20;
    do {
      asm volatile("MCRR p3, 0, %H[target], %[target], cr0\n\t"
                   "MRRC p3, 0, %H[cur], %[cur], cr0"
                   :[cur]"=r"(worldTime)
                   :[target]"r"(targetWorldTime));
      if(key_was_pressed()) { ret = 1; goto owari; } /* double break */
    } while(worldTime < targetWorldTime);
  }
 owari:
  /* STOP truncating interchange stores */
  asm volatile("MCR p3, 0, %0, cr1, cr3"::"r"(0));
  /* clear the prompt */
  clear_screen();
  /* ignore any other accumulated signals */
  flush_signals();
  (void)key_was_pressed;
  return ret;
}
