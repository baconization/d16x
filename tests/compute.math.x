# so, this is a very bad way to do computations when we have 8 registers;
#  however, this is available to test and evaluate correctness

(compute (REG A) (+ 1 (- 7 5)))
(compute (REG B) (* 2 (/ 9 3)))

# my dream is to have a (compute ...) where you provate a temporary/return register 
# and then provite trash registers which will get used to optimize the evaluation
