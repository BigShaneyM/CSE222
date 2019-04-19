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
.eqv GREY 0x07
.eqv DARK_GREY 0x08 
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
	move $a0, %ch
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
	move $a0, %i
	syscall
.end_macro

.macro printIntReg(%i)
	li $v0, 1
	move $a0, %i
	syscall
.end_macro

.macro getCellIndex(%row, %col, %index)
	li $a0, 10#temp
	mul %index $a0, %row #index = row*10
	add %index, %index, %col #index = row*10 + col
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

.macro printCoord(%row, %col)
	printNewLine()
	li $t9, 0x28
	printChar($t9)
	printInt(%row)
	li $t9, 0x2C
	printChar($t9)
	printInt(%col)
	li $t9, 0x29
	printChar($t9)
	printNewLine()
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
    	setColor(YELLOW, GREY, $s2)
    	
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
    setColor(GREY, GREY, $s1)
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
    	
    	setColor(YELLOW, GREY, $s1)
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
    	#BG - val must be saved on top of stack
    	#Save registers / place bg val for set_cell at first address on stack.
    	#s0 - return pointer / s2 - cell_arrays
    	addi $sp, $sp, -12 
    	sw $a3, 0($sp) #Store background value on stack
    	li $a3, WHITE
    	
    	#Save pointers below
    	sw $s0, 4($sp) #-save return pointer
    	sw $s2, 8($sp) #-save cells_array address
    	
    	#Set the cells display
    	jal set_cell
    	
    	#Load save registers
    	lw $s1, 8($sp) #Now using s1 as cells_array, no use of game status anymore.
    	lw $s0, 4($sp)
    	#No need to load back the bg-val
    	addi $sp, $sp, 12
    	
    	
    	#Loop through every cell in game and if hidden, show the cell display color-char
    	
    	#SAVED REGISTER LIST FROM HERE DOWN
    	#s0 - return
    	#s1 - cells_array
    	
    	#t0 = row, t1 = col, t2 = 10
    	add $t0, $0, $0 #t0 = 0
    	addi $t2, $0, 10 #t2 = 10 
    	rm_outer_loop:
    		beq $t0, $t2, rm_loop_end #Finished with loop.
    		add $t1, $0, $0, #Init t1(col)
    		rm_inner_loop:
    			beq $t1, $t2, rm_outer_loop_inc
    		
    			#t0 - row / t1 - col \ DON'T TOUCH T2 IN HERE
    			
    			#Get index in cell array
    			#- Multiply row by 10 - add col to the sum
    			li $t3, 10
    			mul $t3, $t0, $t3 #t3 = row*10
    			add $t3, $t3, $t1 #t3 = 10*row + col
    			add $t3, $t3, $s1 #t3 = cells_array + index
    			
    			#Get Game-Info byte
    			lb $t4, 0($t3) #t4 = *cells_array[index]
    			
			
    			
    			#Check for flag - Display bomb/flag -{correct(bomb at f pos) / incorrect(no bomb at f pos)}
    			andi $t5, $t4, 0x30
    			add $t6, $0, $0 #t6 = isBadFlag (0:false)
    			beq $t5, 0x30, rm_setFlag #If t5 = 0011 0000 flag placed at good spot
    			beq $t5, 0x10, rm_setFlagBad #If t5 = 0001 0000 flag placed at bad spot
    			
    			#Check for if shown
    			andi $t5, $t4, 0x40
    			beq $t5, 0x40, rm_inner_loop_inc #If it's already shown, no point in wasting time and memory
    			
    			#Check for bomb
    			andi $t5, $t4, 0x20
    			beq $t5, 0x20, rm_setBomb #If t5 = 0010 0000 only bomb
    			
    			#Display cell bomb number
    			andi $t5, $t4, 0x0F
    			beq $t5, 0x00, rm_setEmpty #If no bomb# data it must be empty
    			#t5 contains the number of bombs at the cell location
    			#Add +0x30 (0x30 in ascii is '0'
    			addi $t5, $t5, 0x30 #t5 now = ascii num
    			
    			#a0 - row, a1 - col, a2 - char, a3 - fg val, (sp) - bg val
    			move $a0, $t0
    			move $a1, $t1
    			move $a2, $t5 #Our char to display
    			li $a3, BLACK #bg val
    			addi $sp, $sp, -24 #6 reg to save and store
    			sw $a3, 0($sp) #Store bg-val
    			li $a3, BRIGHT_MAGENTA #fg-val
    			
    			#Save registers
    			sw $s0, 4($sp)
    			sw $s1, 8($sp)
    			sw $t0, 12($sp)
    			sw $t1, 16($sp)
    			sw $t2, 20($sp)
    			
    			jal set_cell
    			
    			lw $t2, 20($sp)
    			lw $t1, 16($sp)
    			lw $t0, 12($sp)
    			lw $s1, 8($sp)
    			lw $s0, 4($sp)
    			
    			addi $sp, $sp, 24 #Bring the stack back up
    			
    			#Finished with revealing cell, go to inc.
    			j rm_inner_loop_inc
    			
    			rm_setFlag:
    				move $a0, $t0 #row
    				move $a1, $t1, #col
    				li $a2, 'F' #Flag charatcer
    				
    				#t6 = isBadFlag
    				beqz $t6, setF_good
    				setF_bad:
    					li $a3, BRIGHT_RED #bg val
    					j bg_onStack
    				setF_good:
    					li $a3, BRIGHT_GREEN #bg val	
    					j bg_onStack
    				bg_onStack:
    					addi $sp, $sp, -24 #6 registers
    					sw $a3, 0($sp) #bg is first value on stack
    					li $a3, BRIGHT_BLUE #fg val
    					
    					#Save registers (5)
    					sw $s0, 4($sp)
    					sw $s1, 8($sp)
    					sw $t0, 12($sp)
    					sw $t1, 16($sp)
    					sw $t2, 20($sp)
    					
    					jal set_cell
    					
    					#Load saved-registers(5)
    					lw $t2, 20($sp)
    					lw $t1, 16($sp)
    					lw $t0, 12($sp)
    					lw $s1, 8($sp)
    					lw $s0, 4($sp)
    					addi $sp, $sp, 24
    					j rm_inner_loop_inc
    					
    			rm_setFlagBad:
    				addi $t6, $0, 1 #t6 = isBadFlag = true
    				j rm_setFlag		
    			
    			rm_setBomb:
    				#bg black, fg grey, ch = B
    				move $a0, $t0 #row
    				move $a1, $t1 #col
    				li $a2, 'B' #B for Bomb
    				li $a3, BLACK #bg val
    				addi $sp, $sp, -24 #6 registers to save total
    				sw $a3, 0($sp) #Store bg-val on stack
    				li $a3, GREY #a3 = fg-val
    				
    				#Save registers (5)
    				sw $s0, 4($sp)
    				sw $s1, 8($sp)
    				sw $t0, 12($sp)
    				sw $t1, 16($sp)
    				sw $t2, 20($sp)
    					
    				jal set_cell
    					
    				#Load saved-registers(5)
    				lw $t2, 20($sp)
    				lw $t1, 16($sp)
    				lw $t0, 12($sp)
    				lw $s1, 8($sp)
    				lw $s0, 4($sp)
    				addi $sp, $sp, 24
    				j rm_inner_loop_inc
    					
    			rm_setEmpty:
    				#ch = \0, bg = black, fg = white
    				move $a0, $t0 #row
    				move $a1, $t1 #col
    				li $a2, '\0' #Null Char
    				li $a3, BLACK
    				addi $sp, $sp, -24
    				sw $a3, 0($sp) #bg-val on stack
    				li $a3, WHITE #a3 = fg val now
    				
    				#Save registers (5)
    				sw $s0, 4($sp)
    				sw $s1, 8($sp)
    				sw $t0, 12($sp)
    				sw $t1, 16($sp)
    				sw $t2, 20($sp)
    					
    				jal set_cell
    					
    				#Load saved-registers(5)
    				lw $t2, 20($sp)
    				lw $t1, 16($sp)
    				lw $t0, 12($sp)
    				lw $s1, 8($sp)
    				lw $s0, 4($sp)
    				addi $sp, $sp, 24
    				j rm_inner_loop_inc
    				
    			rm_inner_loop_inc:
    				addi $t1, $t1, 1 #Increment -> col++
    			    	j rm_inner_loop	
    		rm_outer_loop_inc:
    			addi $t0, $t0, 1 #Increment -> row*10
    			j rm_outer_loop
    	rm_loop_end:
    		j reveal_map_exit
    reveal_map_exit:
    	move $ra, $s0 #Take back return address pointer from saved pointer
    	jr $ra

##############################
# PART 4 FUNCTIONS
##############################

perform_action:
    #a1 = user input char
    #a0 = cells_array
    move $s0, $ra
    move $s1, $a0 #cells_array
    move $s2, $a1 #user input
    
    #Load cursor values
    lw $t0, cursor_row
    lw $t1, cursor_col
    
    add $t2, $t0, $0 #previous row
    add $t3, $t1, $0 #previous col
    
    #Check user input
    #Check forward movement
    beq $s2, 0x57, pAction_forward #W
    beq $s2, 0x77, pAction_forward #w
    
    #Check backward movement
    beq $s2, 0x53, pAction_backward #S
    beq $s2, 0x73, pAction_backward #s
    
    #Check left movement
    beq $s2, 0x41, pAction_left #A
    beq $s2, 0x61, pAction_left #a
    
    #Check right movement
    beq $s2, 0x44, pAction_right #D
    beq $s2, 0x64, pAction_right #d
    
    #Check toggle flag
    beq $s2, 0x46, pAction_fToggle #F
    beq $s2, 0x66, pAction_fToggle #f
    
    #Check for toggle reveal
    beq $s2, 0x52, pAction_rToggle #R
    beq $s2, 0x72, pAction_rToggle #r
    
    pAction_forward:
    	beqz $t0, pAction_invalidMove
    	
    	#Set cursor to cursor_row - 1
    	addi $t0, $t0, -1
    	j pAction_updateCursor
    pAction_backward:
    	beq $t0, 9, pAction_invalidMove
    	
    	#Set cursor to cursor_row +1
    	addi $t0, $t0, 1
    	j pAction_updateCursor
    pAction_left:
    	beqz $t1, pAction_invalidMove
    	
    	#Set cursor to cursor_col - 1
    	addi $t1, $t1, -1
    	j pAction_updateCursor
    pAction_right:
    	beq $t1, 9, pAction_invalidMove
    	
    	#Set cursor to cursor_COL +1
    	addi $t1, $t1, 1
    	j pAction_updateCursor
    pAction_fToggle:
    		
    		#No use of t2 and t3
    		li $t2, 10 #temp
    		mul $t2, $t2, $t0 #row*10
    		add $t2, $t2, $t1 #row*10 + col = index
    		add $t3, $t2, $s1
    		
    		lb $t2, 0($t3) #cell_array[index] = game_data
    		
    		andi $t5, $t2, 0x40
    		beq $t5, 0x40, pAction_invalidMove #Check to make sure we arent trying to flag a revealed cell
    		
    		andi $t4, $t2, 0x10 #Wether flag is placed or not
    		andi $t5, $t2, 0x6F #Retrieve all bits except flag bit
    		beq $t4, 0x10, toggleFlagOff
    		j toggleFlagOn
    		
    		toggleFlagOn:
    			
    			ori $t6, $t5, 0x10 #Flag bit enabled
    			sb $t6, 0($t3)
    			#Set flag cell
    			
    			#GREY BACKGROUND BRIGHT_BLUE FOREGROUND 'F'
    			move $a0, $t0 #row
    			move $a1, $t1 #col
    			li $a2, 'F'
    			li $a3, GREY
    			addi $sp, $sp, -24
    			sw $a3, 0($sp) #bg-val
    			li $a3, BRIGHT_BLUE #fg-val
    			j f_set_cell_and_save
    		toggleFlagOff:
    			
    			sb $t5, 0($t3)
    			#set hidden cell
    			#GREY BACKGROUND BRIGHT_BLUE FOREGROUND 'F'
    			move $a0, $t0 #row
    			move $a1, $t1 #col
    			li $a2, '\0'
    			li $a3, YELLOW
    			addi $sp, $sp, -24
    			sw $a3, 0($sp) #bg-val
    			li $a3, GREY #fg-val
    			j f_set_cell_and_save
    		f_set_cell_and_save:
    			
    			sw $s0, 4($sp)
    			sw $s1, 8($sp)
    			sw $s2, 12($sp)
    			sw $t0, 16($sp)
    			sw $t1, 20($sp)
    			
    			jal set_cell
    			
    			lw $t1, 20($sp)
    			lw $t0, 16($sp)
    			lw $s2, 12($sp)
    			lw $s1, 8($sp)
    			lw $s0, 4($sp)
    			addi $sp, $sp, 24
    			add $v0, $0, $0
    			j pAction_exit
    			
    			
    pAction_rToggle:
    	
    	li $t2, 10 #temp
    	mul $t2, $t2, $t0 #row*10
    	add $t2, $t2, $t1 #row*10 + col
    	add $t2, $t2, $s1 #cells_array + offset
    	
    	lb $t3, 0($t2) #game_data
    	
    	andi $t4, $t3, 0x10
    	beq $t4, 0x10, rToggle_flagOff
    	
    	andi $t4, $t3, 0x80 #Check if shown
    	beq $t4, 0x80, pAction_invalidMove #Cant reveal an already revealed cell
    	
    	j rToggle_revealCell
    	
    	rToggle_flagOff:
    		andi $t4, $t3, 0x6F #Get all used bits except flag bit
    		sb $t4, 0($t2)
    		j rToggle_revealCell
    	rToggle_revealCell:
    		
    		andi $t4, $t3, 0xFF
    		ori $t4, $t4, 0x40
    		sb $t4, 0($t2)
    		
    		move $a0, $t0
    		move $a1, $t1
    		
    		andi $t4, $t3, 0x10 #Check if flag
    		beq $t4, 0x10, rToggle_revealCell_f
    		
    		andi $t4, $t3, 0x20 #Check if bomb
    		#If bomb, return 0.. game status will handle revealing bomb
    		add $v0, $0, $0
    		beq $t4, 0x20, pAction_exit
    		
    		andi $t4, $t3, 0x0F #Check for numbers
    		beqz $t4, rToggle_revealCell_e
    		
    		addi $a2, $t4, 0x30 #Convert to ascii number
    		
    		li $a3, BLACK
    		addi $sp, $sp, -16
    		sw $a3, 0($sp)
    		li $a3, BRIGHT_MAGENTA
    		
    		j rToggle_revealCell_save
    		rToggle_revealCell_f:
    			
    			li $a2, 'F'
    			li $a3, GREY
    			addi $sp, $sp, -16
       			sw $a3, 0($sp)
    			li $a3, BRIGHT_BLUE
    			j rToggle_revealCell_save
    		rToggle_revealCell_e:
    			
    			li $a2, '\0'
    			li $a3, BLACK
    			addi $sp, $sp, -16
    			sw $a3, 0($sp)
    			li $a3, WHITE
    			
    			j rToggle_revealCell_save
    		
    		rToggle_revealCell_save:
    			
    			sw $s0, 4($sp)
    			sw $s1, 8($sp)
    			sw $s2, 12($sp)
    			
    			jal set_cell
    			
    			#Call search cell
    			
    			lw $a0, 8($sp)
    			lw $a1, cursor_row
    			lw $a2, cursor_col
    			
    			jal search_cells
    			
    			lw $s2, 12($sp)
    			lw $s1, 8($sp)
    			lw $s0, 4($sp)
    			
    			addi $sp, $sp, 16
    			add $v0, $0, $0
    			j pAction_exit
    pAction_updateCursor:
    	#Update previous cursor loc
    	li $t4, 10 #temp var
    	mul $t4, $t2, $t4 #t4 = previous-row*10
    	add $t4, $t4, $t3 #t4 = offset = previous_row*10 + previous_column
    	
    	add $t4, $t4, $s1 #tf = cells_array + offset
    	
    	lb $t5, 0($t4) #t5 = cell_game_data
    	
    	andi $t6, $t5, 0x40 #if t6 = 0x40, cell is revealed
    	beq $t6, 0x40, pa_updateRevealed
    	
    	andi $t6, $t5, 0x10 #Check for flag
    	beq $t6, 0x10, pa_updateFlagged
    	
    	j pa_updateHidden
    	
    		pa_updateRevealed:
    			
    			#Only 3 possible cells being revealed previously: empty cell, number cell, or flagged cell
    			
    			#Check for empty cell
    			andi $t6, $t5, 0x0F #if t6 != 0, it's a number cell. if not then it is an empty cell
    			beqz $t6, pa_updateEmpty
    			
    			j pa_updateNumber
    			
    			pa_updateNumber:
    				#Change number into ascii number
    				
    				addi $t6, $t6, 0x30 #number to ascii
    				
    				#BLACK BACKGROUND BRIGHT_MAGENTA FOREGROUND 'ascii number'
    				move $a0, $t2 #row
    				move $a1, $t3 #col
    				move $a2, $t6 #t6 = ascii number char
    				li $a3, BLACK
    				addi $sp, $sp, -24
    				sw $a3, 0($sp) #bg-val
    				li $a3, BRIGHT_MAGENTA #fg-val
    				j pc_update_saveRegs
    			pa_updateFlagged:
    				#GREY BACKGROUND BRIGHT_BLUE FOREGROUND 'F'
    				move $a0, $t2 #row
    				move $a1, $t3 #col
    				li $a2, 'F'
    				li $a3, GREY
    				addi $sp, $sp, -24
    				sw $a3, 0($sp) #bg-val
    				li $a3, BRIGHT_BLUE #fg-val
    				j pc_update_saveRegs
    			pa_updateEmpty:
    				#BLACK BACKGROUND WHITE FOREGROUND \0
    				move $a0, $t2 #row
    				move $a1, $t3 #col
    				li $a2, '\0'
    				li $a3, BLACK
    				addi $sp, $sp, -24
    				sw $a3, 0($sp) #bg-val
    				li $a3, WHITE #fg-val
    				j pc_update_saveRegs
    		pa_updateHidden:
    			#GREY BACKGROUND and FOREGROUND with char \0
    			move $a0, $t2 #row
    			move $a1, $t3 #col
    			li $a2, '\0'
    			li $a3, GREY #bg-val and fg val
    			addi $sp, $sp, -24
    			sw $a3, 0($sp) #store bg-val
    			j pc_update_saveRegs
    			
    		pc_update_saveRegs:
    			#store 3 saved registers and 2 temporaries. do not need t2-t3 anymore
    			sw $s0, 4($sp)
    			sw $s1, 8($sp)
    			sw $s2, 12($sp)
    			sw $t0, 16($sp)
    			sw $t1, 20($sp)
    			
    			jal set_cell
    			
    			lw $t1, 20($sp)
    			lw $t0, 16($sp)
    			lw $s2, 12($sp)
    			lw $s1, 8($sp)
    			lw $s0, 4($sp)
    			
    			addi $sp, $sp, 24
    			
    	#Update new cursor loc
    	move $a0, $t0 #current row
    	move $a1, $t1 #current col
    	la $a2, '\0'
    	li $a3, YELLOW #bg-val
    	addi $sp, $sp, -24 #4 registers to save
    	sw $a3, 0($sp) #bg - val on stack
    	li $a3, GREY #foregorund val
        
        #Save registers
        sw $s0, 4($sp)
        sw $s1, 8($sp)
        sw $s2, 12($sp)
        sw $t0, 16($sp)
        sw $t1, 20($sp)
        
        jal set_cell
        
        #Load saved-registers
        lw $t1, 20($sp)
        lw $t0, 16($sp)
        lw $s2, 12($sp)
        lw $s1, 8($sp)
        lw $s0, 4($sp)
        
        
        sw $t0, cursor_row
        sw $t1, cursor_col
        add $v0, $0, $0
        j pAction_exit
        
    pAction_invalidMove:
    	addi $v0, $0, -1 #Invalid code
    	j pAction_exit
    pAction_exit:
    	move $ra, $s0
    	jr $ra

game_status:
    #a0 = cells_array
    move $s0, $ra
    move $s1, $a0
    
    #Check if lost (bomb at cursor)
    lw $t0, cursor_row
    lw $t1, cursor_col
    
    li $t2, 10 #temp
    mul $t2, $t2, $t0 #t2 = row*10
    add $t2, $t2, $t1 #t2 = row*10 + col
    
    add $t3, $t2, $s1 #cells_array + index
    lb $t2, ($t3) #cells_array[index] = game_data
    
    andi $t4, $t2, 0x40 #Hidden/shown bit
    beq $t4, 0x40, game_status_checkBomb
    j game_status_loop_check
    game_status_checkBomb:
    	andi $t4, $t2, 0x20
    	beq $t4, 0x20, game_status_lost
    game_status_loop_check:
    #To win, flags must be placed on only bombs. Cells must be revealed
    
    add $t0, $0, $0 #row = 0
    addi $t2, $0, 10
    add $t3, $0, $0 #Number of bombs
    add $t4, $0, $0 #Number of flags
    
    
    game_status_outer_loop:
    	beq $t0, $t2, game_status_loop_done
    	
    	add $t1, $0, $0 #col = 0
    	game_status_inner_loop:
    		beq $t1, $t2, game_status_outer_inc
    		
    		#Process cell here
    		
    		li $t5, 10 #temp
    		mul $t5, $t5, $t0 #row*10
    		add $t5, $t5, $t1 #row*10 + col = index
    		
    		add $t5, $t5, $s1 #cells_array + index
    		lb $t6, 0($t5) #game_data
    		
    		andi $t7, $t6, 0x30 #bomb + flag
    		beq $t7, 0x30, status_addFlaggedBomb
    		beq $t7, 0x20, status_addBomb
    		beq $t7, 0x10, status_addFlag
    		
    		andi $t7, $t6, 0x40 #Get the shown/hidden bit
    		beqz $t7, status_cell_Hidden
    		
    		status_addFlaggedBomb:
    			addi $t3, $t3, 1 #bomb++
    			addi $t4, $t4, 1 #flag++
    			j game_status_inner_inc
    		status_addBomb:
    			addi $t3, $t3, 1 #bomb++
    			j game_status_inner_inc
    		status_addFlag:
    			addi $t4, $t4, 1 #flag++
    			j game_status_inner_inc
    		
    		status_cell_Hidden:
    			#If there is a hidden cell and it's not a flag/bomb game_status = 0
    			j game_status_inGame
    		#############
    		game_status_inner_inc:
    			addi $t1, $t1, 1 #col++
    			j game_status_inner_loop
    		
    	game_status_outer_inc:
    		addi $t0, $t0, 1 #row++
    		j game_status_outer_loop
    	
    game_status_loop_done:
        
        #If number of flags > number of bombs game = lost
        #If number of bombs = number of flags game = win
        #If number of flags < number of bombs game = still going
        beq $t3, $t4, game_status_win
        bgt $t4, $t3, game_status_lost
        j game_status_inGame
    game_status_lost:
    	addi $v0, $0, -1
    	j game_status_exit
    	
    game_status_win:
    	addi $v0, $0, 1
    	j game_status_exit
    	
    game_status_inGame:
    	add $v0, $0, $0
    	j game_status_exit
    
    game_status_exit:
    	move $ra, $s0
    	jr $ra

##############################
# PART 5 FUNCTIONS
##############################

search_cells:
    #a0 = cells
    #a1 = row
    #a2 = col
    
    move $s0, $ra
    move $s1, $a0
    move $s2, $a1
    move $s3, $a2
    
    add $fp, $sp, $0 #fp = sp
    addi $sp, $sp, -8 #push stack
    sw $s2, 0($sp)
    sw $s3, 4($sp)
    search_cells_whileLoop:
    	beq $fp, $sp, search_cells_whileLoop_done
    	
    	lw $t0, 0($sp)
    	lw $t1, 4($sp)
    	addi $sp, $sp, 8 #pop stack
    	
    	printCoord($t0, $t1)
    	
    	getCellIndex($t0, $t1, $t2)
    	add $t2, $t2, $s1 #cells_array + index
    	lb $t3, 0($t2)
    	
    	andi $t4, $t3, 0x10 #Check if flagged
    	beqz $t4, search_cells_reveal
    	j search_cells_bombNum0
    	search_cells_reveal:
    		#Either a number cell or an empty cell
    		andi $t4, $t3, 0x0F
    		beqz $t4, search_cells_reveal_empty
    		j search_cells_reveal_numbers
    		
    		search_cells_reveal_empty:
    			#Black bg, white fg, \0 char
    			move $a0, $t0
    			move $a1, $t1
    			li $a2, '\0'
    			li $a3, BLACK#bg
    			addi $sp, $sp, -28
    			sw $a3, 0($sp)#bg on stack
    			li $a3, WHITE#fg
    			j search_cells_reveal_
    		search_cells_reveal_numbers:
    			#Black bg, Bright_magenta fg, ascii number
    			move $a0, $t0
    			move $a1, $t1
    			addi $t4, $t4, 0x30 #convert number to ascii number
    			move $a2, $t4
    			li $a3, BLACK #bg
    			addi $sp, $sp, -28
    			sw $a3, 0($sp)#bg on stack
    			li $a3, BRIGHT_MAGENTA #fg
    			j search_cells_reveal_
    		search_cells_reveal_:
    			
    			#Mark as revealed
    			andi $t4, $t3, 0xFF
    			ori $t4, $t4, 0x40
    			sb $t4, 0($t2)
    			
    			#Save regs
    			sw $s0, 4($sp)
    			sw $s1, 8($sp)
    			sw $s2, 12($sp)
    			sw $s3, 16($sp)
    			sw $t0, 20($sp)
    			sw $t1, 24($sp)
    			
    			jal set_cell
    			
    			lw $t1, 24($sp)
    			lw $t0, 20($sp)
    			lw $s3, 16($sp)
    			lw $s2, 12($sp)
    			lw $s1, 8($sp)
    			lw $s0, 4($sp)
    			addi $sp, $sp, 28
    			j search_cells_bombNum0
    	search_cells_bombNum0:
    		getCellIndex($t0, $t1, $t2) #t0 = row, t1 = col, t2 = cells_array + index
    		add $t2, $t2, $s1
    		lb $t3, 0($t2) #game_data
    		andi $t4, $t3, 0x0F
    		beqz $t4, search_cells_bombNum0_reveal
    		
    		j search_cells_whileLoop #Jump back to iterator
    		
    		search_cells_bombNum0_reveal:
    			#if row + 1 < 10
    			rowp1:
    				addi $t2, $t0, 1 #row + 1
    				blt $t2, 10, rowp1_hidden
    				j colp1
    				#cell[row+1][col].isHidden
    				rowp1_hidden:
    					getCellIndex($t2, $t1, $t3) #t3 = index
    					add $t3, $t3, $s1 #t3 = cells_array[index]
    					lb $t4, 0($t3)
    					andi $t5, $t4, 0x40 #Check if isHidden
    					beqz $t5, rowp1_notFlagged
    					j colp1
    					rowp1_notFlagged:
    						#!cell[row+1][col].isFlag
    						andi $t5, $t4, 0x10 #Check if it has a flag
    						beq $t5, 0x10, colp1 #Onto next nested if
    						#Else, increase stack
    						addi $sp, $sp, -8
    						sw $t2, 0($sp)
    						sw $t1, 4($sp)
    						j colp1
    			colp1:
    				addi $t2, $t1, 1 #col + 1
    				blt $t2, 10, colp1_hidden
    				j rowm1
    				#cell[row][col+1].isHidden
    				colp1_hidden:
    					getCellIndex($t0, $t2, $t3) #t3 = index
    					add $t3, $t3, $s1 #t3 = cells_array[index]
    					lb $t4, 0($t3)
    					andi $t5, $t4, 0x40 #Check if isHidden
    					beqz $t5, colp1_notFlagged
    					j rowm1
    					colp1_notFlagged:
    						#!cell[row][col+1].isFlag
    						andi $t5, $t4, 0x10 #Check if it has a flag
    						beq $t5, 0x10, rowm1 #Onto next nested if
    						#Else, increase stack
    						addi $sp, $sp, -8
    						sw $t0, 0($sp)
    						sw $t2, 4($sp)
    						j rowm1
    			rowm1:
    				addi $t2, $t0, -1 #row - 1
    				bgez $t2, rowm1_hidden
    				j colm1
    				#cell[row-1][col].isHidden
    				rowm1_hidden:
    					getCellIndex($t2, $t1, $t3) #t3 = index
    					add $t3, $t3, $s1 #t3 = cells_array[index]
    					lb $t4, 0($t3)
    					andi $t5, $t4, 0x40 #Check if isHidden
    					beqz $t5, rowm1_notFlagged
    					j colm1
    					rowm1_notFlagged:
    						#!cell[row-1][col].isFlag
    						andi $t5, $t4, 0x10 #Check if it has a flag
    						beq $t5, 0x10, colm1 #Onto next nested if
    						#Else, increase stack
    						addi $sp, $sp, -8
    						sw $t2, 0($sp)
    						sw $t1, 4($sp)
    						j colm1
    						
    			colm1:
    				addi $t2, $t1, -1 #col - 1
    				bgez $t2, colm1_hidden
    				j rowm1colm1
    				#cell[row][col+1].isHidden
    				colm1_hidden:
    					getCellIndex($t0, $t2, $t3) #t3 = index
    					add $t3, $t3, $s1 #t3 = cells_array[index]
    					lb $t4, 0($t3)
    					andi $t5, $t4, 0x40 #Check if isHidden
    					beqz $t5, colm1_notFlagged
    					j rowm1colm1
    					colm1_notFlagged:
    						#!cell[row][col-1].isFlag
    						andi $t5, $t4, 0x10 #Check if it has a flag
    						beq $t5, 0x10, rowm1colm1 #Onto next nested if
    						#Else, increase stack
    						addi $sp, $sp, -8
    						sw $t0, 0($sp)
    						sw $t2, 4($sp)
    						j rowm1colm1
    			rowm1colm1:
    				addi $t2, $t0, -1 #row - 1
    				addi $t3, $t1, -1 #col - 1
    				bgez $t2, rowm1colm1_colCheck
    				j rowm1colp1
    				rowm1colm1_colCheck:
    					bgez $t3, rowm1colm1_hidden
    					j rowm1colp1 
    					rowm1colm1_hidden:
    						getCellIndex($t2, $t3, $t4) #t4 = index
    						add $t4, $t4, $s1 #cells_array[index]
    						lb $t5, 0($t4)
    						andi $t6, $t5, 0x40 #Check if is Shown/Hidden
    						beqz $t6 rowm1colm1_notFlagged
    						j rowm1colp1
    						rowm1colm1_notFlagged:
    							#Check for flag
    							andi $t6, $t5, 0x10 #flag bit
    							beq $t6, 0x10, rowm1colp1
    							#Else
    							addi $sp, $sp, -8
    							sw $t2, 0($sp)
    							sw $t3, 4($sp)
    							j rowm1colp1
    			rowm1colp1:
    				addi $t2, $t0, -1 #row - 1
    				addi $t3, $t1, 1 #col + 1
    				bgez $t2, rowm1colp1_colCheck
    				j rowp1colm1
    				rowm1colp1_colCheck:
    					blt $t3, 10, rowm1colp1_hidden
    					j rowp1colm1
    					rowm1colp1_hidden:
    						getCellIndex($t2, $t3, $t4) #t4 = index
    						add $t4, $t4, $s1 #cells_array[index]
    						lb $t5, 0($t4)
    						andi $t6, $t5, 0x40 #Check if is Shown/Hidden
    						beqz $t6, rowm1colp1_notFlagged
    						j rowp1colm1
    						rowm1colp1_notFlagged:
    							#Check for flag
    							andi $t6, $t5, 0x10 #flag bit
    							beq $t6, 0x10, rowp1colm1
    							#Else
    							addi $sp, $sp, -8
    							sw $t2, 0($sp)
    							sw $t3, 4($sp)
    							j rowp1colm1
    			rowp1colm1:
    				addi $t2, $t0, 1 #row + 1
    				addi $t3, $t1, -1 #col - 1
    				blt $t2, 10, rowp1colm1_colCheck
    				j rowp1colp1
    				rowp1colm1_colCheck:
    					bgez, $t3, rowp1colm1_hidden
    					j rowp1colp1
    					rowp1colm1_hidden:
    						getCellIndex($t2, $t3, $t4) #t4 = index
    						add $t4, $t4, $s1 #cells_array[index]
    						lb $t5, 0($t4)
    						andi $t6, $t5, 0x40 #Check if is Shown/Hidden
    						beqz $t6 rowp1colm1_notFlagged
    						j rowp1colp1
    						rowp1colm1_notFlagged:
    							#Check for flag
    							andi $t6, $t5, 0x10 #flag bit
    							beq $t6, 0x10, rowp1colp1
    							#Else
    							addi $sp, $sp, -8
    							sw $t2, 0($sp)
    							sw $t3, 4($sp)
    							j rowp1colp1
    			rowp1colp1:
    				addi $t2, $t0, 1 #row + 1
    				addi $t3, $t1, 1 #col + 1
    				blt $t2, 10, rowp1colp1_colCheck
    				j search_cells_whileLoop
    				rowp1colp1_colCheck:
    					blt $t3, 10, rowp1colp1_hidden
    					j search_cells_whileLoop
    					rowp1colp1_hidden:
    						getCellIndex($t2, $t3, $t4) #t4 = index
    						add $t4, $t4, $s1 #cells_array[index]
    						lb $t5, 0($t4)
    						andi $t6, $t5, 0x40 #Check if is Shown/Hidden
    						beqz $t6, rowp1colp1_notFlagged
    						j search_cells_whileLoop
    						rowp1colp1_notFlagged:
    							#Check for flag
    							andi $t6, $t5, 0x10 #flag bit
    							beq $t6, 0x10, search_cells_whileLoop
    							#Else
    							addi $sp, $sp, -8
    							sw $t2, 0($sp)
    							sw $t3, 4($sp)
    							j search_cells_whileLoop
    search_cells_whileLoop_done:
    	move $ra, $s0
    	jr $ra
#####################################################################

