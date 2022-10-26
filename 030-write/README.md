write - Writing text to  the screen again
=========================================

Writing text to the screen using a syscall works but it's not ideal.
For example, we don't want to have to keep remembering the correct syscall
number each time we want to do it.

A better solution is to turn the write operation into a function or subroutine.

We decide that our subroutine will take a pointer to the string to be written and
the length of the string.  To comply with the Arm Procedure Call Standard,
these will be passed in registers `x0` and `x1` respectively.

However, recall that the write system call requires the pointer to be in
register `x1` and the length to be in register `x2`.  (This is an implementation
detail so we don't decide that our subroutine should take parameters in `x1` and `x2` instead
of `x0` and `x1` just because it might be convenient.)

We therefore need to move the input parameters into the registers where we need them for the
syscall.  This is done as follows:

```asm
mov     x2, x1      // x1 -> x2
mov     x1, x0      // x0 -> x1
```

(Note that it is important to do this in the right order!)

In the Aarch64 Procedure Call Standard we can modify registers `x0` to `x15` as
we choose.  But registers `x8` to `x30` should be returned to the calling function
with the same data in that this function was called with.  (Some of the
`x8` to `x30` registers have special uses and others we can use as we like as long
as we restore the initial values before we return from the subroutine.)

The syscall requires us to put the syscall number in `x8`.  We therefore need to
temporarily store its initial value before modifying it.

We could temporarily store the `x8` register in one of the `x3` to `x15` registers that
we are allowed to modify but are not using in this subroutine.

However, we can also temporarily store any register we want to modify and later restore by
storing its initial value on the stack.  Since this is a tutorial, that's what we'll do:

```asm
str     x8, [sp,#-16]!
```

This subtracts `16` from the stack pointer and stores the `x8` register at that
location.  The `!` tells the cpu to store the computed address back into the
stack pointer.  If the stack pointer was initially `1016` it will end up being `1000`.

You might have noticed that we are allocating 16 bytes of data on the stack even though
the size of `x8` is "only" `8` bytes.  This is because Aarch64 requires that the stack pointer
must be kept 16-byte or 128-bit aligned at all times.

Having saved `x8` we can now safely do the system call:

```asm
mov     x0, #1      // fd := STDOUT_FILENO
mov     x8, #64     // write syscall is #64
svc     #0          // invoke syscall
```

System call done, we can recover `x8` from the stack:

```asm
ldr     x8, [sp], #16
```

This reads the value pointed to by the stack pointer and then updates
the stack pointer by adding `16` to it - thus returning it to
its original value.

All that remains now is to return from the subroutine using a `ret` instruction:

```asm
ret
```

IMPORTANT NOTE: This is a minimalist implementation for a subroutine that doesn't call other
subroutines.  Subroutines that do call other subroutines need to do a little more housekeeping
and I'll cover that in a future exercise.

To call our new function we set our input parameters to the relevant values using
the `x0` and `x1` registers and call our function using the `bl` instruction.

To demonstrate the repeatability of calling the routine I have done this twice in the example:

```asm
ldr     x0, =msg1   // buf = msg1
ldr     x1, =len1   // count = len1
bl      _write

ldr     x0, =msg2   // buf = msg2
ldr     x1, =len2   // count = len2
bl      _write
```

I have also turned the exit system call into a function so it can be more readily used
in larger programs.  (As we are exiting at this point there is no point in storing `x8`
on the stack.)

The complete program is as follows:

```asm
// Material for the data segment
.data

msg1: .ascii        "Hello, ARM64 World!\n"
len1 = . - msg1
msg2: .ascii        "Goodbye for now!\n"
len2 = . - msg2

// Start the segment containing the program code (as opposed to data)
.text

// Specify the application's entry point.
.global _start

_write:
    // Effectively write( const char * x0 /* buf */, size_t x1 /* count */ )
    // Input parameters:
    //   x0 - buf - Pointer to start of data to be written
    //   x1 - count - Length of data to be written

    // To make the syscall we have to move the subroutine's input
    // parameters into the right registers for the syscall
    mov     x2, x1      // x1 -> x2
    mov     x1, x0      // x0 -> x1

    // We should return from this function with x8 unchanged.
    // Step 1 of achieving this is to push it onto the stack
    str     x8, [sp,#-16]!

    // syscall prototype is write(int fd, const void *buf, size_t count)
    mov     x0, #1      // fd := STDOUT_FILENO
    mov     x8, #64     // write syscall is #64
    svc     #0          // invoke syscall

    // Now restore x8 unchanged - Step 2
    ldr     x8, [sp], #16

    // Return to the calling subroutine
    ret

_exit:
    // Subroutine: exit( int x0 /* status */ )
    // invoke exit using the exit(int status) syscall
    mov     x0, #0      // status = 0
    mov     x8, #93     // exit syscall is #93
    svc     #0          // invoke syscall
    // No return!!!

// The start of the code
_start:
    ldr     x0, =msg1   // buf = msg
    ldr     x1, =len1   // count = len
    bl      _write
    ldr     x0, =msg2   // buf = msg
    ldr     x1, =len2   // count = len
    bl      _write
    bl      _exit
```

Using our script, this can be assembled and run using:

```asm
../aarch64 write
```
