#include "boot1.h"
#include "interchange.h"

const int32_t initial_out_line_invoke_buf[] = {
  ICTAG_STRING(3), 'set\0', ICTAG_INT, 3, ICTAG_INT, //(int32_t)0xDEADBEEFU,
  //ICTAG_STRING(0), 0,0,0,0,0,0,0,0,0,0,0
};
static inline int32_t* get_out_line_invoke_buf() {
  return (int32_t*)(memory_bytes-32-ALIGN4(SCREEN_WIDTH));
}
void setup_linebuf() {
  const int32_t* pi = initial_out_line_invoke_buf;
  int32_t* po = get_out_line_invoke_buf();
  for(int n = 0; n < 5; ++n)
    *po++ = *pi++;
}
uint32_t cur_line;
static const int32_t clear_screen_invoke_buf[] = {
  ICTAG_STRING(4), 'fill',
  ICTAG_INT, 1, ICTAG_INT, 2,
  ICTAG_INT, SCREEN_WIDTH, ICTAG_INT, SCREEN_HEIGHT-2,
  ICTAG_STRING(1), ' \0\0\0',
  ICTAG_END
};
void clear_screen() {
  if(!have_ui()) return;
  asm volatile("MCR p3, 0, %[gpu], cr1, cr1\n\t"
               "LDC p3, cr1, %[clear_screen_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #1"
               : /* no outputs */
               : [clear_screen_invoke_buf]"m"(clear_screen_invoke_buf),
                 [gpu]"r"(&nvram_bootgpu));
  cur_line = 3;
}
static const int32_t scroll_screen_invoke_buf[] = {
  ICTAG_STRING(4), 'copy',
  ICTAG_INT, 1, ICTAG_INT, 4,
  ICTAG_INT, SCREEN_WIDTH, ICTAG_INT, SCREEN_HEIGHT-4,
  ICTAG_INT, 1, ICTAG_INT, 3,
  ICTAG_END
};
static const int32_t clear_last_line_invoke_buf[] = {
  ICTAG_STRING(4), 'fill',
  ICTAG_INT, 1, ICTAG_INT, SCREEN_HEIGHT-2,
  ICTAG_INT, SCREEN_WIDTH, ICTAG_INT, 1,
  ICTAG_STRING(1), ' \0\0\0',
  ICTAG_END
};
static void scroll_screen() {
  asm volatile("LDC p3, cr1, %[scroll_screen_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #1\n\t"
               "LDC p3, cr1, %[clear_last_line_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #1"
               : /* no outputs */
               : [scroll_screen_invoke_buf]"m"(scroll_screen_invoke_buf),
                 [clear_last_line_invoke_buf]"m"(clear_last_line_invoke_buf));
  --cur_line;
}
void put_out_line(char* endp) {
  if(!have_ui()) return;
  asm volatile("MCR p3, 0, %[gpu], cr1, cr1"
               ::[gpu]"r"(&nvram_bootgpu));
  while(cur_line >= SCREEN_HEIGHT)
    scroll_screen();
  int32_t* out_line_invoke_buf = get_out_line_invoke_buf();
  out_line_invoke_buf[5] = cur_line;
  int32_t strlen = endp - start_out_line();
  out_line_invoke_buf[6] = ICTAG_STRING(strlen);
  if(strlen > SCREEN_WIDTH || strlen < 0)
    die("put_out_line called with bad length");
  if(strlen&3) endp += 4-(strlen&3);
  *(int32_t*)endp = ICTAG_END;
  asm volatile("LDC p3, cr1, %[out_line_invoke_buf]\n\t"
               "CDP p3, 2, cr0, cr0, cr0, #1"
               : /* no outputs */
               : [out_line_invoke_buf]"m"(*out_line_invoke_buf));
  ++cur_line;
}
void out_line(const char* p) {
  char* endp = start_out_line();
  while(*p) *endp++ = *p++;
  put_out_line(endp);
}
