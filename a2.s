addi a7, zero, 1024
add a7, a7, a7 #2048
add a7, a7, a7 #4096
add a7, a7, a7 #8192
add a7, a7, a7 #16384
add a7, a7, a7 #32K
addi a6, zero, 7
sb a6, 0(a7)
add a1, a7, a7 #64K
# Start store
addi a6, zero, 6
sb a6, 0(a1)
addi a6, zero, 127
sb a6, 1(a1)
addi a6, zero, 126
sb a6, 2(a1)
addi a6, zero, 125
sb a6, 3(a1)
addi a6, zero, 124
sb a6, 4(a1)
addi a6, zero, 123
sb a6, 5(a1)
addi a6, zero, 122
sb a6, 6(a1)
addi a6, zero, -128
sb a6, 7(a1)
addi a6, zero, -1
sb a6, 8(a1)
add a2, a1, a1 #128K
addi a6, zero, 5
sb a6, 0(a2)
lb a5, 0(a7)
add a5, a5, a5
lb a5, 0(a2)
add a5, a5, a5
lb a5, 0(a1)
add a5, a5, a5
lb a5, 1(a1)
add a5, a5, a5
lb a5, 2(a1)
add a5, a5, a5
lb a5, 3(a1)
add a5, a5, a5
lb a5, 4(a1)
add a5, a5, a5
lb a5, 5(a1)
add a5, a5, a5
lb a5, 6(a1)
add a5, a5, a5
lb a5, 7(a1)
addi a5, a5, 128
lb a5, 8(a1)
addi a5, a5, 123
lbu a5, 8(a1)
addi a5, a5, 123
ret
