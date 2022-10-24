/*****************************************************************************

exit.s
======

This is the simplest correct program you can write on Aarch64.  It is derived
from the example at:
    https://peterdn.com/post/2020/08/22/hello-world-in-arm64-assembly/

*****************************************************************************/

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
