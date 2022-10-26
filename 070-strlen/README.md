strlen
======

Having to specify a length in order to display a string is tedious.  Instead it is
easier to use null terminated strings.

You can specify null-terminated strings in the assembler using the `.asciz` directive
instead of the `.ascii` directive.  For example:

```asm
.data

msg:    .asciz "Hello, Aarch64 World!\n"
```

But before we can display a null-terminated string we need to work out its length.
That's what these subroutines do.  I have defined two subroutines here, `strnlen_s` and `strlen`.
`strnlen_s` will work out the length of a string up to a specified maximum.  The intent is
to be safer if it is accidently asked to work out the length of a string that turns out not to be null-terminated.
`strlen` doesn't require the maximum length to be specified.  However, rather than allow
any length string as C's `strlen()` does, it uses `strnlen_s` and specifies a maximum length
of `1000` characters.

This makes the code for `strlen` very simple.  We only have to load `x1` with the second parameter
for `strnlen_s` (`1000`) and then branch to the `strnlen_s` code.

```asm
strlen:
    // int strlen( const char * x0 /* s */ )

    // Set a reasonable maximum and branch to strnlen_s
    mov     x1, #1000
    b       strnlen_s
```

`strnlen_s` is more involved.

Because we are using a number of registers it's a good idea to document their use at the
start of the subroutine.

```asm
strnlen_s:
    // int strnlen_s( const char * x0 /* s */, int x1 /* max_len */ )

    // Register usage:
    //  x0 - Input pointer to string
    //  x1 - Max length we want to search
    // Intermediates:
    //  x2 - Running count of non-null bytes in string
    //  x3 - Place for testing if byte in string is null
```

We're not calling any subroutines and we're not using any registers that we
are not allowed to corrupt.  Therefore we don't need any stack preamble.

`x2` will count the number of characters in the string so we initialise it to `0`:

```asm
    mov     x2, #0
```

Now we start the main loop.

We load the byte pointed to by `x0` into `w3`, post-incrementing the value in `x0` by `1` and
then test the loaded byte to see if it is zero.  If it is we branch to the exit code.

```asm
.L_strnlen_s_main_loop:
    // Load byte pointed to by x0 ready and test if it is zero
    // Branch to exit if it is 0
    ldrb    w3, [x0], #+1
    cmp     x3, #0
    b.eq    .L_strnlen_s_exit
```

If the byte is not zero we increment the byte count by `1`.

```asm
    // Record we have another byte
    add     x2, x2, 1
```

We then decrement the count of the maximum number of bytes we're prepared to look at
by `1` and test if it is zero.  Note the use of `subs` instead of `sub` here to update
the status registers.  If the count is zero we go to the exit code.

```asm
    // Decrement our maximum string length counter
    // Branch to exit if it is zero
    subs    x1, x1, 1
    b.eq    .L_strnlen_s_exit
```

Now we just repeat this for the next byte by going back to the start of the loop:

```asm
    // Repeat
    b       .L_strnlen_s_main_loop
```

In our exit section we move the count from `x2` into the `x0` register.  `x0` is the register
specified to be used for subroutine return values in the Arm Procedure Call Standard.

```asm
.L_strnlen_s_exit:
    // Return the discovered length in x0
    mov     x0, x2
```

Then we can invoke `ret`.

```asm
    // Return
    ret
```

The complete code is:

```asm
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
```

It is called using:

```asm
_start:
    ldr     x0, =msg
    mov     x1, #7
    bl      strnlen_s
    bl      puthex
    bl      putnl
    ldr     x0, =msg
    bl      strlen
    bl      puthex
    bl      putnl
    bl      exit
```

The output is:

```txt
0x07
0x16
```

As usual, using the script, this can be assembled and run using:

```asm
../aarch64 strlen
```
