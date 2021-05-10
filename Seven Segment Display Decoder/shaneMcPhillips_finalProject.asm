#Shane McPhillips, Final Project for CSE222
#	Seven Segment Display Decoder

#	 #### 
# 	#    #
#	#    #
#	#    #
#	 #### 
#	#    #
#	#    #
#	#    #
#	 #### 

.data
pixel_array_address: .byte 0:54 #address for the 1 dimensional array
pixel_array_size: .word 54 #array size
char_hashtag: .byte '#'
char_space: .byte ' '
segment_string_strip: .space 6 #6 bytes for 6 characters
segment_string_size: .word 6 #Size of the string
newLine: .asciiz "\n"
inputPrompt: .asciiz "Please enter a positive single digit number to display. (To exit, please enter the number -1)\n"
.text
.globl main
main:
	#Start the main menu loop
	jal mainMenu
	#End the program with a syscall
	j endProgram
	
################################
######## MENU FUNCTIONS ########
################################

mainMenu:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
mainMenuLoop:
	la $a0, inputPrompt
	jal printString
	
	li $v0, 5
	syscall
	
	bltz $v0, mainMenuDone
	move $a0, $v0
	
	#Check segments and set them.
	jal segmentSetter
	#Print out segment display
	jal displaySegments
	#Clear pixel array for next input
	jal clearPixelArray
	#Jump back to input prompt
	j mainMenuLoop
	
mainMenuDone:	
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra

################################
##### SEGMENT FUNCTIONS ########
################################

	#Turn a number into 4 different binary numbers
	#a0 = number input
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
numberToBinInputs:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
	
	#Retrieve input A
	li $t0, 8 #	1000
	and $s0, $a0, $t0
	srl $s0, $s0, 3	#	0001
	
	#Retrieve input B
	li $t0, 4 #	0100
	and $s1, $a0, $t0
	srl $s1, $s1, 2 #	0001
	
	#Retrieve input C
	li $t0, 2 #	0010
	and $s2, $a0, $t0
	srl $s2, $s2, 1 #	0001
	
	
	#Retrieve input D
	li $t0, 1 #	0001
	and $s3, $a0, $t0
	
	jal getFlippedBits
	
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
getFlippedBits:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
	
	not $s4, $s0 #t0 = !A
	sll $s4, $s4, 31
	srl $s4, $s4, 31
	not $s5, $s1 #t1 = !B
	sll $s5, $s5, 31
	srl $s5, $s5, 31
	not $s6, $s2 #t2 = !C
	sll $s6, $s6, 31
	srl $s6, $s6, 31
	not $s7, $s3 #t3 = !D
	sll $s7, $s7, 31
	srl $s7, $s7, 31
	
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentA:
	#Y = !AC + !A!B!D + !ABD + A!B!C
	
	#!AC
	and $t0, $s4, $s2
	
	#!A!B!D
	and $t1, $s4, $s5
	and $t1, $t1, $s7
	
	#!AC + !A!B!D
	or $v0, $t0, $t1
	
	#!ABD
	and $t0, $s4, $s1
	and $t0, $t0, $s3
	
	#A!B!C
	and $t1, $s0, $s5
	and $t1, $t1, $s6
	
	#!ABD + A!B!C
	or $v1, $t0, $t1
	
	#!AC + !A!B!D + !ABD + A!B!C
	or $v0, $v0, $v1
	
	bgtz $v0, setSegmentA
	jr $ra
setSegmentA:
	#[indexes]:{1, 2, 3, 4}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 1($t0)
	sb $t1, 2($t0)
	sb $t1, 3($t0)
	sb $t1, 4($t0)
	
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentB:
	#Y = !A!B + !B!C + !A!C!D + !ACD
	
	#!A!B
	and $t0, $s4, $s5
	
	#!B!C
	and $t1, $s5, $s6
	
	#!A!B + !B!C
	or $v0, $t0, $t1
	
	#!A!C!D
	and $t0, $s4, $s6
	and $t0, $t0, $s7
	
	#!ACD
	and $t1, $s4, $s2
	and $t1, $t1, $s3
	
	#!A!C!D + !ACD
	or $v1, $t0, $t1
	
	#!A!B + !B!C + !A!C!D + !ACD
	or $v0, $v0, $v1
	
	bgtz $v0, setSegmentB
	jr $ra
setSegmentB:
	#[indexes]:{11, 17, 23}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 11($t0)
	sb $t1, 17($t0)
	sb $t1, 23($t0)
	
	jr $ra

	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentC:
	#Y = !B!C + !AD + !AB
	
	#!B!C
	and $t0, $s5, $s6
	
	#!AD
	and $t1, $s4, $s3
	
	#!B!C + !AD
	or $v0, $t0, $t1
	
	#!AB
	and $v1, $s4, $s1
	
	#!B!C + !AD + !AB
	
	or $v0, $v0, $v1
	
	bgtz $v0, setSegmentC
	jr $ra
	
setSegmentC:
	#indices: {35, 41, 47}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 35($t0)
	sb $t1, 41($t0)
	sb $t1, 47($t0)
	
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentD:
	#Y = !A!B!D + !A!BC + !AC!D + A!B!C + !AB!CD
	
	#!A!B!D
	and $t0, $s4, $s5
	and $t0, $t0, $s7
	
	#!A!BC
	and $t1, $s4, $s5
	and $t1, $t1, $s2
	
	#!A!B!D + !A!BC
	or $v0, $t0, $t1
	
	#!AC!D
	and $t0, $s4, $s2
	and $t0, $t0, $s7
	
	#A!B!C
	and $t1, $s0, $s5
	and $t1, $t1, $s6
	
	#!AC!D + A!B!C
	or $v1, $t0, $t1
	
	#!AB!CD
	and $t0, $s4, $s1
	and $t1, $s6, $s3
	and $t0, $t0, $t1
	
	or $v0, $v0, $t0
	or $v0, $v0, $v1
	
	bgtz $v0, setSegmentD
	jr $ra
	
setSegmentD:
	#indices: {49, 50, 51, 52}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 49($t0)
	sb $t1, 50($t0)
	sb $t1, 51($t0)
	sb $t1, 52($t0)
	
	jr $ra

	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentE:
	#Y = !B!C!D + !AC!D
	
	#!B!C!D
	and $t0, $s5, $s6
	and $t0, $t0, $s7
	
	#!AC!D
	and $t1, $s4, $s2
	and $t1, $t1, $s7
	
	#!B!C!D + !AC!D
	or $v0, $t0, $t1
	
	bgtz $v0, setSegmentE
	jr $ra
	
setSegmentE:
	#indices: {30, 36, 42}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 30($t0)
	sb $t1, 36($t0)
	sb $t1, 42($t0)
	
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentF:
	#Y = !A!C!D + !AB!C + !AB!D + A!B!C
	
	#!A!C!D
	and $t0, $s4, $s6
	and $t0, $t0, $s7
	
	#!AB!C
	and $t1, $s4, $s1
	and $t1, $t1, $s6
	
	#!A!C!D + !AB!C
	or $v0, $t0, $t1
	
	#!AB!D
	and $t0, $s4, $s1
	and $t0, $t0, $s7
	
	#A!B!C
	and $t1, $s0, $s5
	and $t1, $t1, $s6
	
	#!AB!D + A!B!C
	or $v1, $t0, $t1
	
	#!A!C!D + !AB!C + !AB!D + A!B!C
	or $v0, $v0, $v1
	bgtz $v0, setSegmentF
	jr $ra
	
setSegmentF:
	#indices: {6, 12, 18}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 6($t0)
	sb $t1, 12($t0)
	sb $t1, 18($t0)
	
	jr $ra
	
	#s0 = A
	#s1 = B
	#s2 = C
	#s3 = D
	#s4 = !A
	#s5 = !B
	#s6 = !C
	#s7 = !D
segmentG:
	#Y = !A!BC + !AC!D + !AB!C + A!B!C
	
	#!A!BC
	and $t0, $s4, $s5
	and $t0, $t0, $s2
	
	#!AC!D
	and $t1, $s4, $s2
	and $t1, $t1, $s7
	
	#!A!BC + !AC!D
	or $v0, $t0, $t1
	
	#!AB!C
	and $t0, $s4, $s1
	and $t0, $t0, $s6
	
	#A!B!C
	and $t1, $s0, $s5
	and $t1, $t1, $s6
	
	#!AB!C + A!B!C
	or $v1, $t0, $t1
	
	#!A!BC + !AC!D + !AB!C + A!B!C
	or $v0, $v0, $v1
	bgtz $v0, setSegmentG
	jr $ra
	
setSegmentG:
	#indicies: {25,26,27,28}
	la $t0, pixel_array_address
	lb $t1, char_hashtag
	
	sb $t1, 25($t0)
	sb $t1, 26($t0)
	sb $t1, 27($t0)
	sb $t1, 28($t0)
	
	jr $ra
	
	#Goes through each segement. If a segment returns a 1, the segment will then go on to set its specific indexes within the pixel array to the hashtag character.
	#a0 = number input
segmentSetter:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
	
	#Get our number bits and flipped bits
	jal numberToBinInputs
	
	#Check and set segments into array
	jal segmentA
	jal segmentB
	jal segmentC
	jal segmentD
	jal segmentE
	jal segmentF
	jal segmentG
	
	#Set any index that doesn't have the hastag char, set as space char.
	jal setSpaces
	
	#Return
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra
	
################################
#### PIXEL ARRAY FUNCTIONS #####
################################

	#Sets spaces where there isn't a hashtag character.
setSpaces:
	la $t0, pixel_array_address
	lw $t1, pixel_array_size
	li $t2, 0 #counter
	move $t3, $t0 #address counter
	lb $t4, char_hashtag
	lb $t5, char_space
setSpacesLoop:
	beq $t2, $t1, setSpacesDone
	lb $t6, 0($t3)
	bne $t6, $t4, setSpace
	j setSpaceEndLoop
setSpace:
	sb $t5, 0($t3)
setSpaceEndLoop:
	addi $t2, $t2, 1
	addi $t3, $t3, 1
	j setSpacesLoop
setSpacesDone:
	jr $ra
	
	#Displays the segments as chars, prints a new line after every 6th char.
displaySegments:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
	la $t0, pixel_array_address
	lw $t1, pixel_array_size
	li $t2, 0 #counter
	li $t3, 0 #new line counter
displaySegmentsLoop:
	beq $t2, $t1, displaySegmentsDone
	lb $a0, 0($t0)
	jal printChar
	addi $t0, $t0, 1
	addi $t2, $t2, 1
	addi $t3, $t3, 1
	beq $t3, 6, insertNewLineDisplay
	j displaySegmentsLoop
insertNewLineDisplay:
	li $t3, 0
	la $a0, newLine
	jal printString
	j displaySegmentsLoop
displaySegmentsDone:
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra
	
clearPixelArray:
	sw $ra, 0($sp)
	addi $sp, $sp, 4
	la $t0, pixel_array_address
	lw $t1, pixel_array_size
	li $t2, 0 #counter
clearPixelArrayLoop:
	beq $t2, $t1, clearPixelArrayDone
	sb $0, 0($t0)
	addi $t0, $t0, 1
	addi $t2, $t2, 1
	j clearPixelArrayLoop
clearPixelArrayDone:
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	jr $ra
################################
####### BASIC FUNCTIONS ########
################################
	#a0 contains string to print.
printString:
	li $v0, 4
	syscall
	jr $ra
	#a0 = char to print
printChar:
	li $v0, 11
	syscall
	jr $ra
endProgram:
	li $v0, 10
	syscall
