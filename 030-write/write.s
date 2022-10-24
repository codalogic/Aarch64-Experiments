/*****************************************************************************

write.s
=======

This is derived from the example at:
    https://peterdn.com/post/2020/08/22/hello-world-in-arm64-assembly/

*****************************************************************************/

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
    mov     x2, x1      // count = len
    mov     x1, x0      // buf = msg

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
