This contains source code and a basic build system for OC-ARM ROMs and "boot programs". Some useful ones:

- `bin/boot0.rom`: A basic bootloader, which can boot an ELF file from any connected filesystem. It searches each filesystem for `/OC-ARM` and attempts to boot it.
- `bin/tetris.rom`: A clone of a certain Tetromino-based game, residing entirely in EEPROM and using only the 256 byte built-in SRAM for working memory. Contains some examples of how to efficiently do IO from ROM in assembly.
- `bin/test.elf`: A bootable ELF written in C that prints out some information on the low-level emulated hardware. It does not include (or demonstrate how to use) any standard C library, and it requires `allowSerialDebugCP=true` in `OpenComputers-ARM.cfg` in order to work. (Look in your Minecraft log for its output.)
- `bin/redclock.rom`: Designed for use in a microcontroller with a redstone card. Pulses the north/-Z redstone output between 15 and 0 at 1Hz. Also written in C, also does not include or demonstrate a C library. Not at all tolerant of problems.
- `bin/infinity.rom`: An infinite loop. Good for demonstrating OC-ARM's timing restrictions and little else.

To build this, you need clang 3.5 or later and an ARM build of GNU binutils. Configure binutils targeting `arm-none-eabi` or `arm-linux`, and edit the top of `GNUmakefile` to point to your built versions of those tools. Then just run `make` in this directory. ROMs are given in both ELF and preloaded (suitable for use with `flash`) format. ELFs are given in both stripped and unstripped (suitable for use with `gdb`/`addr2line`/etc.) format. All programs also give a disassembly of the linked code alongside the built binary.

