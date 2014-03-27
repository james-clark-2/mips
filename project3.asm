###############################################################################
#
#James Clark
#CSC225-1N1
#Project 3 - Due 3/31
#
#project3.asm
#	Accepts a string as input and then performs two functions:
#		1) Strips all non-alphabet characters and compresses the string
#			ex: "I'm the Batman!" becomes "ImtheBatman"
#
#		2) Prints a report of how frequently each letter appears in the string
#
###############################################################################

.data
	buffer: .space 81				#Buffer for string input
	letter_freq: .word 0:26			#Frequency counts of letters, initialized to zero
	prompt: .asciiz "Enter a string: "
	a_m_label: .asciiz "a b c d e f g h i j k l m"
	n_z_label: .asciiz "n o p q r s t u v w x y z"
	newline: .asciiz "\n"
	space: .asciiz " "

.text
main:
input_loop:
	la $a0, prompt					#Prompt for string
	jal print
	
	la $a0, buffer					#Get string from console, max 80 chars and newline
	li $a1, 81
	jal get_string_input
	
	lb $t0, 0($a0)					#Check if first char is '\0'
	beq $t0, $0, exit				#Exit on empty string input
	
	jal compress_string				#Compress the string, then print it
	jal println
	
	la $a1, letter_freq				#Address of letter frequency table
	
	jal build_frequency_table		#Store frequency of letters in string at $a0
	
	move $a0, $a1					#Print our table
	jal print_frequency_table
	
	j input_loop					#Continue until string input is null
	
exit:
	li $v0, 10						#Exit to system
	syscall

###############################################################################
#
# zero_word_array: $a0 - address of array of words
#				   $a1 - number of items in array
#
#	Initializes each element in array at $a0 with zeroes
#

zero_word_array:	
	li $t0, 0						#Counter
	move $t1, $a0					#Array offset
	move $t2, $a1
	
array_loop:
	bge $t0, $t2, exit_array_loop	#Don't exceed size stored in $a1
	sw $0, 0($t1)					#Set it to zero

	addi $t0, $t0, 1				#Increment counter
	addi $t1, $t1, 4				#Increment offset
	j array_loop
exit_array_loop:

	jr $ra							#Return
	
###############################################################################
#
# is_alpha: $a0 - a single character
# Output: $v0 - 0 if not within 'a'-'z' or 'A'-'Z', 1 otherwise
#
is_alpha:
	move $t0, $a0					#Store copy of $a0
	li $t1, 90	 					#90(dec) == 'Z'
	bgt $t0, $t1, test_alpha 		#Check if character "could" be lower case
	addi $t0, $t0, 32				#Make "lower case" to simplify alpha test
	
test_alpha:
	li $t1, 97						#Test $t0 < 'a'
	blt $t0, $t1, not_alpha
	li $t1, 122						#Test $t0 > 'z'
	bgt $t0, $t1, not_alpha
		
	li $v0, 1						#$a0 is a letter, return 1
	jr $ra
	
not_alpha:
	li $v0, 0						#$a0 is not a letter, return 0
	jr $ra


###############################################################################
#
# print_char: $a0 - char value
#
# Output: prints a single character to console
#

print_char:
	addi $sp, $sp, -4
	sw $v0, 0($sp)					#Save $v0 on stack

	li, $v0, 11
	syscall
	
	lw $v0, 0($sp)					#Pop $v0 from stack
	addi $sp, $sp, 4
	
	jr $ra
	
###############################################################################
#
# print: $a0 - address of string buffer
#
# Output: prints string to console
#
print:
	addi $sp, $sp, -4
	sw $v0, 0($sp)					#Save $v0 on stack
	
	li, $v0, 4
	#$a0 already holds address of string
	syscall
	
	lw $v0, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
###############################################################################
#
# println: $a0 - address of string buffer
#
# Output: prints string to console
#
println:
	addi $sp, $sp, -8				
	sw $v0, 0($sp)					#Save $v0 on stack
	sw $a0, 4($sp)					#Save $a0 on stack

	li, $v0, 4						#Print string syscall
	#$a0 already holds address of string
	syscall
	
	la $a0, newline
	syscall
	
	lw $a0, 4($sp)					#Pop $a0 from stack
	lw $v0, 0($sp)					#Pop $v0 from stack
	addi $sp, $sp, 8
	
	jr $ra
	
###############################################################################
#
# get_string_input: $a0 - address of string buffer
#					$a1 - size of buffer
# Output: Buffer at address $a0 holds null-terminated console input
#
get_string_input:
	addi $sp, $sp, -4
	sw $v0, 0($sp)					#Save $v0 on stack

	li $v0, 8						#Get string input
	#$a0 already holds address of buffer
	#$a1 already holds size of buffer
	syscall
	
#Find newline at end of string and replace it with '\0'
	move $t2, $a0					#Start $t2 at address of $a0
	
find_end:
	lb $t0, 0($t2)
	li $t1, 10						#10(dec) = ASCII newline
	beq $t0, $t1, find_end_exit		#$t0 == '\n', found end of string
	beqz $t0, find_end_exit			#$t0 == '\0', found end of string
	addi $t2, 1						#Increment address
	j find_end
find_end_exit:
	sb $0, 0($t2)					#Replace newline at the end with '\0'
	
	lw $v0, 0($sp)					#Pop $v0 from stack
	addi $sp, $sp, 4
	
	jr $ra							#Return
	
###############################################################################
#
# compress_string: $a0 - address of null-terminated string buffer
#
# Output: Removes all non-alpha characters from string
#
compress_string:
	move $t1, $a0					#Current place in string
	move $t2, $a0					#Next letter in string
	
loop_string:
	lb $t0, 0($t2)					#Get character
	beq $t0, $0, exit_loop_string	#Check end of string
		
	addi $sp, $sp, -20				#Make room for 5 words
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	sw $a0, 16($sp)
	
	move $a0, $t0
	jal is_alpha					#Check if $t0 is a letter
	
	lw $a0, 16($sp)					#Restore registers from stack
	lw $t2, 12($sp)					
	lw $t1, 8($sp)
	lw $t0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	
	beq $v0, $0, increment			#$t0 is not a letter, increment $t2 only
	
	sb $t0, 0($t1)					#Place letter at $t1
	addi $t1, $t1, 1				#Next place to put a letter
		
increment:
	addi $t2, $t2, 1				#Increment address to next character
	j loop_string					#And repeat
exit_loop_string:

	sb $0, 0($t1)					#Null terminate the compressed string

	jr $ra							#Return
	
###############################################################################
#
# build_frequency_table: $a0 - address of null-terminated string buffer
#						 $a1 - address of frequency table, assumed to hold 26
#                              elements
# **Assumes that string at $a0 holds only letters
#
# Output: Keeps count of each letter's occurrence in the string at $a0 in the 
#         frequency table at $a1
#
build_frequency_table:
	addi $sp, $sp, -12				#Store $ra, $a0, $a1 on stack
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	
	move $a0, $a1					#$a0 == Address of frequency table
	li $a1, 26						#$a1 == size of frequency table
	jal zero_word_array				#Initialze table to zeroes
	
	lw $a1, 8($sp)					#Pop $ra, $a0, $a1 from stack
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	
	move $t1, $a0
	
loop:
	lb $t0, 0($t1)					#Get character
	beq $t0, $0, exit_loop			#Exit loop when we find '\0'
	
	li $t2, 97						#97(dec) == 'a'
	bge $t0, $t2, record_freq		#Check if lower case
	addi $t0, $t0, -32				#Make upper case
		
record_freq:
	addi $t0, $t0, -97				#Get ordinal of character ('A'==0, 'B'==1, etc.)
	sll $t0, $t0, 2					#$t0 * 4 == byte offset
	add $t0, $a1, $t0				#Get frequency table address + offset
	lw $t3, 0($t0)
	addi $t3, $t3, 1				#Increment letter count
	sw $t3, 0($t0)
	
increment_loop:
	addi $t1, $t1, 1				#Increment count
	j loop
exit_loop:

	jr $ra							#Return
	
###############################################################################
#
# print_frequency_table: $a0 - address of frequency table, assumed to hold 26
#                              elements
#
# Output: Prints contents of frequency table
#
print_frequency_table:
	addi $sp, $sp, -12				
	sw $a0, 0($sp)					#Save $a0 on stack
	sw $ra, 4($sp)					#Save $ra on stack
	sw $v0, 8($sp)					#Save $v0 on stack
	
	move $t0, $a0					#Address of table
	li $t1, 0						#Counter
	li $t2, 13						#Print first 13 letters of alphabet
		
	la $a0, a_m_label				#Print a-m
	jal println
	
print_loop:
	bge $t1, $t2, exit_print_loop
	li $v0, 1
	lw $a0, 0($t0)					#Print frequency
	syscall
	
	li $v0, 4
	la $a0, space					#Put a space after it
	syscall
	
	addi $t0, $t0, 4				#Increment offset and counter
	addi $t1, $t1, 1
	
	j print_loop
exit_print_loop:

	li $t3, 13
	bne $t1, $t3, exit_proc			#Exit procedure if we've passed half of the alphabet
	
	la $a0, newline					#Print newline
	jal print
	
	la $a0, n_z_label				#Print n-z
	jal println
	
	li $t2, 26						#Prepare to print remaining 13 letters
	j print_loop					#Re-loop through n-z
	
exit_proc:
	la $a0, newline
	jal println

	lw $v0, 8($sp)					#Pop $v0 from stack
	lw $ra, 4($sp)					#Pop $ra from stack
	lw $a0, 0($sp)					#Pop $a0 from stack
	addi $sp, $sp, 8

	jr $ra							#Return