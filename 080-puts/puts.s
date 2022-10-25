.data

msg:    .asciz "Hello, Aarch64 World!\n"

// Start the segment containing the program code (as opposed to data)
.text

// Specify the application's entry point.
.global _start

puts:
    // void puts( const char * x0 /* s */ )

    stp     fp, lr, [sp,#-16]!
    mov     fp, sp

    // We need x0 and x1 to call subroutines so put input x0
    // somewhere safe.
    str     x0, [sp,#-16]!

    // The location of the string is already in x0 so we can
    // call strlen directly
    bl      strlen

    // Put the calculated length in x1 and retrieve the original
    // pointer to the string and put it in x0
    mov     x1, x0
    ldr     x0, [sp]
    bl      write

    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret

strlen:
    // int strlen( const char * x0 /* s */ )

    // Set a reasonable maximum and branch to strnlen_s
    mov     x1, #1000
    b       strnlen_s

strnlen_s:
    // int strnlen_s( const char * x0 /* s */, int x1 /* max_len */ )

    // Register usage:
    //  x0 - Input pointer to string
    //  x1 - Max length we want to search
    // Intermediates:
    //  x2 - Running count of non-null bytes in string
    //  x3 - Place for testing if byte in string is null

    // We're not calling any subroutines.  No need for any stack work

    // Initialise our count
    mov     x2, #0

.L_strnlen_s_main_loop:
    // Load byte pointed to by x0 ready and test if it is zero
    // Branch to exit if it is 0
    ldrb    w3, [x0], #+1
    cmp     x3, #0
    b.eq    .L_strnlen_s_exit

    // Record we have another byte
    add     x2, x2, 1

    // Decrement our maximum string length counter
    // Branch to exit if it is zero
    subs    x1, x1, 1
    b.eq    .L_strnlen_s_exit

    // Repeat
    b       .L_strnlen_s_main_loop

.L_strnlen_s_exit:
    // Return the discovered length in x0
    mov     x0, x2

    // Return
    ret

hex_preamble: .ascii "0x"

.align 3    // 8 byte boundary

puthex:
    // void puthex( int64 x0 /* v */ )

    stp     fp, lr, [sp,#-16]!
    mov     fp, sp

    // We need x0 and x1 to call subroutines so put input x0
    // somewhere safe
    str     x11, [sp,#-16]!
    mov     x11, x0

    // Print "0x" to make it clear it's a hex value
    ldr     x0, =hex_preamble
    mov     x1, 2
    bl      write

    // If the input value is 0, print "00" then jump to return
    cmp     x11, 0
    bne     .L_puthex_1
    mov     x0, #'0'
    bl      putc
    mov     x0, #'0'
    bl      putc
    b       .L_puthex_exit

.L_puthex_1:
    // Reverse the order of the bytes in x11
    rev     x11, x11
    // There are 8 bytes in x11 so we have to do the below
    // operation 8 times
    mov     x12, #8

.L_puthex_2:
    // We want to skip leading zeros.
    // If the least significant byte in x11 is non-zero
    // branch to display it, else shift in the next byte
    // and decrement the loop count
    tst     x11, #0x0f
    bne     .L_puthex_3

    lsr     x11, x11, #8
    subs    x12, x12, 1
    bne     .L_puthex_2
    b       .L_puthex_exit  // Defensive - Shouldn't be possible
                            // to get here as value can't be zero

.L_puthex_3:
    // Output top nibble of byte (note lsr)
    mov     x0, x11
    lsr     x0, x0, #4
    bl      puthexnibble

    // Output bottom nibble of byte
    mov     x0, x11
    bl      puthexnibble

    // See if we've finished
    lsr     x11, x11, #8
    subs    x12, x12, 1
    bne     .L_puthex_3

.L_puthex_exit:
    ldr     x11, [sp]
    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret

puthexnibble:
    // void puthexnibble( int64 x0 /* v */ )

    and     x0, x0, #0x0f
    cmp     x0, #10
    add     x1, x0, #'0'
    add     x2, x0, #'a'-10
    csel    x0, x1, x2, LT
    b       putc
    // As putc is the last and only subroutine called we can do a
    // jump rather than a subroutine.  The ret in putc will take
    // us back to the calling function
    // If we could guarentee putc always followed puthexnibble we
    // wouldn't even need the branch!

putnl:
    // void putnl()
    mov     x0, #'\n'
    b       putc

putc:
    // void putc( char x0 /* c */ )

    stp     fp, lr, [sp,#-16]!
    mov     fp, sp

    // To call write() we need our character in memory so let's put
    // it on the stack
    sub     sp, sp, #16
    strb    w0, [fp,#-1]

    // Now call write() to write the character string
    add     x0, fp, #-1
    mov     x1, #1
    bl      write

    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret

write:
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

exit:
    // Subroutine: exit( int x0 /* status */ )
    // invoke exit using the exit(int status) syscall
    mov     x0, #0      // status = 0
    mov     x8, #93     // exit syscall is #93
    svc     #0          // invoke syscall
    // No return!!!

// The start of the code
_start:
    ldr     x0, =msg
    bl      puts
    b       exit
