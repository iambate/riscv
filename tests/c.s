addi    a7,x0,1024
add     a7,a7,a7
add     a7,a7,a7
add     a7,a7,a7
add     a7,a7,a7 #a7=16384 tag=1
add     a7,a7,a7 #a7=32768 tag=1
addi    ra,x0,1113
sd      ra,0(a7) #store ra value at 32768
lb      a4,0(a7)
ret
