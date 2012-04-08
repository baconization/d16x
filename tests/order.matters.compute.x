# testing optimization of math

(compute (REG A) (REG Z) (REG Y) (REG X) 
   (/
      (+ (REG B) 
         (* (+ 2 (REG C)) (REG I))
      )
      (* (+ 3 (REG C)) (REG J))
   )
)
