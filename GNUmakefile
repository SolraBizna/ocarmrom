AS=arm-none-eabi-as
CC=clang
CXX=clang++
LD=arm-none-eabi-ld
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump

ASFLAGS=-march=armv7-a -mfloat-abi=soft -EB -mthumb-interwork -meabi=5
CFLAGS=-Oz -g -nostdlibinc -isystem include/ -isystem ../newlib-jarm-build -isystem ../newlib-2.4.0/newlib/libc/include -ffreestanding -mhwdiv=arm,thumb -target armv7a-eabi -march=armv7a -mbig-endian -mfloat-abi=soft -msoft-float -Wall -Werror -mllvm -inline-threshold=-20
CXXFLAGS=$(CFLAGS)
LDFLAGS=--be8 -z max-page-size=4

all: bin/test.elf bin/boot0.rom bin/tetris.rom bin/redclock.rom

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
