##############################################################
# Homework #3
# name: Shane McPhillips
# sbuid: mcphs28
##############################################################

#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1

smiley_eCoords: .word 2, 3, 3, 3, 2, 6, 3, 6
smiley_eC_Size: .word 8
smiley_sCoords: .word 6, 2, 7, 3, 8, 4, 8, 5, 7, 6, 6, 7
smiley_sC_Size: .word 12

readBuffer: .space 1024 #100 bytes allocated.
readBufferSize: .word 1024

load_map_bCoords: .space 792 #792 bytes reserved for 99 Coords (198 numbers), 4-bit integers
load_map_bC_Count: .word 0 #Counter for coords

newLine: .asciiz "\n"

#####_COLORS_#######
.eqv BLACK 0x00
.eqv RED 0X01
.eqv GREEN 0x02
.eqv BROWN 0x03
.eqv BLUE 0x04
.eqv MAGENTA 0x05
.eqv CYAN 0x06 
.eqv GRAY 0x07
.eqv DARK_GRAY 0x08 
.eqv BRIGHT_RED 0x09 
.eqv BRIGHT_GREEN 0x0A 
.eqv YELLOW 0x0B 
.eqv BRIGHT_BLUE 0x0C 
.eqv BRIGHT_MAGENTA 0x0D 
.eqv BRIGHT_CYAN 0x0E 
.eqv WHITE 0x0F
###################

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

.macro printIntReg(%i)
	li $v0, 1
	move $a0, %i
	syscall
.end_macro

.macro updateCellDisplay(%row, %col, %char, %color)
	li $v0, 20
	mul $a0, $v0, %row # a0 = row * 20
	sll $a1, %col, 1 #a1 = col * 2
	
	add $a2, $a0, $a1 #offset
	lui $a0, 0xFFFF #a0 = 0xFFFF0000
	add $a1, $a0, $a2 #0xFFFF00{ + [offset]}
	
	sb %char, 0($a1)
	sb %color, 1($a1)
	
.end_macro

#row = row
#col = column
#stop index is when the loop reaches the end
#start is where to start searching in the loop
#isRepeat = 0 when false, 1 when true
.macro isCoordRepeat(%row, %col, %stopIndex, %startIndex, %isRepeat)
	
	move $v0, %startIndex
	la $v1, load_map_bCoords
	sll $a0, $v0, 2
	add $a0, $v1, $a0
	isCoordRepeatLoop:
		bge $v0, %stopIndex, isCoordRepeat_Done
		lw $a1, 0($a0)
		bne %row, $a1, isCoordRepeatLoopInc
		lw $a1, 4($a0)
		bne %col, $a1, isCoordRepeatLoopInc
		
		addi %isRepeat, $0, 1 #isRepeat = true
		j isCoordRepeat_Done
		isCoordRepeatLoopInc:
			addi $v0, $v0, 2 #v0 += 2
			addi $a0, $a0, 8 #a0 += 8
			j isCoordRepeatLoop
	isCoordRepeat_Done:
.end_macro

.macro addBombCountToCell(%addressOffset)
	
	lb $v0, (%addressOffset) #Get cell info byte
	andi $v1, $v0, 0xF #byte AND 0000 1111 will give us first four bytes
	
	#Increase bomb count by 1
	addi $v1, $v1, 1
	
	li $a0, 0xF0 #1111 0000
	and $a0, $a0, $v0 #a0 now = second half byte of v0
	
	or $a1, $a0, $v1
	
	sb $a1, (%addressOffset) #Store info back into cell
.end_macro

.macro setColor(%bgVal, %fgVal, %color)
	
	li $a0 %bgVal #Using arg0 as temp
	li $a1, %fgVal #Using arg1 as temp
	bindColorValues($a0, $a1, %color)
.end_macro

.macro bindColorValues(%bgReg, %fgReg, %color)
	
	move $a0, %bgReg
	move $a1, %fgReg
	sll $a2, $a0, 4 #Background value is multiplied by 16 so it is now within the high order bits.
	
	andi $a2, $a2, 0xF0 #Clear out bg low-order bits for fg.
	andi $a1, $a1, 0x0F #Clear out fg high-order bits for bg.
	
	or %color, $a2, $a1 #%color = [bg - 4bits][fg - 4bits] (Combined value)
.end_macro
#place any additional data declarations here

#############################################
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
    setColor(BLACK, WHITE, $s2)
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
    		updateCellDisplay($t0, $t1, $s1, $s2)
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
    	setColor(YELLOW, GRAY, $s2)
    	
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
    		
    		updateCellDisplay($t4, $t5, $s1, $s2)
    		
    		addi $t0, $t0, 2
    		j s_drawEyes
    	s_beginDrawMouth:
    		li $s1, 'E'
    		setColor(RED, WHITE, $s2)
    	
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
    		
    			updateCellDisplay($t4, $t5, $s1, $s2)
    		
    			addi $t0, $t0, 2
    		j s_drawMouth
    s_done:
    jr $ra

##############################
# PART 2 FUNCTIONS
##############################

open_file:
    #Define your code here
    #a0 = fileName/location
    #$v0 = file descriptor return
    
    li $v0, 13 #Number for open file operation
    li $a1, 0 #flag: open file for read only
    li $a2, 0 #Mode ignored.
    syscall
    
    #$v0 = return value from open file
    jr $ra

close_file:
    #Define your code here
    #a0 = file descriptor to close.
    
    li $v0, 16 #number for closing a file.
    syscall
    jr $ra
    
load_map:
    #Define your code here
    #a0 = file descriptor
    #a1 = cells_array
    
    #$s0 = return address
    #s1 = readBuffer char array base address
    #s2 = $v0 from read_file
    #s5 = cells array
    move $s0, $ra
    move $s5, $a1
    
    #For reading in a file
    la $a1, readBuffer
    lw $a2, readBufferSize
    
    li $v0, 14
    syscall
    #v0 contains number of chars read, 0 if eof.
    
    move $s1, $a1
    move $s2, $v0 #s2 contains previous v0
    
    li $v0, 4
    move $a0, $s1
    syscall
    
    li $v0, 1
    move $a0, $s2
    syscall
    
    
    #######################
    #Processing File Data #
    #######################
    #s1 = address of readBuffer
    #t1 = char at index
    #t2 = current coord (not pair)
    #s3 = address of bomb coords array
    #s4 = bomb coord number counter (Remember to divide by 2 Later)
    #s5 = cells_array
    
    lbu $t1, 0($s1) #load first char
    
    la $s3, load_map_bCoords
    add $s4, $0, $0 #Bomb coords size
    
    li $v0, 0xD #Carriage return
    li $v1, 0xA #New Line
    li $a0, 0x20 #Space
    li $a1, 0x9 #Tab
    li $a2, 0x30 #0
    li $a3, 0x39 #9
    	
    load_map_buffer_values:
    	#t1 = char to process.
    	beqz $t1, lm_processCoords
    	
    	#Switch statement
    	lm_valueCR:
    		bne $t1, $v0, lm_valueNL
    		j load_map_loopInc #continue
    	lm_valueNL:
    		bne $t1, $v1, lm_valueSP
    		j load_map_loopInc #continue
    	lm_valueSP:
    		bne $t1, $a0, lm_valueTB
    		j load_map_loopInc #continue
    	lm_valueTB:
    		bne $t1, $a1, lm_valueNUM
    		j load_map_loopInc #continue
    	lm_valueNUM:
    		blt $t1, $a2, lm_valueInvalid
    		bgt $t1, $a3, lm_valueInvalid
    		
    		#Turn into number
    		addi $t2, $t1, -0x30 #0x30 is starting number for char of '0'
    		
    		sw $t2, 0($s3) #Store number thats in t2 into bomb coord array
    		addi $s3, $s3, 4 #Increment by 4 because it is word
    		addi $s4, $s4, 1 #Increase bomb coord size
    		
    		#Increment and go back to beginning
    		j load_map_loopInc
    	lm_valueInvalid:
    	j load_map_invalid #Go to error return.
    	
    load_map_loopInc:
    	addi $s1, $s1, 1#address index++
    	lbu $t1, ($s1) #Load next character
    	j load_map_buffer_values #Jump back to loop.
    load_map_invalid:
    	li $v0, -1 #Invalid data file
    	j load_map_finished	
    lm_processCoords:
    	
    	printNewLine()
    	printIntReg($s4)
    	printNewLine()
    	
    	#Check if bomb coord size ($s4) is greater than 0
    	blez $s4, load_map_invalid
    	li $v0, 198 #Max size for coord array
    	bgt $s4, $v0, load_map_invalid
    	andi $v0, $s4, 1 #will return 1 if odd
    	beq $v0, 1, load_map_invalid
    	
    	#Loop through every 2 coord numbers.
    	
    	add $t0, $0, $0 #t0 = indexer
    	la $s3, load_map_bCoords
    	#s3 = base address of word array
    	#s4 = size
    	
    	processCoords_loop:
    		bge $t0, $s4, processCoords_setAdjacentBombs
    		
    		#t1 = row, t2 = col
    		lw $t1, 0($s3)
    		lw $t2, 4($s3)
    		
    		addi $t0, $t0, 2
    		addi $s3, $s3, 8
    		
    		li $t3, 0 #isRepeat
    		
    		#Macro defined to help check if coordinate is repeated in array
    		#t1 = row, $t2 = col, $s4 = index to end at, $t0 = index to begin at, $t3 = isRepeating
    		isCoordRepeat($t1, $t2, $s4, $t0, $t3)#Returns 1 if coord pair is repeated, if 1, ignore
    		beq $t3, 1, processCoords_loop
    		
    		li $v0, 10 #To multiply t1 with
    		mul $t1, $t1, $v0 #t1 *= 10
    		
    		#offset in cell_array
    		add $t1, $t1, $t2 #(row*10) += col;
    		#Address offset of cell_array[i]
    		add $t2, $t1, $s5 #s5 = cell_array
    		
    		li $v0, 0
    		ori $v0, $v0, 0x20 #bomb will be 2^5 bit
    		
    		sb $v0, ($t2) #cells_array[index] = v0 = 0x100000
    		
    		j processCoords_loop
    			
    	processCoords_setAdjacentBombs:
    		
    		#s5 = cells_array base address
    		#t0 = row = 0
    		#t1 = col = 0
    		
    		add $t0, $0, $0
    		addi $t2, $0, 9
    		pc_searchCells_loop_o:
    			bgt $t0, $t2, pc_searchCells_finished
    			
    			add $t1, $0, $0 #Reset column to 0
    			pc_searchCells_loop_i:
    				bgt $t1, $t2, pc_searchCells_loop_o_inc
    				
    				li $t6, 10 #multiply row by 10
    				mul $t6, $t6, $t0
    				
    				add $t6, $t6, $t1 #t6 = offset = (row*10) + col;
    				
    				add $t3, $t6, $s5 #address + offset = cells_array[row,col]
    				
    				#Check if cell is a bomb
    				lb $t4, 0($t3) #Cell data
    				andi $t5, $t4, 0x20 #BIN:100000
    				
    				#If t5 = 0x20, is bomb.
    				bne $t5, 0x20, pc_searchCells_loop_i_inc #If not a bomb, keep searching
    				
    				#Is bomb
				
				#t0 = row
				#t1 = col
				#t3 = cell_array - address offset
				bombCellRow0:
					bnez $t0, bombCellRow9
		
					bombCell0Col0:
						bnez $t1, bombCell0Col9
			
						#Allowed Checks: Down, Right, RDA
						
						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
						addi $t4, $t3, 11 #RDA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
			
					bombCell0Col9:
						bne $t1, 9, bombCell0ColDef
			
						#Allowed Checks: Down, Left, LDA
						
						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
						addi $t4, $t3, 9 #LDA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
					bombCell0ColDef:
			
						#Allowed Checks: Left, Right, LDA, Down, RDA
						
						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
						addi $t4, $t3, 9 #LDA
						addBombCountToCell($t4)
						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
						addi $t4, $t3, 11 #RDA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
				bombCellRow9:
					bne $t0, 9, bombCellRowDef
					bombCell9Col0:
						bnez $t1, bombCell9Col9
			
						#Allowed Checks: UP, RIGHT, RUA
						
						addi $t4, $t3, -10 #Up
						addBombCountToCell($t4)
						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
						addi $t4, $t3, -9 #RUA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
					bombCell9Col9:
						bne $t1, 9, bombCell9ColDef
			
						#Allowed Checks: LUA, UP, LEFT
						
						addi $t4, $t3, -10 #Up
						addBombCountToCell($t4)
						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
						addi $t4, $t3, -11 #LUA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
					bombCell9ColDef:
			
						#Allowed Checks: LUA, UP, RUA, LT, RT
						
						addi $t4, $t3, -11 #LUA
						addBombCountToCell($t4)
						addi $t4, $t3, -10 #UP
						addBombCountToCell($t4)
						addi $t4, $t3, -9 #RUA
						addBombCountToCell($t4)
						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
				bombCellRowDef:
		
					bombCellDefCol0:
						bnez $t1, bombCellDefCol9
			
						#Allowed Checks: UP, RUA, RIGHT, DOWN, RDA
						
						addi $t4, $t3, -10 #Up
						addBombCountToCell($t4)
						addi $t4, $t3, -9 #RUA
						addBombCountToCell($t4)
						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
						addi $t4, $t3, 11 #RDA
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
					bombCellDefCol9:
						bne $t1, 9, bombCellDefColDef
			
						#Allowed Checks: LUA, UP, LEFT, LDA, DOWN
						
						addi $t4, $t3, -11 #LUA
						addBombCountToCell($t4)
						addi $t4, $t3, -10 #UP
						addBombCountToCell($t4)
						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
						addi $t4, $t3, 9 #LDA
						addBombCountToCell($t4)
						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
						j pc_searchCells_loop_i_inc
						
					bombCellDefColDef:
			
						#Allowed Checks: ALL
						addi $t4, $t3, -10 #Up
						addBombCountToCell($t4)
    						addi $t4, $t3, 10 #Down
						addBombCountToCell($t4)
    						addi $t4, $t3, -1 #Left
						addBombCountToCell($t4)
    						addi $t4, $t3, 1 #Right
						addBombCountToCell($t4)
    						addi $t4, $t3, -11 #LUA
						addBombCountToCell($t4)
    						addi $t4, $t3, -9 #RUA
						addBombCountToCell($t4)
						addi $t4, $t3, 9 #LDA
						addBombCountToCell($t4)
    						addi $t4, $t3, 11 #RDA
						addBombCountToCell($t4)
    						j pc_searchCells_loop_i_inc
    						
    			pc_searchCells_loop_i_inc:
    				addi $t1, $t1, 1 #Increment column
    				j pc_searchCells_loop_i #Jump back to inner loop start
    			pc_searchCells_loop_o_inc:
    				addi $t0, $t0, 1 #Increment row
    				j pc_searchCells_loop_o #Go back to outer-loop
    		pc_searchCells_finished:
    		
    			#Now since we are finished, init cursor vars to 0
    			sw $0, cursor_row #row = 0
    			sw $0, cursor_col #col = 0
    			
    			j load_map_finished
    		
    load_map_finished:
    	move $ra, $s0
    	jr $ra

##############################
# PART 3 FUNCTIONS
##############################

init_display:
    
    #Loop through all cell displays and set to hidden.
    
    #t0 = row, t1 = col, t2 = 10 (Whjere to stop loop)
    #char = null_char
    #color {bg = gf = gray}
    li $s0, '\0'
    setColor(GRAY, GRAY, $s1)
    add $t0, $0, $0 #t0 = 0
    addi $t2, $0, 10 #t2 = 10
    init_display_outer_loop:
    	beq $t0, $t2, init_display_setCursor
    	
    	#Init col = t1 = 0
    	add $t1, $0, $0
    	init_display_inner_loop:
    		beq $t1, $t2, init_display_outer_incr
		
		#t0 = row, t1 = col
		#Set display to hidden cell color
		updateCellDisplay($t0, $t1, $s0, $s1) #row, col, char, color
		
		#Increment the inner loop
		addi $t1, $t1, 1 #Increment column by 1
		j init_display_inner_loop
	init_display_outer_incr:
		#Increment the outer loop
		addi $t0, $t0, 1 #Increment row by 1
		j init_display_outer_loop
    init_display_setCursor:
    	
    	#Cursor cell-pos will have a yellow bg and gray fg, char still $s0
    	
    	setColor(YELLOW, GRAY, $s1)
    	lw $t0, cursor_row #t0 = crow
    	lw $t1, cursor_col #t1 = ccol
    	
    	updateCellDisplay($t0, $t1, $s0, $s1) #row,col,char,color
    	j init_display_exit
    init_display_exit:
    	jr $ra

set_cell:
    
    #a0 = row
    #a1 = col
    #a2 = char
    #a3 = fg
    #0($sp) = bg (load the byte not the word)
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    lb $s4, 0($sp)
    
    #Param checks:
    
    # 0 <= row <= 9
    bltz $s0, set_cell_invalid
    bgt $s0, 9, set_cell_invalid
    # 0 <= col <= 9
    bltz $s1, set_cell_invalid
    bgt $s1, 9, set_cell_invalid
    # 0 <= bg <= 15
    bltz $s4, set_cell_invalid
    bgt $s4, 15, set_cell_invalid
    # 0 <= fg <= 15
    bltz $s3, set_cell_invalid
    bgt $s3, 15, set_cell_invalid
    
    #s5 = color (bg & fg)
    bindColorValues($s4, $s3, $s5) #bg, fg, color
    
    #Update the display with the new display info
    updateCellDisplay($s0, $s1, $s2, $s5) #row, col, char, color
    
    add $v0, $0, $0 #Successful return
    j set_cell_exit
    
    set_cell_invalid:
    	addi $v0, $0, -1 #Invalid return
    	j set_cell_exit
    
    set_cell_exit:
    	jr $ra

reveal_map:
    
    #s0 = return address
    #s1 = a0 = game_status(1,0,-1)
    #s2 = a1 = cells_array pointer
    move $s0, $ra
    move $s1, $a0
    move $s2, $a1
    
    #Check game status:
    bgtz $s1, reveal_map_win #Go to smiley if game status is = 1
    beqz $s1, reveal_map_inProg #Exit reveal map function, the game is still in progress. game status = 0
    bltz $s1, reveal_map_loss #Go to map reveal if game status = -1
    
    reveal_map_win:
    	#Only need to save $s0
    	addi $sp, $sp, -4
    	sw $s0, 0($sp) #Store saved return address.
    	
    	#Jump to smiley function
    	jal smiley
    	
    	lw $s0, 0($sp) #Load the saved return address.
    	addi $sp, $sp, 4
    	j reveal_map_exit
    	
    reveal_map_inProg:
    	#Do nothing, just exit function
    	j reveal_map_exit
    
    reveal_map_loss:
    	
    	#Place exploded bomb at cursor location
    	#Red background, white foreground
    	lw $a0, cursor_row #Load row
    	lw $a1, cursor_col #Load col
    	li $a2, 'E' #Explosion character
    	li $a3, BRIGHT_RED
    	addi $sp, $sp, -4
    	sw $a3, 0($sp) #Store background value on stack
    	li $a3, WHITE
    	
    	#Set the cells display
    	jal set_cell
    	
    	addi $sp, $sp, 4
    	
    	#t0 = row, t1 = col
    	rm_outer_loop:
    		
    		rm_inner_loop:
    		
    		
    		
    		
    		
    		rm_outer_loop_inc:
    	
    	rm_loop_end:
    reveal_map_exit:
    	move $ra, $s0 #Take back return address pointer from saved pointer
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

#####################################################################

