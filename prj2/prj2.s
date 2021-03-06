!************************************************************************!
!									 !
! general calling convention:						 !
!									 !
! (1) Register usage is as implied in the assembler names		 !
!									 !
! (2) Stack convention							 !
!									 !
!	  The stack grows towards higher addresses.  The stack pointer	 !
!	  ($sp) points to the next available (empty) location.		 !
!									 !
! (3) Mechanics								 !
!									 !
!	  (3a) Caller at call time:					 !
!	       o  Write any caller-saved stuff not saved at entry to	 !
!		  space on the stack that was reserved at entry time.	 !
!	       o  Do a JALR leaving the return address in $ra		 !
!									 !
!	  (3b) Callee at entry time:					 !
!	       o  Reserve all stack space that the subroutine will need	 !
!		  by adding that number of words to the stack pointer,	 !
!		  $sp.							 !
!	       o  Write any callee-saved stuff ($ra) to reserved space	 !
!		  on the stack.						 !
!	       o  Write any caller-saved stuff if it makes sense to	 !
!		  do so now.						 !
!									 !
!	  (3c) Callee at exit time:					 !
!	       o  Read back any callee-saved stuff from the stack ($ra)	 !
!	       o  Deallocate stack space by subtract the number of words !
!		  used from the stack pointer, $sp			 !
!	       o  return by executing $jalr $ra, $zero.			 !
!									 !
!	  (3d) Caller after return:					 !
!	       o  Read back any caller-saved stuff needed.		 !
!									 !
!************************************************************************!

!vector table
 vector0: .fill 0x00000000 !0
 .fill 0x00000000 !1
 .fill 0x00000000 !2
 .fill 0x00000000
 .fill 0x00000000 !4
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !8
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !15
!end vector table


main:
	addi $sp, $zero, initsp ! initialize the stack pointer
	lw $sp, 0($sp)
				! Install timer interrupt handler into the vector table
	addi $a0, $zero, ti_inthandler	! place the address of ti_inthandler into $t0
	addi $a1, $zero, 1	
	sw $a0, 0($a1)
	ei 			! Don't forget to enable interrupts...

		
	addi $a0, $zero, 2	! load base for pow
	addi $a1, $zero, 1	! load power for pow
	addi $at, $zero, POW	! load address of pow
	jalr $at, $ra		! run pow
		
	halt	
		
		

POW: 
	addi $sp, $sp, 2   	! push 2 slots onto the stack
	sw $ra, -1($sp)   	! save RA to stack
	sw $a0, -2($sp)   	! save arg 0 to stack
	beq $zero, $a1, RET1 	! if the power is 0 return 1
	beq $zero, $a0, RET0 	! if the base is 0 return 0
	addi $a1, $a1, -1  	! decrement the power
	la $at, POW		! load the address of POW
	jalr $at, $ra   	! recursively call POW
	add $a1, $v0, $zero  	! store return value in arg 1
	lw $a0, -2($sp)   	! load the base into arg 0
	la $at, MULT		! load the address of MULT
	jalr $at, $ra   	! multiply arg 0 (base) and arg 1 (running product)
	lw $ra, -1($sp)   	! load RA from the stack
	addi $sp, $sp, -2  	! pop the RA and arg 0 off the stack
	jalr $ra, $zero   	! return
RET1: 	addi $v0, $zero, 1  	! return a value of 1
	addi $sp, $sp, -2
	jalr $ra, $zero
RET0: 	add $v0, $zero, $zero 	! return a value of 0
	addi $sp, $sp, -2
	jalr $ra, $zero		
	
MULT: 	add $v0, $zero, $zero 	! zero out return value
AGAIN: 	add $v0,$v0, $a0  	! multiply loop
  	addi $a1, $a1, -1
  	beq $a1, $zero, DONE 	! finished multiplying
  	beq $zero, $zero, AGAIN	! loop again
DONE: 	jalr $ra, $zero	
		
		
ti_inthandler:
	addi $sp, $sp, 14	! increase stack pointer by 14 (don't need to save $zero or $sp) and one more in case something was at the old $sp
	sw $at, 0($sp)		! save all of the registers
	sw $v0, -1($sp)
	sw $a0, -2($sp)
	sw $a1, -3($sp)
	sw $a2, -4($sp)
	sw $a3, -5($sp)
	sw $a4, -6($sp)
	sw $s0, -7($sp)
	sw $s1, -8($sp)
	sw $s2, -9($sp)
	sw $s3, -10($sp)
	sw $k0, -11($sp)
	sw $fp, -12($sp)
	sw $ra, -13($sp)
	ei
	addi $a2, $zero, seconds
	lw $a0, 0($a2)		! load the current second counter into $t0
	addi $a0, $a0, 1	! increment the counter
	addi $a1, $zero, 60	! set $t1 to 60 (to check for minutes)
	beq $a0, $a1, MINUTE	! go to minutes if needed
	sw $a0, 0($a2)		! save the seconds
	beq $zero, $zero, EXIT

MINUTE:	add $a0, $zero, $zero	! set the seconds to 0
	sw $a0, 0($a2)		! save the seconds
	lw $a0, 1($a2)		! get the number of minutes
	addi $a0, $a0, 1	! increment the minutes
	beq $a0, $a1, HOUR	! go to hours if needed
	sw $a0, 1($a2)		! save the minutes
	beq $zero, $zero, EXIT
	
HOUR:	add $a0, $zero, $zero	! set the minutes to 0
	sw $a0, 1($a2)		! save the minutes
	lw $a0, 2($a2)		! get the number of hours
	addi $a0, $a0, 1	! increment the hours 
	sw $a0, 2($a2)		! save the hours

EXIT:	lw $at, 0($sp)		! load all of the registers back
	lw $v0, -1($sp)
	lw $a0, -2($sp)
	lw $a1, -3($sp)
	lw $a2, -4($sp)
	lw $a3, -5($sp)
	lw $a4, -6($sp)
	lw $s0, -7($sp)
	lw $s1, -8($sp)
	lw $s2, -9($sp)
	lw $s3, -10($sp)
	lw $k0, -11($sp)
	lw $fp, -12($sp)
	lw $ra, -13($sp)
	addi $sp, $sp, -14	! set the stack pointer back to where it was
	reti			! go back to the program
	
initsp: .fill 0xA00000
seconds: .fill 0xFFFFC
minutes: .fill 0xFFFFD
hours: .fill 0xFFFFE
