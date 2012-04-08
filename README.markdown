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
* expressive computation (+, \*, \-, /, %); write math like (+ 1 (\* 2 (/ 4 (\- 3 1))))
* data structure planning, sizing, and offsets
* inline data: (WORD word), (WORDS cnt), (DATA 1 2 3), "abcdef"

## Roadmap ##

What-ever I want. I'll add things as I need it.

I'm working on a stdlib for this with things like

* large stack mapping (push/pop) (if you could crawl into my head, this would make a lot of sense)
* binary search
* basic math
* fixed point math

And, I'd like to add a "switch" like thing for building an optimized word -> word table.
I should add a "const" concept where I can make idents always refer to a specific word.
More tests!
I'm looking for three emulators that don't suck, so I can do multiple regression tests on the compilation results.

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

Now, that looks stupid, yes? That's because it is. If you attempt to write a high level language, then good luck with that. High level languages tend to build abstractions that leak in terms of performance by abusing the stack to make things nice. It's very clear to see that this happens with arithmetic. For instance, the first check-in of the (compute ...) method did just that, it abused the stack to be correct without a doubt. But, I took the time to optimize (compute ...) and there was a price.

Suppose I want to compute (+ (REG C) (+ (REG B) (+ (REG A)))) and store the result in register X without touching A, B, C

<pre>
(compute (REG X)
  (+ (REG C) (+ (REG B) (+ (REG A))))
)
</pre>

And thus, it will be done. X will now contain the result of A+B+C without mutating any other registers. However, what if we want to make it smarter and faster without using the stack. Then, we pay with another register.

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

What if we give it another trash variable, say (REG Z):

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

Aha, now this is better.
Interestingly enough, by giving the "compute" algorithm more room, it actually removed a register.
I can also rewrite the original expression in a way that causes it to reduce more; for instance,

<pre>
(compute (REG X) (REG Y)
   (+ (+ (REG B) (REG A)) (REG C))
)
</pre>

will become

<pre>
0431                ;(SET (REG X ) (REG B ) ) 
0032                ;(ADD (REG X ) (REG A ) ) 
0832                ;(ADD (REG X ) (REG C ) ) 
</pre>

which is optimal. I'm working on exploiting the commutative properties of addition/multiplication to make this a gurantee.

So, this what I mean by a toll.
That is, I plan on adding some neat "aides" to make this assembler expressive, but you have to give details about its wiggle room.

## Why should I use this? ##

I'd rather you not use it. I'm writing d16x in hopes of giving me a competitive advantage in the future game. 

One of the reasons I'm starting out at a very low level is because memory is constrained to 64KW. For those paying attention, there are only 65,536 words. While that does mean there are 128KB, there is going to be a lot of waste if you don't understand the concept of a word. Also, I have a feeling that counting the cycle time of each operation is important, so for those of us that take the extra time out of our busy days to understand the impact of registers may have a competitive advantage.

## Why is d16x written in OCaml? ##

Oh, that's because I'm a math ass-hole.
I thought about writing it in Haskell to maximize the asshole-ness, but I really like OCaml's pattern matching.
This project is total ass-hole programming since I have a day job where I have to write

* unit tests
* regression tests
* integration tests
* acceptance tests
* comments
* code that is expected to be maintained for decades
 
So, yes, I'm writing the bare minimal code that makes me happy since I plan to win at what-ever notch's game becomes.
It's a lot of fun, and I expect bugs.
Consider yourself lucky that I'm a cheap bastard not wanting to pay $7 to upgrade this account.
