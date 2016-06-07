#include <stdarg.h>
#include <inttypes.h>

struct uuid {
  int a, b, c, d;
};
struct compact_component {
  struct uuid address;
  char name[16];
};

static struct uuid redstone_card;

static void find_redstone_card() {
  struct compact_component buf;
  // latch component list
  asm volatile("CDP p3, 5, cr0, cr0, cr0, #0"::);
  // find a redstone component
  for(uint32_t n = 0;; ++n) {
    // CCIR := n
    asm volatile("MCR p3, 0, %0, cr1, cr2"::"r"(n));
    // buf := Compact Component
    int skip, end;
    asm volatile("STC p3, c4, %0\n\t"
                 "MOVVS %1, #1\n\t"
                 "MOVVC %1, #0\n\t"
                 "MOVEQ %2, #1\n\t"
                 "MOVNE %2, #0":"=m"(buf),"=r"(skip),"=r"(end):);
    if(end) break;
    if(skip) continue;
    // is it "redstone"?
    if(((uint32_t*)buf.name)[0] == 'reds' &&
       ((uint32_t*)buf.name)[1] == 'tone' &&
       ((uint32_t*)buf.name)[2] == 0 &&
       ((uint32_t*)buf.name)[3] == 0) {
      redstone_card.a = buf.address.a;
      redstone_card.b = buf.address.b;
      redstone_card.c = buf.address.c;
      redstone_card.d = buf.address.d;
    }
  }
  // uh... let's just assume that worked
  asm volatile("MCR p3, 0, %0, cr1, cr1"::"r"(&redstone_card));
}

static uint32_t flick_on[] = {
  9, 'setO', 'utpu', 't\0\0\0',
  -5, 2, -5, 15, -1,
};
static uint32_t flick_off[] = {
  9, 'setO', 'utpu', 't\0\0\0',
  -5, 2, -5, 0, -1,
};

#define get_time(now) asm volatile("MRRC p3, 0, %H0, %0, cr0":"=r"(now):)
#define sleep_till(when) asm volatile("MCRR p3, 0, %H0, %0, cr0"::"r"(when))

static void flush_signals() {
  asm volatile("\n"
               "flush_signals_loop:\n\t"
               "CDP p3, 6, cr0, cr0, cr0, #0\n\t"
               "BVC flush_signals_loop"::);
}

static void time_loop() {
  long long then;
  get_time(then);
  while(1) {
    flush_signals();
    long long now;
    get_time(now);
    if(now < then) then = now;
    if(now > then + 20) then = now;
    asm volatile("LDC p3, cr1, %0\n\t"
                 "CDP p3, 2, cr0, cr0, cr0, #0"::"m"(flick_on));
    then += 10;
    sleep_till(then);
    asm volatile("LDC p3, cr1, %0\n\t"
                 "CDP p3, 2, cr0, cr0, cr0, #0"::"m"(flick_off));
    then += 10;
    sleep_till(then);
  }
}

int main(int argc, char* argv[]) {
  find_redstone_card();
  time_loop();
  return 0;
}
