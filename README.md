# Aarch64 Experiments

Experiments with Arm Aarch64 / Arm64 Assembly Code

The intent is to build up some code that will act as an introduction to
Aarch64/Arm64 programming.  Each program will build on the previous program
but each step will be stored in a separate directory so that the
evolution is clear and you can follow the growth of the code.  I've numbered the
directories so you can easily see the order.  I've gone up in jumps of 10 in case
it later occurs to me to add an intermediate step!

I run this on a Raspbery Pi 4 running Ubuntu.

I use the GNU assembler: GAS.  To get these tools do:

```bash
sudo apt update
sudo apt upgrade
sudo apt install gcc
```

To more easily build the code I've created a bash file called `aarch64` that contains:

```bash
as -o $1.o $1.s && ld -o $1 $1.o && ./$1
```

(Don't forget to do `chmod +x aarch64` to make the bash file executable.)

For example, to build the code in the first example, which is called `exit`, do:

```bash
aarch64 exit
```

## Overview of Aarch64

The Arm 64-bit architecture as 31 64-bit registers named `x0` to `x30`.  32-bit operations 
can be done on these registers by referring to the registers as `w0` to `w30`.

The stack pointer and the zero register take the place of what would be `x31`.  Depending on the
instrution used, when the instruction encodes register `11111` (31) either the stack pointer or the zero
register will be accessed.

The zero register allows instructs to have zero valued inputs and to be able to discard
results of computations.  For example, register to register `mov` instructions are done
by adding (via `add`) the zero register to a register and storing the result in the target register.
`cmp` comparison instructions are performed by subtracting the content of two registers
and storing the result to the zero register, thus discarding it.

The architecture also has 32 128-bit floating point registers, some 'house keeping' registers
and the option of vector processor registers.  These are not discussed in this tutorial.

The Arm Procedure Call standard specifies that `x0` to `x7` are used to pass parameters to a subroutine.
`x8` is used to pass in a pointer to a location for returning large objects that can't be returned in `x0`.

Once inside a subroutine, the values in `x0` to `x15` can be modified and do NOT have to be restored before
returning to the caller.  However, if `x19` to `x28` are modified their values must be restored before
returning to the caller.  `x16` to `x18` have special uses and are probably best left alone.
`x29` and `x30` also have special uses as the 'Frame Pointer' and 'Link Register'.

Values are returned to the caller in `x0` or, if the value won't fit in a register, in the location
pointed to by `x8`.

## Useful Resources

Learn the architecture - AArch64 Instruction Set Architecture - https://documentation-service.arm.com/static/62d02ce031ea212bb66273fe?token=

ARMv8 A64 Quick Reference - https://courses.cs.washington.edu/courses/cse469/18wi/Materials/arm64.pdf

GAS Assembler manual - https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_chapter/as_toc.html

Arm64 syscalls - https://arm64.syscall.sh/

Linux A64 syscalls unistd.h file - https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/unistd.h
