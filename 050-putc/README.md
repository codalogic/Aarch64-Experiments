putc
====

The `putcx2` subroutine was a useful exercise but what we really want is
one character at a time using `putc`.

The code for `putc` is below.  Having explained `putcx2` I won't explain the code here.
You can treat this code as a revision exercise.

```asm
_putc:
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
    bl      _write

    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret
```

It is called using:

```asm
_start:
    mov     x0, #'A'
    bl      _putc
    mov     x0, #'Z'
    bl      _putc
    mov     x0, #'\n'
    bl      _putc
    bl      _exit
```

As usual, using the script, this can be assembled and run using:

```asm
../aarch64 putc
```
