#ifndef CCUTILH
#define CCUTILH

struct compact_component {
  uuid_t address;
  char name[16];
};

extern int foreach_cc(struct compact_component* cc,
                      int(*callback)(struct compact_component* cc));
extern int cc_matches_bootfs(struct compact_component* cc);
extern int cc_matches_bootscreen(struct compact_component* cc);
extern int cc_matches_bootgpu(struct compact_component* cc);
extern int cc_is_fs(struct compact_component* cc);
extern int cc_is_screen(struct compact_component* cc);
extern int cc_is_gpu(struct compact_component* cc);

#endif
