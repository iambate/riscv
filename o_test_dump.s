addi	sp,sp,-32 #0
sd	s0,24(sp) #4
addi	s0,sp,32  #8
sw	zero,-20(s0) #c
jal	zero,38 #<.L2> #10
lw	a5,-20(s0) #14
slli	a5,a5,0x2   #18
addi	a4,s0,-16   #1c
add	a5,a4,a5    #20
addi	a4,zero,10   #24
sw	a4,-16(a5)  #28
lw	a5,-20(s0) #2c
addiw	a5,a5,1 #30
sw	a5,-20(s0) #34
lw	a4,-20(s0)  #38
addi	a5,zero,1  #3c
bge	a5,a4,14 #<.L3>
addi	a5,zero,0
addi	a0,a5,0
ld	s0,24(sp)
scall
ld	a6,24(sp)
addi	sp,sp,32
jalr	zero,0(ra)
