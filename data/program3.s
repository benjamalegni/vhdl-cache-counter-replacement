.data 
num0: .word 1 # posic 0
num1: .word 2 # posic 4
num2: .word 4 # posic 8 
num3: .word 8 # posic 12 
num4: .word 16 # posic 16 
num5: .word 20 # posic 20
num6: .word 24 # posic 24
num7: .word 10 # posic 28
num8: .word 20 # posic 32
num9: .word 30 # posic 36
num10: .word 40 # posic 40
num11: .word 50 # posic 44
num12: .word 60 # posic 32
num13: .word 70 # posic 36
num14: .word 80 # posic 40
num15: .word 0 # posic 44
.text 
main:
  lw $t0, 0($zero) 
  lw $t1, 4($zero) 
  lw $t2, 8($zero) 
  lw $t3, 12($zero)
  lw $t4, 16($zero)
  lw $t5, 20($zero)
  lw $t6, 24($zero)
  lw $t7, 28($zero)
  sw $t0, 64($zero)
  sw $t1, 68($zero)
  sw $t2, 72($zero)
  sw $t3, 76($zero)
  sw $t4, 80($zero)
  sw $t5, 84($zero)
  sw $t6, 88($zero)
  sw $t7, 92($zero)
  lw $t0, 32($zero) 
  lw $t1, 36($zero) 
  lw $t2, 40($zero) 
  lw $t3, 44($zero)
  lw $t4, 48($zero)
  lw $t5, 52($zero)
  lw $t6, 56($zero)
  lw $t7, 60($zero) 
  sw $t0, 96($zero)
  sw $t1, 100($zero)
  sw $t2, 104($zero)
  sw $t3, 108($zero)
  sw $t4, 112($zero)
  sw $t5, 116($zero)
  sw $t6, 120($zero)
  sw $t7, 124($zero)
  lw $t0, 64($zero)
  lw $t1, 96($zero)
  add $s0, $t0, $t1
  lw $t0, 68($zero)
  lw $t1, 100($zero)
  add $s1, $t0, $t1
  lw $t0, 72($zero)
  lw $t1, 104($zero)
  add $s2, $t0, $t1
  lw $t0, 76($zero)
  lw $t1, 108($zero)
  add $s3, $t0, $t1
  lw $t0, 80($zero)
  lw $t1, 112($zero)
  add $s4, $t0, $t1
  lw $t0, 84($zero)
  lw $t1, 116($zero)
  add $s5, $t0, $t1
  lw $t0, 88($zero)
  lw $t1, 120($zero)
  add $s6, $t0, $t1
  lw $t0, 92($zero)
  lw $t1, 124($zero)
  add $s7, $t0, $t1
  sw $s0, 0($zero)
  sw $s1, 4($zero)
  sw $s2, 8($zero)
  sw $s3, 12($zero)
  sw $s4, 16($zero)
  sw $s5, 20($zero)
  sw $s6, 24($zero)
  sw $s7, 28($zero)
  lw $t0, 0($zero)
  lw $t1, 32($zero)
  add $s0, $t0, $t1
  lw $t0, 4($zero)
  lw $t1, 36($zero)
  add $s1, $t0, $t1
  lw $t0, 8($zero)
  lw $t1, 40($zero)
  add $s2, $t0, $t1
  lw $t0, 12($zero)
  lw $t1, 44($zero)
  add $s3, $t0, $t1
  lw $t0, 16($zero)
  lw $t1, 48($zero)
  add $s4, $t0, $t1
  lw $t0, 20($zero)
  lw $t1, 52($zero)
  add $s5, $t0, $t1
  lw $t0, 24($zero)
  lw $t1, 56($zero)
  add $s6, $t0, $t1
  lw $t0, 28($zero)
  lw $t1, 60($zero)
  add $s7, $t0, $t1
  sw $s0, 192($zero)
  sw $s1, 196($zero)
  sw $s2, 200($zero)
  sw $s3, 204($zero)
  sw $s4, 208($zero)
  sw $s5, 212($zero)
  sw $s6, 216($zero)
  sw $s7, 220($zero)  
  lw $t0, 192($zero) 
  lw $t1, 196($zero) 
  lw $t2, 200($zero) 
  lw $t3, 204($zero)
  lw $t4, 208($zero)
  lw $t5, 212($zero)
  lw $t6, 216($zero)
  lw $t7, 220($zero)
  sw $t0, 160($zero)
  sw $t1, 164($zero)
  sw $t2, 168($zero)
  sw $t3, 172($zero)
  sw $t4, 176($zero)
  sw $t5, 180($zero)
  sw $t6, 184($zero)
  sw $t7, 188($zero)
  lw $t0, 0($zero)
  lw $t1, 4($zero)
  lw $t2, 8($zero)
  lw $t3, 12($zero)
  lw $t4, 16($zero)
  lw $t5, 20($zero)
  lw $t6, 24($zero)
  lw $t7, 28($zero)
  lw $s0, 160($zero)
  lw $s1, 164($zero)
  lw $s2, 168($zero)
  lw $s3, 172($zero)
  lw $s4, 176($zero)
  lw $s5, 180($zero)
  lw $s6, 184($zero)
  lw $s7, 188($zero)
  lw $t0, 64($zero)
  lw $t1, 68($zero)
  lw $t2, 72($zero)
  lw $t3, 76($zero)
  lw $t4, 80($zero)
  lw $t5, 84($zero)
  lw $t6, 88($zero)
  lw $t7, 92($zero)
  lw $s0, 96($zero)
  lw $s1, 100($zero)
  lw $s2, 104($zero)
  lw $s3, 108($zero)
  lw $s4, 112($zero)
  lw $s5, 116($zero)
  lw $s6, 120($zero)
  lw $s7, 124($zero)
end_program:
  j end_program
 
   
  
  

