(SET (REG A) 0x30)
(SET (AT 0x1000) 0x20)
(SUB (REG A) (AT 0x1000))
(IFN (REG A) 0x10)
(SET PC (# crash))

(SET (REG I) 10)
(SET (REG A) 0x2000)
(: loop)
   (SET (AT I 0x2000) (AT A))
   (SUB (REG I) 1)
   (IFN (REG I) 0)
   (SET PC (# loop))

(SET (REG X) 0x4)
(JSR (# testsub))
(SET PC (# crash))

(: testsub)
   (SHL (REG X) 4)
   (SET PC POP)

(: crash)
   (SET PC (# crash))
