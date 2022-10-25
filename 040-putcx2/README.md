putcx2 and the full stack frame
===============================

In this exercise we'll create a subroutine to write a single ASCII character to the
screen twice.  

In so doing we will describe the details of a traditional complete stack frame.

This subroutine relies on the `write()` subroutine that we wrote earlier (which is not
reproduced here).  To use `write()` we need to create a string in memory from the
subroutine's input character given in the `x0` register.  We could put it in some global
memory but a better option is to put it on the stack.

Let's get started...

Before `putx2` gets called, the stack looks like this:

```txt
                           fp = x29 = ?????
                           lr = x30 = ?????
|                     | <- sp = x31
+---------------------+
```

When a subroutine is called the return program counter is placed in the `x30` register.
To make that easier to remember, the `x30` register can also be referred to as `lr`, which
stands for "link register".

If we call another subroutine in this subroutine the `lr` register will get overwritten with the
program counter return address that call.  As we are going to call `write()` we need to store `lr`
somewhere and the stack is the place to do it.

To do that, remembering that the stack is grown downwards, towards lower memory, we do:

```asm
stp     fp, lr, [sp,#-16]!
// Equivalent to: stp     x29, x30, [sp, -#16]!
```

This uses the `stp` "Store Pair" instruction to subtract 16 from the stack pointer and
store the pair of registers `fp` and `lr` (AKA `x29` and `x30`) at the location pointed
to by the modified stack pointer.

We will talk more about the `fp` frame pointer soon but for now accept that we also
need to store it on the stack.

After the `stp` instruction the stack looks like this:

```txt
                           fp = x29 = ?????
                           lr = x30 = ?????
|                     |
+---------------------+
|         lr          |
+---------------------+
|    original fp      | <- sp = x31
+---------------------+
```

We then store the updated stack pointer in the frame pointer using:

```asm
mov     fp, sp
```

Giving us:

```txt
|                     |
+---------------------+
|         lr          |
+---------------------+
|    original fp      | <- sp, fp
+---------------------+
```

Next we want to store the char to be printed onto the stack.  There are many ways to do this,
but the general way is to allocate a chunk of memory on the stack and then store
any variables we need into that allocated space.

Remembering that we need to keep the stack pointer 16-byte aligned, we do:

```asm
sub     sp, sp, #16
```

Giving us:

```txt
|                     |
+---------------------+
|         lr          |
+---------------------+
|    original fp      | <- fp
+---------------------+
|                     |
|                     |
|                     |
|        ...          |
|                     | <- sp
+---------------------+
```

Then we write our two characters into that space using:

```asm
strb    w0, [fp,#-1]
strb    w0, [fp,#-2]
```

This yields:

```txt
|                     |
+---------------------+
|         lr          |
+---------------------+
|    original fp      | <- fp
+---------------------+
| c | c |             |
+---------------------+
|                     |
|                     |
|        ...          |
|                     | <- sp
+---------------------+
```

Here we've done that using addressing relative to the `fp` register.  In this case
the `fp` register marks the dividing line between the data put on the stack by the
calling subroutine and the data put on the stack by the called subroutine.  Positive offsets
from `fp` will access data put on by the calling subroutine and negative offsets of `fp`
will access data of the called subroutine.

Compilers that can more easily keep track of the offsets of various pieces of data than
us people may access data relative to the `sp` stack register.

Now we call our `write` subroutine by putting the address of the lowest character in `x0`
and the length of `2` in `x1`:

```asm
add     x0, fp, #-2
mov     x1, #2
bl      _write
```

(As a trivia aside, this gives the opportunity to say that there are no op-codes to do
register to register moves in Aarch64.  Instructions like `mov rd, rs` are actually implemented as
aliases of `add rd, rs, #0`.  There are other similar tricks in the instruction set opcode mapping
that I can hopefully visit at some point.)

Once the `write()` call returns we need to start unwinding the stack.

The first operation is:

```asm
mov     sp, fp
```

This retores the stack pointer to the value it had before we allocated space for
the string with the characters.  Note that we could have messed around with the stack
pointer many times in our subroutine, growing and shrinking the stack in an ad-hoc way,
but this operation will restore the original stack pointer in a simple and safe way.

The stack now looks like:

```txt
|                     |
+---------------------+
|          lr         |
+---------------------+
|    original fp      | <- fp, sp
+---------------------+
| c | c |             |
+---------------------+
|                     |
|                     |
|        ...          |
|                     |
+---------------------+
```

Next we need to restore the `fp` register and the `lr` register so we can make a successful return call.

```asm
ldp     fp, lr, [sp], #16
```

(Personally I'd have liked that instruction to include an `!` mark on the end to make it clearer that `sp`
is being modified.  i.e. It would be `ldp fp, lr, [sp], #16 !`.)

This yields:

```txt
                           fp = x29 = original fp
                           lr = x30 = ?????
|                     | <- sp = x31
+---------------------+
|         lr          |
+---------------------+
|    original fp      |
+---------------------+
| c | c |             |
+---------------------+
|                     |
|                     |
|        ...          |
|                     |
+---------------------+
```

With the link register restored, the `ret` instruction can be called:

```asm
ret
```

This returns the stack to its orignal state. All the data that was put on it is
now out-of-date so we can ignore it:

```txt
                           fp = x29 = original fp
                           lr = x30 = ?????
|                     | <- sp = x31
+---------------------+
```

The benefit of using the frame pointer, especially when doing manual assembly coding,
is that you can easily restore the stack pointer irrespective of how many chunks of data
you allocated.  You can also push and pop data on the stack without having to
re-compute the offsets needed to access the various bits of data.

The complete `putcx2` subroutine code is:

```asm
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
```

It is called using:

```asm
_start:
    mov     x0, #'A'
    bl      _putcx2
    mov     x0, #'Z'
    bl      _putcx2
    mov     x0, #'\n'
    bl      _putcx2
    bl      _exit
```

As usual, using the script, this can be assembled and run using:

```asm
../aarch64 putcx2
```
