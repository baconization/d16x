(table slow (REG A) (REG B)
   (e 0 1)
   (e 1 2)
   (e 2 3)
)

(SET (REG B) 0xffff)

(table fast (REG A) (REG C)
   (e 0 1)
   (e 5 10)
   (e 10 5)
)

(WORD 0)
(: here)
(SET PC (# here))


(table fast (REG A) (REG C)
   (e 0 1)
   (e 1 2)
   (e 2 3)
   (e 3 4)
   (e 4 5)
   (e 5 6)
   (e 6 7)
   (e 7 8)
)


