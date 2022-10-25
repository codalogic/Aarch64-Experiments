// Start the segment containing the program code (as opposed to data)
.text

// Specify the application's entry point.
.global _start

_putcx2:
    // void putcx2( char x0 /* c */ )

    // Store the Link Register (x30 == lr) and frame pointer (x29 == fp)
    // on to the stack
    stp     fp, lr, [sp,#-16]!
    // Equivalent to: stp     x29, x30, [sp, -#16]!
    mov     fp, sp

    // To call write() we need our character in memory so let's put
    // it on the stack
    //strb    w0, [sp,#-16]!
    sub     sp, sp, #16

    strb    w0, [fp,#-1]
    strb    w0, [fp,#-2]

    // Now call write() to write the 2 character string
    add     x0, fp, #-2
    mov     x1, 2
    bl      _write

    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret

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
    mov     x0, #'A'
    bl      _putcx2
    mov     x0, #'Z'
    bl      _putcx2
    mov     x0, #'\n'
    bl      _putcx2
    bl      _exit
