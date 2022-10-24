sys-write - Writing text to  the screen
=======================================

This is possibly the simplest _useful_ program.  It prints out the string
`Hello, ARM64 World!` by directly calling the revelant syscall (#64).

This example introduces the data segment using the `.data` directive and defines
an ASCII string which is identified by the label `msg`.

```asm
.data
msg: .ascii        "Hello, ARM64 World!\n"
```

The program shows how we can compute values based on labels.  In this case we compute the
length of the message by doing:

```asm
len = . - msg
```

Here the `.` represents the current address at which data would be written if another piece of data
was included in the data segment.  By subtracting the address of the start of the message
from the current address we get the length of the message.

We also see how to include the values of labels and computed values in our assembly.
This is done by preceding them with the `=` character.  For example:

```asm
ldr     x1, =msg    // buf = msg
ldr     x2, =len    // count = len
```

The complete program is:

```asm
// Material for the data segment
.data

msg: .ascii        "Hello, ARM64 World!\n"
len = . - msg

// Start the segment containing the program code (as opposed to data)
.text

// Specify the application's entry point.
.global _start

// The start of the code
_start:
    // syscall prototype is write(int fd, const void *buf, size_t count)
    mov     x0, #1      // fd := STDOUT_FILENO
    ldr     x1, =msg    // buf = msg
    ldr     x2, =len    // count = len
    mov     x8, #64     // write syscall is #64
    svc     #0          // invoke syscall

    // invoke exit using the exit(int status) syscall
    mov     x0, #0      // status = 0
    mov     x8, #93     // exit syscall is #93
    svc     #0          // invoke syscall
```

Using our script, this can be assembled and run using:

```asm
../aarch64 sys-write
```
