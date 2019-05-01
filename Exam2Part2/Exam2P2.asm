.data

# two given array 

sectionA:	.word  56, 70, 90, 84, 45, 78, 96, 80, 88, 67, 58, 92, 0
sectionB:	.word  74, 59, 49, 88, 92, 76, 88, 72, 90,  50, 82, 0

name: .asciiz "Name: Shane McPhillips\n\n"
tab: .asciiz "\t"
newLine: .asciiz "\n"
numStudents: .asciiz " No. of Students"
fail: .asciiz "Fail"
pass: .asciiz "Pass"
avg: .asciiz "Average"
divider: .asciiz "================================================================="
secA: .asciiz "SectionA:"
secB: .asciiz "SectionB:"

.macro printString(%str)
	
	li $v0, 4
	la $a0, %str
	syscall
	
.end_macro

.macro printString_R(%str)
	
	li $v0, 4
	move $a0, %str
	syscall
	
.end_macro

.macro printInt(%reg)
	
	li $v0, 1
	move $a0, %reg
	syscall
	
.end_macro

.macro printHeader()

	printString(numStudents)
	printString(tab)
	printString(fail)
	printString(tab)
	printString(pass)
	printString(tab)
	printString(avg)
	printString(newLine)
	printString(divider)
	printString(newLine)

.end_macro

.align 2
.text
.globl main

main:
	
	printString(name)
	printHeader()
	
	la $a0, sectionA
	la $a1, secA
	jal process_section
	
	la $a0, sectionB
	la $a1, secB
	jal process_section
	
	j exit
	
#a0 = array - grade_section
#a1 = section_name
process_section:
	move $s0, $a0
	move $s1, $a1
	add $t0, $0, $s0 #t0 = incrementor of section A
	add $t1, $0, $0 #t1 = num students
	add $t2, $0, $0 #Passing grades. (To find failing grades, fail_grades = (num_students - passing_grades)
	add $t5, $0, $0 #Grade total (For average calc)
	lw $t3, 0($t0)
	loop:
		beqz $t3, output #If we reach a grade of 0, output a.
		
		#Add grade to total
		add $t5, $t5, $t3
			
		#Increment the number of students.
		addi $t1, $t1, 1 #t1++
		bge $t3, 60, addPassGrade
		j loop_inc
		addPassGrade:
			#Increment our passing grades count.
			add $t2, $t2, 1 #t2++
			j loop_inc
		loop_inc:
			#Increment our indexer
			addi $t0, $t0, 4
			lw $t3, 0($t0)
			j loop
	output:
		#output here
			printString_R($s1)
			printString(tab)
			printInt($t1)
			printString(tab)
			sub $t4, $t1, $t2
			printInt($t4)
			printString(tab)
			printInt($t2)
			printString(tab)
			div $t6, $t5, $t1
			printInt($t6)
			printString(newLine)
		#Return to our original function.
		jr $ra
exit:
	li	$v0,10
	syscall
