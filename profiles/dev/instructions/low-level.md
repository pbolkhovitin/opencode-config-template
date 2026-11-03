# Low-Level Programming Instructions

## Domains
- Embedded C/C++ (ARM Cortex-M, AVR, RISC-V)
- Firmware development
- Reverse engineering (x86/x64, ARM)
- Assembly: x86_64, ARM Thumb, AVR
- Binary analysis and debugging

## Toolchain
- gcc-arm-none-eabi — ARM cross-compiler
- avr-gcc + avrdude — AVR
- openocd — JTAG/SWD debug
- qemu-system-arm — emulation
- radare2 / rizin — binary analysis
- objdump / readelf — ELF inspection
- gdb-multiarch — debugging

## Commands
```bash
# ARM cross-compile
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -O2 -c main.c

# Link + map
arm-none-eabi-ld -T link.ld -o firmware.elf *.o
arm-none-eabi-objcopy -O binary firmware.elf firmware.bin

# AVR
avr-gcc -mmcu=atmega328p -Os -o main.elf main.c
avrdude -c arduino -p m328p -P /dev/ttyUSB0 -U flash:w:main.elf

# Binary analysis
objdump -d firmware.elf
readelf -h firmware.elf
strings firmware.bin | head -50

# Emulate
qemu-system-arm -M stm32-p103 -kernel firmware.bin

# Debug
gdb-multiarch firmware.elf
target remote localhost:3333  # openocd
```

## Conventions
- Linker script: define FLASH + RAM regions explicitly
- Use volatile for MMIO registers
- Startup code: reset vector, .data init, .bss clear
- Always check linker map for section placement
- Never use `-O0` for production firmware
- HAL/LL библиотеки > прямые регистры (где возможно)

## Verify
```bash
arm-none-eabi-gcc --version && openocd --version && qemu-system-arm --version
```
