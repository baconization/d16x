# simple fibonacci using (stackcompute)

(SET (REG B) 0)
(SET (REG C) 1)

(: loop)
   (compute (REG A) (REG X) (+ (REG B) (REG C)))

   (SET (REG B) (REG C))
   (SET (REG C) (REG A))
   (SET PC (# loop))

# on second thought, (stackcompute ) while neat is kind of bullshit.
