##############################################################
# Homework #3
# name: MY_NAME
# sbuid: MY_SBU_ID
##############################################################
.data

baseAddress: .word 0xFFFF0000 #Start of MMIO memory section. (0xFFFF0000 -> 0xFFFF00C7)

smiley_eCoords: .word 2, 3, 3, 3, 2, 6, 3, 6
smiley_eC_Size: .word 8
smiley_sCoords: .word 6, 2, 7, 3, 8, 4, 8, 5, 7, 6, 6, 7
smiley_sC_Size: .word 12

newLine: .asciiz "\n"

.macro printChar(%ch)
	li $v0, 11
	la $a0, %ch
	syscall
.end_macro

.macro printNewLine()
	li $v0, 4
	la $a0, newLine
	syscall
.end_macro

.macro printString(%str)
	li $v0, 4
	move $a0, %str
	syscall
.end_macro

.macro printInt(%i)
	li $v0, 1
	la $a0, %i
	syscall
.end_macro

.macro updateCell(%row, %col, %char, %color)
	
	move $a0, %row
	move $a1, %col
	
	li $v0, 20
	mul $a0, $a0, $v0 #a0(row) * 20
	sll $a1, $a1, 1 #a1(col) * 2
	
	add $v0, $a0, $a1
	lui $v1, 0xFFFF #0xFFFF0000
	add $v0, $v0, $v1 #0xFFFF0000 + [offset]
	
	sb %char, 0($v0)
	sb %color, 1($v0) 
.end_macro

.text
##############################
# PART 1 FUNCTIONS
##############################

smiley:
    #Define your code here
    #s0 = $ra
    move $s0, $ra
    
    #Reset all cells to black background white foreground, null char
    #######################################
    #s1 = null char
    #s2 = background/foreground color byte
    li $s1, '\0'
    li $s2, 0xF
    ############################
    
    
    add $t0, $0, $0 #t0 = i = 0;
    #outside forloop (for(int i = 0; i <= 9; i++))
    s_rOuterLoop:
    	bgt $t0, 9, s_drawFace
    	
    	#inner loop (for(int j = 0; j <= 9; j++))
    	add $t1, $0, $0 #t1 = j = 0;
    	s_rInnerLoop:
    		bgt $t1, 9, s_rLIncrement #inner loop finished, increment outerloop and repeat.
    		#t0 = row, t1 = col
    		updateCell($t0, $t1, $s1, $s2)
    		#increment and repeat
    		addi $t1, $t1, 1 #t1 = j++;
    		j s_rInnerLoop
    s_rLIncrement:
    	addi $t0, $t0, 1 #t0 = i++;
    	j s_rOuterLoop
    s_drawFace:
    	
    	#Draw Eyes
    	
    	#Yellow background 3,1 
    	#Gray foreground 7,0
    	#0xB7 = (((1*8) + 3) * 16) + 7 -> Hex
    	#Ascii BOMB 'B'
    	
    	li $s1, 'B'
    	li $s2, 0xB7 #Yellow/Gray
    	
    	add $t0, $0, $0
    	lw $t1, smiley_eC_Size
    	la $t2, smiley_eCoords
    	s_drawEyes:
    		beq $t0, $t1, s_beginDrawMouth
    		li $v0, 4
    		mul $t3, $t0, $v0
    		add $t3, $t3, $t2 #array address[i] 
    		
    		lw $t4, 0($t3)
    		lw $t5, 4($t3)
    		
    		updateCell($t4, $t5, $s1, $s2)
    		
    		addi $t0, $t0, 2
    		j s_drawEyes
    	s_beginDrawMouth:
    		li $s1, 'E'
    		li $s2, 0x1F #Red/White
    	
    		add $t0, $0, $0
    		lw $t1, smiley_sC_Size
    		la $t2, smiley_sCoords
    		s_drawMouth:
    			beq $t0, $t1, s_done
    			li $v0, 4
    			mul $t3, $t0, $v0
    			add $t3, $t3, $t2 #array address[i] 
    		
    			lw $t4, 0($t3)
    			lw $t5, 4($t3)
    		
    			updateCell($t4, $t5, $s1, $s2)
    		
    			addi $t0, $t0, 2
    		j s_drawMouth
    s_done:
    jr $ra

##############################
# PART 2 FUNCTIONS
##############################

open_file:
    #Define your code here
    
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ###########################################
    jr $ra

close_file:
    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ###########################################
    jr $ra

load_map:
    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ###########################################
    jr $ra

##############################
# PART 3 FUNCTIONS
##############################

init_display:
    #Define your code here
    jr $ra

set_cell:
    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ###########################################
    jr $ra

reveal_map:
    #Define your code here
    jr $ra


##############################
# PART 4 FUNCTIONS
##############################

perform_action:
    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ##########################################
    jr $ra

game_status:
    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    li $v0, -200
    ##########################################
    jr $ra

##############################
# PART 5 FUNCTIONS
##############################

search_cells:
    #Define your code here
    jr $ra


#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1

#place any additional data declarations here

