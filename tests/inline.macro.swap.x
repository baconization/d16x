#swap reg1 reg2 regTemp
(INLINE swap
   (SEQ 
      (SET $3 $1)
         (SET $1 $2)
             (SET $2 $3)
   )
)

(swap (REG A) (REG B) (REG C))

