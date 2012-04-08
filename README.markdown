= D16X =

== What is d16x? ==

d16x is a programming language assembler thing for notch's DCPU-16.

See
   http://0x10c.com/doc/dcpu-16.txt
for more details.

-------------------------------------------------

What is a "programming language assembler thing"?

Well, it's a programming language that you are going to hate. That's right, I'm writing a programming language that you are going to hate on _purpose_. That's the goal. It's starting out as a basic assembler written in OCaml. Why OCaml? Because, chances are you hate it, and I don't want you playing in
my sandbox. This project is a very anti-social thing for me.

Although, in some strange paradoxical universe, I also love lisp. That's why the language of d16x is Lisp-like. In fact, I may bring a full lambda calculus meta-style of programming to d16x. Why? So, language primitives in d16x can be written in d16x.

That's right, my goal is to make some basic primitives in d16x that enable me (not you) to write new language primitives in d16x that compile to machine code. But, depending on where I go, I may skimp on this goal and have a lot of primitives defined in OCaml.

One of the reasons I'm starting out at a very low level is because memory is constrained to 64KW. For those paying attention, there are only 65,536 words. While that does mean there are 128KB, there is going to be a lot of waste if you don't understand the concept of a word. Also, I have a feeling that counting the cycle time of each operation is important, so for those of us that take the extra time out of busy days to understand the impact of registers may have a competitive advantage.

What about being "expressive?", oh, I'll be adding function, structs, and closures. Don't worry, it will be very expressive. However, it will require you to be a super genius to use them all effectively.


