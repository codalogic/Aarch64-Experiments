exit - The Simplest AArch64 Program
===================================

This is the simplest correct program you can write on Aarch64.
It is derived from the example at:
    https://peterdn.com/post/2020/08/22/hello-world-in-arm64-assembly/

Even though it is simple it contains a lot of useful information for
getting started.

It shows how comments are written (pretty much essential when writing
assembler), how to identify the section containing program code as
opposed to data, how to mark the start of your program and how to exit.

The program (which is stored in the file `exit.s`) is as follows:

```asm
// Start the segment containing the program code (as opposed to data)
.text

// Specify the application's entry point.
.global _start

// The start of the code
_start:
    // invoke exit using the exit(int status) syscall
    mov     x0, #0      // status = 0
    mov     x8, #93     // exit syscall is #93
    svc     #0          // invoke syscall
```

Comments are the same style as C++ comments.

Different section of the program are identified using Assembler directives.

The `.text` directive identifies the program section.  A `.data` directive (not used here)
identifies a data section.

Labels are used to identify locations with in a program.  They can identify locations
in the program code or the data.  They have the form `<name>:` where `<name>` is
replaced by the name of the label.  In this program `_start:` is a label identifying the
start of the program.

A list of assembler directives is available at https://sourceware.org/binutils/docs/as/Pseudo-Ops.html.

The end of the program is signalled to the OS by the `svc` instruction
system call.  Syscall `93` invokes the equivalent of the
C `exit(int)` function.  (More precisely, an `exit(int)` call in C
ends up invoking syscall `93`.)

Other syscall codes are listed at https://arm64.syscall.sh/.

To turn the program into an executable you need an assembler and linker.
I'm using these on my Raspberry 4 running Ubuntu via the following instructions:

```
as -o exit.o exit.s
ld -o exit exit.o
```

To run the program do:

```
./exit
```

Using the bash script mentioned in the
[README for the top-level of this tutorial](../) this can be also done using:

```bash
../aarch64 exit
```

The program does nothing!  That's actually a good thing because one
of the things it could do if it was wrong would be to cause a seg fault!

For example, one way to get a seg fault is to naively assume that the
way to exit the program is to simply use a `ret` instruction.
