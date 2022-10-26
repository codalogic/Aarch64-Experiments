puts
====

Having created a subroutine to extract the length of a null-terminated string and also
having the `write` subroutine, printing a null-terminated string to the screen becomes
reasonably straight forward.  This is done using the `puts` subroutine.

We need to call the `strlen` and `write` subroutines.  Hence we need to do the stack preamble:

```asm
puts:
    // void puts( const char * x0 /* s */ )

    stp     fp, lr, [sp,#-16]!
    mov     fp, sp
```

The pointer to the string, which is initially stored in `x0`, will be passed to both
`strlen` and `write`.  Called subroutines are allowed to corrupt the `x0` to `x7`
registers so we need to put it somewhere safe so we can get it back after the
subroutine call.  Therefore we put it on the stack.  (If we decided to put it in, say, `x11`
we'd have to first write `x11` to the stack because we have to return registers `x8` to `x29`
to the calling subroutine unmodified.  Therefore putting `x0` on the stack directly is easier.)

```asm
    str     x0, [sp,#-16]!
```

The pointer to the string we want the length of is already in `x0` so we can directly call
`strlen`.

```asm
    bl      strlen
```

`strlen` will return the length in `x0`, as required by the Arm Procedure Call Standard.
`write` requires the length in `x1` so we move `x0` into `x1`.  Next we retrieve the pointer to
the string from the stack into `x0` and call `write`.

```asm
    mov     x1, x0
    ldr     x0, [sp]
    bl      write
```

Our work is done.  We rely on the standard postamble to fix up the modified stack pointer and
return.

```asm
    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret
```

To test the subroutine I defined a null-terminated string, thus:

```asm
.data

msg:    .asciz "Hello, Aarch64 World!\n"
```

This can be printed as follows:

```asm
_start:
    ldr     x0, =msg
    bl      puts
```

Having to define a string a long why from where it is used is difficult and error prone.

It would be nice if the assembler allowed you to do magic like the following as it does for
numerical values:

```asm
    // NOT VALID ASSEMBLY CODE
    ldr     x0, ="Hello, World!"
```

Alas, I couldn't get this to work.

The best I could do is below.  The `.text 1` directive puts the string into a second text segment.
`0:` gives it a local label.  On return to the main text segment via the `.text` directive the local
label can be referred to using `0b`.  This effectively means "the local label 0 looking backwards".
You can have multiple local labels with the same numerical value so it is possible to use the `0` label
multiple times.

```asm
            .text 1
            0: .asciz "Goodbye for now!\n"
            .text
    ldr     x0, =0b
    bl      puts

            .text 1
            0: .asciz "So bye, bye!\n"
            .text
    ldr     x0, =0b
    bl      puts

    b       exit
```

The output of the program is:

```txt
Hello, Aarch64 World!
Goodbye for now!
So bye, bye!
```

The complete code is:

```asm
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
```

As usual, using the script, this can be assembled and run using:

```asm
../aarch64 puts
```
