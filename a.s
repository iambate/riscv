addi a6, zero, -32
addi a7, zero, 1024
add a7, a7, a7 #2048
add a7, a7, a7 #4096
add a7, a7, a7 #8192
add a7, a7, a7 #16384
add a7, a7, a7 #32K
sd a6, 0(a7)
ld a5, 0(a7)
add a4, a5, 64
ret
