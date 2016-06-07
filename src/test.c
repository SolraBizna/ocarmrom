#include <stdarg.h>
#include <inttypes.h>

struct uuid {
  int a, b, c, d;
};
struct compact_component {
  struct uuid address;
  char name[16];
};

static void putchar(uint32_t codepoint) {
  if(codepoint == '\n')
    asm volatile("CDP p7, 0, cr0, cr0, cr0, #0" ::);
  else
    asm volatile("MCR p7, 0, %0, cr0, cr0" :: "r"(codepoint));
}
static void put_string(const char* str) { while(*str) putchar(*str++); }
static void put_lstring(const char* str, uint32_t l) { while(l--) putchar(*str++); }
static void put_int(int i) {
  /* slow but simple */
  /* we're not cool enough to use double dabble yet */
  char buf[11];
  buf[10] = 0;
  char* bufp = buf + 10;
  do {
    *--bufp = '0' + (i % 10);
    i /= 10;
  } while(i != 0);
  put_string(bufp);
}
static unsigned long long fix_bcd_digits(unsigned long long x) {
  /* for each BCD digit:
     add = x > 4 ? 3 : 0
     or, equivalently:
     add = ((x & 8) || ((x & 4) && (x & 3))) ? 3 : 0 */
  unsigned long long add =
    ((x & 0x8888888888888888ULL) >> 2)
    | (((x & 0x4444444444444444ULL) >> 1) &
       ((x & 0x2222222222222222ULL) | ((x & 0x1111111111111111ULL) << 1)));
  add |= add >> 1;
  return x + add;
}
static void put_longlong(long long i) {
  /* we have no choice but to use double dabble now */
  unsigned long long rl2 = 0, rl1 = 0, rl0;
  if(i < 0) { putchar('-'); rl0 = -i; }
  else rl0 = i;
  for(int n = 0; n < 64; ++n) {
    rl2 = fix_bcd_digits(rl2);
    rl1 = fix_bcd_digits(rl1);
    rl2 = (rl2 << 1) | (rl1 >> 63);
    rl1 = (rl1 << 1) | (rl0 >> 63);
    rl0 = rl0 << 1;
  }
  for(int n = 3; n >= 0; --n) {
    int digit = ((int)(rl2 >> (n*4)))&15;
    putchar('0'+digit);
  }
  for(int n = 15; n >= 0; --n) {
    int digit = ((int)(rl1 >> (n*4)))&15;
    putchar('0'+digit);
  }
}
static const char hexdigits[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
static void put_hexint(unsigned int i) {
  char buf[9];
  buf[8] = 0;
  char* bufp = buf + 8;
  for(int n = 0; n < 8; ++n) {
    *--bufp = hexdigits[i&15];
    i >>= 4;
  }
  put_string(bufp);
}
static void put_hexlonglong(unsigned long long i) {
  char buf[17];
  buf[16] = 0;
  char* bufp = buf + 16;
  for(int n = 0; n < 16; ++n) {
    *--bufp = hexdigits[i&15];
    i >>= 4;
  }
  put_string(bufp);
}
static int printf(const char* format, ...) __attribute__((format(printf,1,2)));
static int printf(const char* format, ...) {
  int ret = 0;
  va_list arg;
  va_start(arg, format);
  while(*format) {
    switch(*format) {
    case '%':
      ++format;
      switch(*format) {
      case '%':
        putchar('%');
        break;
      case 'i':
      case 'd':
        put_int(va_arg(arg, int));
        break;
      case 'l':
        if(*++format == 'l') {
          switch(*++format) {
          case 'i':
            put_longlong(va_arg(arg, long long));
            break;
          case 'X':
          case 'x':
            put_hexlonglong(va_arg(arg, unsigned long long));
            break;
          default:
            format -= 2;
          }
        } else --format;
        break;
      case 'p':
      case 'X':
      case 'x':
        put_hexint(va_arg(arg, unsigned int));
        break;
      case 's':
        put_string(va_arg(arg, const char*));
        break;
      default:
        put_string("<unknown format char ");
        putchar(*format);
        putchar('>');
      }
      ++format;
      break;
    default:
      putchar(*format++);
    }
  }
  va_end(arg);
  return ret;
}

static uint8_t big_buffer[1024];
void dump_component_list() {
  asm volatile("CDP p3, 5, cr0, cr0, cr0, #0\n\t"
               "STC p3, c3, %0":"=m"(big_buffer):);
  uint8_t* p = big_buffer;
  do {
    int32_t tag = *(int32_t*)p;
    if(tag == -1) break;
    if(tag != -8) {
      put_string("Wasn't an ICTAG_UUID, we'll stop now\n");
      printf("%X\n", tag);
      break;
    }
    tag = ((int32_t*)p)[5];
    if(tag < 0 || tag >= 16384) {
      put_string("Wasn't an ICTAG_STRING, we'll stop now\n");
      printf("%X\n", tag);
      break;
    }
    printf("%X%X%X%X ", ((int32_t*)p)[1], ((int32_t*)p)[2],
           ((int32_t*)p)[3], ((int32_t*)p)[4]);
    put_lstring((const char*)(p+24), tag);
    putchar('\n');
    p = p + 24 + tag;
    if(tag&3) p += 4-(tag&3);
  } while(1);
}

int main(int argc, char* argv[]) {
  put_string("Testing...!\n");
  int cpu_speed;
  asm("MRC p3, 0, %0, cr0, cr2":"=r"(cpu_speed):);
  printf("CPU is %iKHz\n", cpu_speed / 50);
  long long clock;
  asm volatile("MRRC p3, 0, %0, %H0, cr0":"=r"(clock):);
  printf("Current time is %lli / %llX\n", clock, clock);
  int sram_size;
  asm("MCR p3, 0, %1, cr0, cr0\n\t"
          "MRC p3, 0, %0, cr0, cr0":"=r"(sram_size):"r"(0));
  if(sram_size == 0)
    put_string("ROM is not installed!? Then... who am I?!\n");
  else {
    int rom_latency;
    asm("MRC p3, 0, %0, cr0, cr1":"=r"(rom_latency):);
    printf("0xC0000000 ROM: *** bytes, %i-bit, %i cycles\n",
           (rom_latency&1)?16:32, rom_latency>>1);
    printf("0x80000000 SRAM: %i bytes, %i-bit, %i cycles\n",
           sram_size, (rom_latency&1)?16:32, rom_latency>>1);
  }
  char* p = 0;
  for(int mem = 1;; ++mem) {
    int mem_size, mem_latency;
    asm("MCR p3, 0, %2, cr0, cr0\n\t"
            "MRC p3, 0, %0, cr0, cr0\n\t"
            "MRC p3, 0, %1, cr0, cr1":"=r"(mem_size),"=r"(mem_latency):"r"(mem));
    if(mem_size == 0) break;
    printf("0x%p RAM #%i: %i bytes, %i-bit, %i cycles\n",
           p, mem, mem_size, (mem_latency&1)?16:32, mem_latency>>1);
    p += mem_size;
  }
  dump_component_list();
  asm volatile("CDP p3, 0, cr0, cr0, cr0, #0");
  __builtin_unreachable();
}
