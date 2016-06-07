#include "nvram.h"
#include "uuid.h"
#include "boot1.h"
#include "ccutil.h"
#include "interchange.h"

struct compact_component* bootdev_p;
struct compact_component* bootdev_end;
static int32_t boot_elf_exists_invoke_bufs[2][8] = {
  {
    ICTAG_STRING(6), 'exis', 'ts\0\0',
    ICTAG_STRING(12), 'boot', '/arm', '.elf',
    ICTAG_END
  },
  {
    ICTAG_STRING(6), 'exis', 'ts\0\0',
    ICTAG_STRING(11), 'armb', 'oot.', 'elf\0',
    ICTAG_END
  }
};
static int is_bootfs(struct compact_component* cc) {
  int32_t reply_buf[4];
  int32_t reply_size;
  for(int n = 0; n < 2; ++n) {
    invoke(boot_elf_exists_invoke_bufs[n]);
    /* read reply buffer size register; success gives 16 bytes */
    asm volatile("MRC p3, 0, %[reply_size], cr2, cr1"
                 : [reply_size]"=r"(reply_size));
    if(reply_size != 16) return 0;
    asm volatile("STC p3, cr1, %[reply_buf]"
                 : [reply_buf]"=m"(reply_buf)
                 : /* no inputs */
                 : "cc", "memory");
    if(reply_buf[0] != INVOKE_SUCCESS || reply_buf[1] != ICTAG_BOOLEAN
       || reply_buf[3] != ICTAG_END) return 0;
    if(reply_buf[2]) return 1;
  }
  return 0;
}
static int count_bootfs(struct compact_component* cc) {
  if(!cc_is_fs(cc)) return 0;
  /* set filesystem as invoke target */
  asm volatile("MCR p3, 0, %[fs], cr1, cr1"
               ::[fs]"r"(&cc->address));
  if(!is_bootfs(cc)) return 0;
  *bootdev_p++ = *cc;
  return bootdev_p >= bootdev_end;
}
void post_ramstack() {
  setup_linebuf();
  clear_screen();
  /* latch component list again in case it changed */
  asm("CDP p3, 5, cr0, cr0, cr0, #0");
  struct compact_component bootdevs[10];
  bootdev_p = bootdevs;
  bootdev_end = bootdevs + sizeof(bootdevs)/sizeof(*bootdevs);
  { struct compact_component cc_buf; foreach_cc(&cc_buf, count_bootfs); }
  int count = bootdev_p-bootdevs;
  if(count == 0) {
    out_line("No bootable medium found.");
    out_line("");
    out_line("Attach a filesystem containing one of the");
    out_line("following files:");
    out_line("");
    out_line("/armboot.elf");
    out_line("/boot/arm.elf");
    die("No bootable medium found.");
    __builtin_unreachable();
  }
  else if(count == 1) {
    uuidcpy(&nvram_bootfs, &bootdevs[0].address);
    goto _;
    __builtin_unreachable();
  }
  else if((nvram_flags & NVRAM_FLAGS_BOOTFS_VALID) && autoboot_prompt()) {
    goto _;
    __builtin_unreachable();
  }
  else {
    if(count > 9)
      out_line("Warning: more than 9 bootable media!");
    out_line("Select one of the following to boot from:");
    for(int n = 0; n < count; ++n) {
      char buf[40];
      buf[0] = '1' + n;
      buf[1] = '.';
      buf[2] = ' ';
      uuid_to_ascii(&bootdevs[n].address, buf + 3);
      buf[39] = 0;
      out_line(buf);
    }
  _: goto _;
  }
  __builtin_unreachable();
}

void rom_main() {
  init_nvram();
  devsetup();
  __builtin_unreachable();
}
