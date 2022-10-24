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

## Useful Resources

Learn the architecture - AArch64 Instruction Set Architecture - https://documentation-service.arm.com/static/62d02ce031ea212bb66273fe?token=

ARMv8 A64 Quick Reference - https://courses.cs.washington.edu/courses/cse469/18wi/Materials/arm64.pdf

GAS Assembler directives - https://sourceware.org/binutils/docs/as/Pseudo-Ops.html

Arm64 syscalls - https://arm64.syscall.sh/

Linux A64 syscalls unistd.h file - https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/unistd.h
