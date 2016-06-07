#ifndef UUIDH
#define UUIDH

#include "inttypes.h"

typedef struct {
  uint32_t first;
  uint16_t middle[3];
  uint8_t remaining[6];
} uuid_t;

static inline int uuidcmp(const uuid_t* a, const uuid_t* b) {
  return ((uint32_t*)a)[0] != ((uint32_t*)b)[0]
    || ((uint32_t*)a)[1] != ((uint32_t*)b)[1]
    || ((uint32_t*)a)[2] != ((uint32_t*)b)[2]
    || ((uint32_t*)a)[3] != ((uint32_t*)b)[3];
}

static inline void uuidcpy(uuid_t* a, const uuid_t* b) {
  ((uint32_t*)a)[0] = ((uint32_t*)b)[0];
  ((uint32_t*)a)[1] = ((uint32_t*)b)[1];
  ((uint32_t*)a)[2] = ((uint32_t*)b)[2];
  ((uint32_t*)a)[3] = ((uint32_t*)b)[3];
}

#endif
