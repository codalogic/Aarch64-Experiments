/*****************************************************************************

sys-write.s
===========

This is derived from the example at:
    https://peterdn.com/post/2020/08/22/hello-world-in-arm64-assembly/

*****************************************************************************/

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
