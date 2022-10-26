puthex
======

When running programs its handy to print out numerical values.  `puthex` prints of the
value in the `x0` register in hexdecimal format.

In addition to being a useful function we will also see some
interesting Aarch64 instructions, including `rev` and `csel`.

Compared to the earlier subroutines, this has turned out to be quite long but hopefully
it will all make sense.

Let's begin...

I want to prefix the displayed number with `0x`.  To do that I defined an ASCII
string.  I put it in the `.text` program segment because I didn't want it to be modifiable.

```asm
hex_preamble: .ascii "0x"
```

The prefix is only 16-bits long.  Instructions need to be aligned to 32-bit boundaries so
it is necessary to tell the assembler to re-align its output using the `.align` directive.
In this case the `2` tells the assembler to align to a `2^2` byte boundary.

```asm
.align 2    // 4 byte boundary
```

Starting the subroutine, we do the regular stack from preamble sequence.

```asm
puthex:
    // void puthex( int64 x0 /* v */ )

    stp     fp, lr, [sp,#-16]!
    mov     fp, sp
```

We want to use some register while the subroutine is running, specifically
`x19` as a temporary store and `x20` as a loop counter, so we
store their initial values on the stack for later recovery.

```asm
    stp     x19, x20, [sp,#-16]!
```

We need `x0` and `x1` to call subroutines so we need to put the input `x0`
value somewhere where we can retrieve it after a subroutine call.  I've chosen
to put it in `x19`.

```asm
    mov     x19, x0
```

Next we print the preamble string mentioned earlier using our `write` subroutine.

```asm
    // Print "0x" to make it clear it's a hex value
    ldr     x0, =hex_preamble
    mov     x1, 2
    bl      write
```

I want to skip leading zeros, but I don't want to print nothing if the
whole value is zero.  To handle this case a test is made to see if
the input is zero.  This is done using a `cmp` instruction.  If the input is
not zero the "branch not equal" `b.ne` instruction wil branch to the next section.
If the input is zero we use `putc` to output two zeros.
Note that each time we call `putc` we must re-initialise `x0`
because called functions are allowed to overwrite the contents of
registers `x0` to `x7`.  When this special case is handled we branch
to the exit.  (A label beginning with `.L` is a local label and won't be exported
in the object file.  Local labels still have file wide scope so I have chosen to
name local labels using the format: `.L_<subroutine name>_<local name>`.)

```asm
    // If the input value is 0, print "00" then jump to return
    cmp     x19, 0
    b.ne    .L_puthex_1
    mov     x0, #'0'
    bl      putc
    mov     x0, #'0'
    bl      putc
    b       .L_puthex_exit
```

Now here's a neat Aarch64 instruction!  We want the highest
order byte to be processed and displayed first.  We therefore use the
`rev` instruction to reverse the order of the bytes in our
input register.  If the input was `0x0123456789abcdef` the
result would be `0xefcdab8967452301`.

```asm
.L_puthex_1:
    // Reverse the order of the bytes in x19
    rev     x19, x19
```

A 64-bit register contains 8 bytes so we need to run the next loop
8 times.  We're using `x20` to keep track of how many more loops we
need to do.

```asm
    // There are 8 bytes in x19 so we have to do the below
    // operation 8 times
    mov     x20, #8
```

I want to skip leading zeros.
If the least significant byte in `x19` is non-zero
branch to the main display code to display it.

```asm
.L_puthex_2:
    tst     x19, #0x0f
    bne     .L_puthex_3
```

Otherwise skip the zero byte by shifting in the next byte
and decrementing the loop count.  Then branch back to the check to
see if the next byte is zero.

```asm
    lsr     x19, x19, #8
    subs    x20, x20, 1
    bne     .L_puthex_2
    b       .L_puthex_exit  // Defensive - Shouldn't be possible
                            // to get here as value can't be zero
```

A byte contains two hex nibbles.  To avoid code duplication I have added an extra subroutine to
output a 4 bit nibble.  I will describe that later.  But first
we have to get the top nibble into the low nibble using an
`lsr` logical shift right instruction.  We can then call the
`puthexnibble` nibble output subroutine, reload `x0` with the output value and
output the low nibble.

```asm
.L_puthex_3:
    // Output top nibble of byte (note lsr)
    mov     x0, x19
    lsr     x0, x0, #4
    bl      puthexnibble

    // Output bottom nibble of byte
    mov     x0, x19
    bl      puthexnibble
```

Having output the hex for a byte, we move the next byte into the lower
byte position using another `lsr` logical shift right.

```asm
    lsr     x19, x19, #8
```

Time to work out if we have done enough loops.  We subtract `1` from our
loop count stored in `x20`.  We have seen the `sub` instruction before
but this time we use the `subs` instruction.  Unlike `sub`, this updates the
status register with the result of the subtraction.  If the result is zero
the `z` zero flag will be set in the status register and we can test that
using the branch if not equal `b.ne` instruction.  If the count hasn't got to zero
we loop back to display the next byte.

```asm
    subs    x20, x20, 1
    b.ne    .L_puthex_3
```

If the count is zero then all the bytes have been output.  All that remains to
recover the registers we put aside for safe keeping, do the stack frame
postamble and do the `ret` subroutine return.

```asm
.L_puthex_exit:
    ldp     x19, x20, [sp]
    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret
```

The `posthexnibble` instruction mentioned earlier highlights another interesting
feature of the Aarch64 instruction set.

As you know, hex values are represented by the ASCII characters `0` to `9` and
`a` to `f`.  We can convert a number in the range `0` to `9` to its ASCII value
by adding the ASCII value of `0` to it.  However, this does not work for a
number is the range `a` to `f`.  In this latter case we have to add the
ASCII value of `a` minus `10`.  We need to do a test to see which of these
two cases our input number falls into.

In the code below we compare the value to `10` using a `cmp` instruction.
This updates the status register.  Rather than perform a branch on the result of this
test we perform both of the above modifications on our number, storing the
result of the first (`x0` + ASCII value of `0`) in `x1` and the second (`x0` + ASCII value of `a`
minus `10`) in `x2`.  Becuase we did these calculations using `add` instructions rather
than `adds` instruction, they didn't modify the status register which means the
result of the earlier `cmp` instruction is preserved.

This allows us to use the 'conditional select' `csel` instruction.  This has an `LT`
'less than' condition attached to it.  Therefore, if the earlier `cmp` instruction
yielded a 'less than' result, the contents of `x1` will be stored in `x0`, otherwise the
contents of `x2` will be stored in `x0`.

Performing conditional selection operations like this avoids having to use
branches that can dramatically slow down the execution of the code.  Depending on
the specific Arm core used the two `add` instructions could be dispatched to separate
execution pipelines and be performed in parallel meaning no time was lost.

```asm
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
```

Oh, and I snuck in a little `putnl()` subroutine to just put out a new line
in order to make life simpler!

Observe that because there is no stack frame
manipulations and the branch to `putc` is the last thing done in this routine,
a simple `b` branch can be done to `putc` rather than a `bl`.  `putc` will
use the link register to directlly return control back to the calling function.

```asm
putnl:
    // void putnl()
    mov     x0, #'\n'
    b       putc
```

Examples of calling `puthex` are below.

This highlights another feature of
the instruction set.  Because all instructions are coded into 32-bit words it's
impossible for an instruction to encode a 64-bit immediate value.  The largest
immediate value that can be inserted into a register in one instruction is 16-bits.

Therefore the following 16-bit values can be loaded in one instruction.

```asm
_start:
    mov     x0, #0
    bl      puthex
    bl      putnl

    mov     x0, #0x89cd
    bl      puthex
    bl      putnl
```

Immediate moves of negative values will be automatically assembled to use the
`movn` 'Move wide with NOT' instruction.  This zeros the register, inserts the immediate
value with an optional shift and then inverts the result.

```asm
    mov     x0, #-100
    bl      puthex
    bl      putnl
```

This means that the immediate range in one instruction is roughly `+/-65536`. I say roughly
because the assembler will try to use shifted values to load values beyond this range if it can.

There are two ways around this 16-bit limit.

Firstly, you can use the 'zero and insert' move instruction `movz` together with the
'keep and insert' `movk` instruction.  These instructions allow the specified 16-bit
immediate value to be left shifted by `0`, `16`, `32` or `48` bits before inserting the
value into a register.  The `movz` (zero) instruction will set the register to zero before
inserting the shifted immediate value and the `movk` (keep) instruction will not zero the
register, keeping its initial value, and insert the shifted immediate value.
Combinations of these instructions allow any 64-bit (or smaller) immediate value to be
placed in a register.

```asm
    // Loads 0x01234567
    movz    x0, #0x0123, LSL 16
    movk    x0, #0x4567
    bl      puthex
    bl      putnl

    // Loads 0x0123456789abcdef
    movz    x0, #0x0123, LSL 48
    movk    x0, #0x4567, LSL 32
    movk    x0, #0x89ab, LSL 16
    movk    x0, #0xcdef
    bl      puthex
    bl      putnl
```

The second is to use some assembler magic with the special assembler `ldr x0, =0xfedcba9876543210` form.  This
puts the value in the `.text` area of the program and automagically defines a pointer
to it which is inserted in place of the specified value.  Using `objdump -d puthex`
will give you a better idea of how this works.  The result of this is shown after the
code snippet.

```asm
    ldr     x0, =0xfedcba9876543210
    bl      puthex
    bl      putnl
    bl      exit
```

The relevant part of the `obj -d puthex` output is here.  You can see
that the `0x0123456789abcdef` value has been put in memory
in little endian order at location `4001d8` and the `ldr` instruction
has been modified to read `x0` from that location.

```txt
  4001bc:       580000e0        ldr     x0, 4001d8 <_start+0x5c>
  4001c0:       97ffffb0        bl      400080 <puthex>
  4001c4:       97ffffd7        bl      400120 <putnl>
  4001c8:       97ffffea        bl      400170 <exit>
  4001cc:       00000000        .inst   0x00000000 ; undefined
  4001d0:       00400078        .word   0x00400078
  4001d4:       00000000        .word   0x00000000
  4001d8:       76543210        .word   0x76543210
  4001dc:       fedcba98        .word   0xfedcba98
```

And that's it.  We're finally done. Although long, this exercise has shown a
number of interesting aspects of the Aarch64 instruction set.  We've seen `cmp`
and conditinal branches, the difference between `sub` and `subs`, `movz` and `movk`
for loading large immediate values and the special instructions `rev` and `csel`.

I hope you enjoyed it.


As usual, using the script, the program can be assembled and run using:

```asm
../aarch64 puthex
```
