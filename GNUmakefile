OCCROSS_PREFIX=/opt/occross/armeb-oc_arm-eabi/bin
AS=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-as
CC=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-gcc
CXX=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-g++
LD=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-gcc
OBJCOPY=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-objcopy
OBJDUMP=$(OCCROSS_PREFIX)/armeb-oc_arm-eabi-objdump

ASFLAGS=
CFLAGS=-Os -g -Wall
CXXFLAGS=$(CFLAGS)
LDFLAGS=-z max-page-size=4 -nostartfiles

all: bin obj bin/test.elf bin/boot0.rom bin/tetris.rom bin/redclock.rom

bin:
	mkdir -p bin

obj:
	mkdir -p obj

bin/%.rom: bin/%.elf
	@echo "Preloading to $@..."
	@$(OBJCOPY) $< -Sg -O binary $@~
	@echo -n "--[==[" > $@
	@cat $@~ >> $@
	@rm -f $@~
	@echo -n "]==]error\"This EEPROM is not compatible with Lua computers\"" >> $@
	@(test `wc -c $@ | cut -f 1 -d " "` -gt 4096 && echo "WARNING: Image is larger than 4KiB" >&2) || true

bin/%.elf: src/%.ld obj/%.o
	@echo "Linking $@..."
	@$(LD) $(LDFLAGS) -T $^ -o $@
	@($(OBJDUMP) -d $@ > bin/$*.txt) || true

bin/test.elf: src/test.ld obj/test.o obj/startup.o

bin/boot1.elf: src/boot1.ld obj/boot1.o obj/boot1_startup.o obj/boot1_devsetup.o obj/boot1_ccutil.o obj/nvram.o obj/debug.o obj/boot1_autoboot_prompt.o obj/boot1_out_line.o obj/boot1_ramstack.o obj/u2a.o obj/boot1_key_was_pressed.o

bin/boot0.elf: src/boot0.ld obj/boot0.o obj/boot0_ccutil.o

bin/tetris.elf: src/tetris.ld obj/tetris.o obj/tetris_startup.o obj/tetrominoes.o obj/tetris_util.o obj/tetris_ccutil.o obj/tetris_ui.o obj/tetris_rand.o

bin/redclock.elf: src/redclock.ld obj/redclock.o obj/startup.o

obj/%.o: src/%.c
	@echo "Compiling $<..."
	@$(CC) $(CFLAGS) -c "$<" -o "$@"

obj/%.o: src/%.cc
	@echo "Compiling $<..."
	@$(CXX) $(CXXFLAGS) -c "$<" -o "$@"

obj/%.o: src/%.s
	@echo "Assembling $<..."
	@$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f obj/* bin/*

.PRECIOUS: obj/%.o bin/%.elf
