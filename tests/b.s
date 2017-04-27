addi	a7,x0,1024
add	a7,a7,a7
add	a7,a7,a7
add	a7,a7,a7
add	a7,a7,a7 #a7=16384 tag=1
add	a7,a7,a7 #a7=32768 tag=1
sd	ra,0(a7) #index 0
lw      a4,0(x0) #index 0
sw	ra,0(a7)
ret
