#include "boot1.h"
#include "ccutil.h"
#include "interchange.h"

uint32_t memory_bytes;

static const int32_t get_keyboards_invoke_buf[] = {
  ICTAG_STRING(12), 'getK', 'eybo', 'ards',
  ICTAG_END
};
static int cc_is_valid_bootscreen(struct compact_component* cc_buf) {
  if(!cc_is_screen(cc_buf)) return 0;
  dputs("Checking bootscreen validity...");
  uint32_t reply_size;
  /* call screen->getKeyboards... but we don't need to store the reply, only
     find out its length
     set the length to 0 if an error occurred on the call */
  asm volatile("MCR p3, 0, %[cc_buf], cr1, cr1\n\t"
               "LDC p3, cr1, %[get_keyboards_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #0\n\t"
               "MRC p3, 0, %[reply_size], cr2, cr1\n\t"
               "MOVMI %[reply_size], #0"
               : [reply_size]"=r"(reply_size)
               : [cc_buf]"r"(cc_buf),
                 [get_keyboards_invoke_buf]"m"(get_keyboards_invoke_buf)
               : "cc");
  // Possible lengths:
  // zero length: N bit was set
  // ICTAG_INT, 0, ICTAG_END: No returned value
  // ICTAG_INT, 0, ICTAG_NULL, ICTAG_END: NULL reply
  // ICTAG_INT, 0, ICTAG_ARRAY, ICTAG_END, ICTAG_END: Empty list of keyboards
  // The shortest possible reply with at least one keyboard is longer than any
  // of the above. Therefore, checking the length is enough to know whether
  // there is an attached keyboard.
  return reply_size > 20;
}

static uint32_t fix_bcd_digits(uint32_t x) {
  /* for each BCD digit:
     add = x > 4 ? 3 : 0
     or, equivalently:
     add = ((x & 8) || ((x & 4) && (x & 3))) ? 3 : 0 */
  uint32_t add = ((x & 0x88888888U) >> 2)
    |(((x & 0x44444444U) >> 1) & ((x & 0x22222222U) | ((x & 0x11111111U)<<1)));
  add |= add >> 1;
  return x + add;
}
static uint32_t memory_bytes_to_bcd_kib(uint32_t memory_bytes) {
  memory_bytes = memory_bytes & ~1023;
  /* a 22-bit integer will dabble comfortably into 32-bit BCD, with 4 bits to
     spare */
  uint32_t bcd = 0;
  for(int n = 0; n < 22; ++n) {
    bcd = fix_bcd_digits(bcd);
    bcd = (bcd << 1) | (memory_bytes >> 31);
    memory_bytes = memory_bytes << 1;
  }
  return bcd;
}

static const int32_t turn_on_invoke_buf[] = {
  ICTAG_STRING(6), 'turn', 'On\0\0',
  ICTAG_END
};
/* Use black text on white background, like classy Open Firmware systems
   ... but use a fancy green/blue header for the bootloader because why not? */
static const int32_t banner_set_background_invoke_buf[] = {
  ICTAG_STRING(13), 'setB', 'ackg', 'roun', 'd\0\0\0',
  ICTAG_INT, 0x00FFFF,
  ICTAG_END
};
static const int32_t set_background_invoke_buf[] = {
  ICTAG_STRING(13), 'setB', 'ackg', 'roun', 'd\0\0\0',
  ICTAG_INT, 0xFFFFFF,
  ICTAG_END
};
static const int32_t set_foreground_invoke_buf[] = {
  ICTAG_STRING(13), 'setF', 'oreg', 'roun', 'd\0\0\0',
  ICTAG_INT, 0x000000,
  ICTAG_END
};
static const int32_t clear_banner_invoke_buf[] = {
  ICTAG_STRING(4), 'fill',
  ICTAG_INT, 1, ICTAG_INT, 1, ICTAG_INT, SCREEN_WIDTH, ICTAG_INT, 1,
  ICTAG_STRING(1), ' \0\0\0',
  ICTAG_END,
};
static const int32_t clear_ramline_invoke_buf[] = {
  ICTAG_STRING(4), 'fill',
  ICTAG_INT, 1, ICTAG_INT, SCREEN_HEIGHT, ICTAG_INT, SCREEN_WIDTH, ICTAG_INT,1,
  ICTAG_STRING(1), ' \0\0\0',
  ICTAG_END,
};
static const int32_t set_banner_invoke_buf[] = {
  ICTAG_STRING(3), 'set\0',
  ICTAG_INT, 14, ICTAG_INT, 1,
  ICTAG_STRING(24), 'OC A','RM B','oot ','Firm','ware',' 0.0',
  ICTAG_END
};
static const int32_t set_resolution_invoke_buf[] = {
  ICTAG_STRING(13), 'setR', 'esol', 'utio', 'n\0\0\0',
  ICTAG_INT, SCREEN_WIDTH, ICTAG_INT, SCREEN_HEIGHT,
  ICTAG_END
};
static int init_ui() {
  /* call screen->turnOn (assume success) */
  asm volatile("MCR p3, 0, %[nvram_bootscreen], cr1, cr1\n\t"
               "LDC p3, cr1, %[turn_on_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #1"
               : /* no outputs */
               : [nvram_bootscreen]"r"(&nvram_bootscreen),
               [turn_on_invoke_buf]"m"(turn_on_invoke_buf));
  /* next several invocations will be on the boot GPU, go ahead and set the
     Invoke Target Register */
  asm volatile("MCR p3, 0, %[nvram_bootgpu], cr1, cr1"
               : /* no outputs */
               : [nvram_bootgpu]"r"(&nvram_bootgpu));
  uint32_t invoke_buf[11];
  /* call gpu->bind on the screen (assume success) */
  invoke_buf[0] = ICTAG_STRING(4);
  invoke_buf[1] = 'bind';
  invoke_buf[2] = ICTAG_UUID;
  uuidcpy((uuid_t*)(invoke_buf+3), &nvram_bootscreen);
  invoke_buf[7] = ICTAG_END;
  invoke(invoke_buf);
  /* gpu->setResolution(w, h) (assume success) */
  invoke(set_resolution_invoke_buf);
  /* gpu->setForeground(foreground_color) (disregard failure) */
  invoke(set_foreground_invoke_buf);
  /* gpu->setBackground(banner_color) */
  invoke(banner_set_background_invoke_buf);
  /* gpu->fill(1, 1, w, 1, " ") (assume success) */
  invoke(clear_banner_invoke_buf);
  /* gpu->set(14, 1, "...banner...") */
  invoke(set_banner_invoke_buf);
  /* gpu->setBackground(background_color) (disregard failure) */
  invoke(set_background_invoke_buf);
  /* gpu->fill(1, h, w, 1, " ") (assume success) */
  invoke(clear_ramline_invoke_buf);
  /* write memory amount */
  /* str = ("%iK  \xc2\xa4"):format(memory_bytes)
     gpu->set(screen_width-2-#str, screen_height, str) */
  {
    invoke_buf[0] = ICTAG_STRING(3);
    invoke_buf[1] = 'set\0';
    invoke_buf[2] = ICTAG_INT;
    invoke_buf[4] = ICTAG_INT;
    invoke_buf[5] = SCREEN_HEIGHT;
    char* p = (char*)(invoke_buf+7);
    uint32_t kib = memory_bytes_to_bcd_kib(memory_bytes);
    /* the leftmost digit that can possibly be set in mbtbk's result */
    uint32_t shift = 24;
    /* find the most significant digit (or just do the ones digit) */
    while(shift > 0) if((kib >> shift) & 0xF) break; else shift -= 4;
    do {
      *p++ = '0' + ((kib >> shift) & 0xF);
      shift -= 4;
    } while(shift < 32); /* shift will overflow when we're done */
    *p++ = 'K';
    int strlen = p-(char*)(invoke_buf+7);
    invoke_buf[3] = SCREEN_WIDTH-strlen-2;
    invoke_buf[6] = ICTAG_STRING(strlen);
    if(strlen&3) p += 4-(strlen&3);
    *(int32_t*)p = ICTAG_END;
    invoke(invoke_buf);
  }
  /* our caller will call clear_screen */
  return 1;
}

const int32_t no_ram_invoke_buf[] = {
  ICTAG_STRING(3), 'set\0', ICTAG_INT, 1, ICTAG_INT, 2,
  ICTAG_STRING(39), 'No R','AM i','nsta','lled',', bo','otin','g is',' imp','ossi','ble\0',
  ICTAG_END
};
void devsetup() {
  dputs("Finding RAM amount...");
  memory_bytes = 0;
  for(int i = 1;; ++i) {
    uint32_t module_size;
    asm("MCR p3, 0, %[i], cr0, cr0\n\t"
        "MRC p3, 0, %[module_size], cr0, cr0"
        :[module_size]"=r"(module_size)
        :[i]"r"(i));
    if(module_size) memory_bytes += module_size;
    else break;
  }
  dputs("Checking NVRAM component validity...");
  /* stack space for Compact Component storage */
  struct compact_component cc_buf;
  /* latch Component Buffer */
  asm volatile("CDP p3, 5, cr0, cr0, cr0, #0");
  /* confirm validity of boot filesystem, screen, and GPU stored in NVRAM */
  if(nvram_flags & NVRAM_FLAGS_BOOTFS_VALID) {
    if(!foreach_cc(&cc_buf, cc_matches_bootfs))
      nvram_flags &= ~NVRAM_FLAGS_BOOTFS_VALID;
    else
      dputs("  Boot FS OK");
  }
  if(nvram_flags & NVRAM_FLAGS_BOOTSCREEN_VALID) {
    if(!foreach_cc(&cc_buf, cc_matches_bootscreen))
      nvram_flags &= ~NVRAM_FLAGS_BOOTSCREEN_VALID;
    else
      dputs("  Boot screen OK");
  }
  if(nvram_flags & NVRAM_FLAGS_BOOTGPU_VALID) {
    if(!foreach_cc(&cc_buf, cc_matches_bootgpu))
      nvram_flags &= ~NVRAM_FLAGS_BOOTGPU_VALID;
    else
      dputs("  Boot GPU OK");
  }
  /* if there was no screen or GPU selected, find one and use it */
  if(!(nvram_flags & NVRAM_FLAGS_BOOTSCREEN_VALID)) {
    dputs("Find screen with keyboard...");
    if(foreach_cc(&cc_buf, cc_is_valid_bootscreen)) {
      uuidcpy(&nvram_bootscreen, &cc_buf.address);
      nvram_flags |= NVRAM_FLAGS_BOOTSCREEN_VALID;
      dputs("  GOT ONE!");
    } else dputs("  Got none...");
  }
  if(!(nvram_flags & NVRAM_FLAGS_BOOTGPU_VALID)) {
    dputs("Find GPU...");
    if(foreach_cc(&cc_buf, cc_is_gpu)) {
      uuidcpy(&nvram_bootgpu, &cc_buf.address);
      nvram_flags |= NVRAM_FLAGS_BOOTGPU_VALID;
      dputs("  GOT ONE!");
    } else dputs("  Got none...");
  }
  if(have_ui()) {
    /* there is a screen (with keyboard) and a GPU; put them together */
    dputs("Initialize UI...");
    if(!init_ui()) {
      dputs("  Never mind...");
      /* couldn't actually initialize them, mark them as invalid */
      nvram_flags &= ~(NVRAM_FLAGS_BOOTSCREEN_VALID|NVRAM_FLAGS_BOOTGPU_VALID);
    } dputs("Did it!");
  }
  if(memory_bytes == 0) {
    /* error out */
    const char* msg = (const char*)(no_ram_invoke_buf+7);
    if(have_ui()) {
      clear_screen();
      asm volatile("LDC p3, cr1, %[no_ram_invoke_buf]\n\t"
                   "CDP p3, 2, cr0, cr0, cr0, #1"
                   : /* no outputs */
                   : [no_ram_invoke_buf]"m"(no_ram_invoke_buf));
    }
    die(msg);
    __builtin_unreachable();
  }
  transfer_stack_to_RAM();
}
