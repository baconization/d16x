#swap reg1 reg2 regTemp
(INLINE swap
   (SEQ
      (: foo)
      (SET $3 $1)
      (SET $1 $2)
      (SET $2 $3)
      (SET PC (# foo))
   )
)

(swap (REG A) (REG B) (REG C))
(swap (REG A) (REG B) (REG C))

