# D16X #

## What is d16x? ##

d16x is a programming language assembler thing for notch's DCPU-16.

See
   http://0x10c.com/doc/dcpu-16.txt
for more details on what is dcpu-16.

-------------------------------------------------

## What does d16x offer? ##

d16x offers a lisp-like assembler language written in OCaml.

* basic assembler like language that tastes like lisp (i.e. (SET (REG A) 0x01) instead of SET A, 0x01).
* label a location with (: label) and then recall that (# label) as a value later
* parameterized inline macros with labels that mutate (i.e. you can define higher order primitives like while, if)
* expressive computation (+, \*, -, /, %); write math like (+ 1 (\* 2 (/ 4 (- 3 1))))
                                                                          - 
## What is a "programming language assembler thing"? ##

Well, it's a programming language that you will most likely hate because it does things radically different.
This is on purpose because I want a language that allows me to think expressively in assembly, but not too expressive to commit sins on my behalf. There's not going to be any standards, nor any conventions. Instead, you will be constantly presented a choice. Instead of magic, you are going to have to pay a toll.

## What do you mean "pay a toll" ##

Assembly is simple, and you can tell it do things that are not... needed. For instance, if I wanted to evaluate
1 + 2 and store the result in register A, then I could do this.

<pre>
SET PUSH, 1
SET PUSH, 2
SET A, POP
ADD A, POP
</pre>

Now, that looks stupid, yes? That's because it is. If you attempt to write a high level language, then good luck with that. High level languages tend to build abstractions that leak in terms of performance by abusing the stack to make things nice. It's very clear to see this happen with arithmetic. For instance, the first check-in of the (compute ...) method did just that, it abused the stack to be correct without a doubt. But, I took the time to optimize (compute ...) and there is a price.

Suppose I want to compute (+ (REG C) (+ (REG B) (+ (REG A)))) and store the result in register X without touching A, B, C

<pre>
(compute (REG X)
  (+ (REG C) (+ (REG B) (+ (REG A))))
)
</pre>

And thus, it will be done. X will now contain the result of A+B+C without mutating any other registers. However, what if we want to make it smaler and faster without using the stack. Then, we pay with another register.

<pre>
(compute (REG X) (REG Y)
  (+ (REG C) (+ (REG B) (+ (REG A))))
)
</pre>

Now, register Y is considered trash and owned by the computation process. 
There are no contracts about what register Y contains after this process.
If you want to keep it, then PUSH it into the stack. Wait, what?

without (REG Y), the compiled code looks like

<pre>
0431                ;(SET (REG X ) (REG B ) ) 
0032                ;(ADD (REG X ) (REG A ) ) 
0da1                ;(SET PUSH (REG X ) ) 
0831                ;(SET (REG X ) (REG C ) ) 
6032                ;(ADD (REG X ) POP ) 
0da1                ;(SET PUSH (REG X ) ) 
6031                ;(SET (REG X ) POP ) 
</pre>

However, with (REG Y), the code becomes

<pre>
0441                ;(SET (REG Y ) (REG B ) ) 
0042                ;(ADD (REG Y ) (REG A ) ) 
0831                ;(SET (REG X ) (REG C ) ) 
1032                ;(ADD (REG X ) (REG Y ) ) 
0da1                ;(SET PUSH (REG X ) ) 
6031                ;(SET (REG X ) POP ) 
</pre>

which is slightly better; there is a bit of redundancy... (which is going to get fixed).

What if we give it another trash variable by doing something like this

<pre>
(compute (REG X) (REG Y) (REG Z)
  (+ (REG C) (+ (REG B) (+ (REG A))))
)
</pre>

What does that do?

<pre>
0451                ;(SET (REG Z ) (REG B ) ) 
0052                ;(ADD (REG Z ) (REG A ) ) 
0831                ;(SET (REG X ) (REG C ) ) 
1432                ;(ADD (REG X ) (REG Z ) ) 
</pre>

Aha, now this is better. Interestingly enough, by giving the "compute" algorithm more room, it actually removed a register.

So, this what I mean by toll.
I plan on adding some neat "aides" to make this assembler expressive, but you have to give 
details about its wiggle room.

## Why should I use this? ##

I'd rather you not use it. I'm writing d16x in hopes of giving me a competitive advantage in the future game. 

One of the reasons I'm starting out at a very low level is because memory is constrained to 64KW. For those paying attention, there are only 65,536 words. While that does mean there are 128KB, there is going to be a lot of waste if you don't understand the concept of a word. Also, I have a feeling that counting the cycle time of each operation is important, so for those of us that take the extra time out of our busy days to understand the impact of registers may have a competitive advantage.
