#ifzero (value to test as zero) (block to run if zero)
(INLINE ifzero
   (SEQ
      (IFN $1 0)
      (SET PC (# skip))
      $2
      (: skip)
   )
)

(ifzero (REG A)
   (SEQ
      (SET (REG B) 0)
      (SET (REG C) 0)
      (SET (REG X) 0)
      (SET (REG Y) 0)
      (SET (REG Z) 0)
      (SET (REG I) 0)
      (SET (REG J) 0)
   )
)

