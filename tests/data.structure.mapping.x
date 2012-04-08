(SET PC (# end))
(: start)
   (WORD 0)
   (WORD 0)
   (WORD 0)
   (WORD 0)
   (DATA 1 2 3)
(: end)

(struct pnt
   (x word)
   (y word)
)

(struct foo 
   (id word)
   (vector (array word 16))
   (head (ptr word))
   (position (ptr pnt))
   (size pnt)
   (final word)
)

(SET (REG A) (sizeof foo))
(SET (REG A) (sizeof pnt))
(SET (REG X) (offset pnt x))
(SET (REG Y) (offset pnt y))
(SET (REG I) (offset foo id))
(SET (REG I) (offset foo vector))
(SET (REG I) (offset foo head))
(SET (REG I) (offset foo position))
(SET (REG I) (offset foo size))
(SET (REG I) (offset foo final))

# let's allocate
(: p1) (WORDS (sizeof pnt))
(: p2) (WORDS (sizeof pnt))
(: foo1) (WORDS (sizeof foo))

(SET (REG A) (# p1))
(SET (AT A (offset pnt x)) 0x04)
(SET (AT A (offset pnt y)) 0x02)

(: skip)
(SET (REG B) (# p1))
(SET (REG B) (# p2))
(SET (REG B) (# foo1))
(SET (REG B) (# skip))

# bug fix for hex literals
(SET (REG B) 0xdead)
(SET (REG B) 0xbeef)

