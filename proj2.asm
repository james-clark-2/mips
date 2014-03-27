###############################################################################
#
#James Clark
#CSC225-1N1
#Project 2 - Due 3/14
#
#proj2.asm
#	Defines and tests two functions. One to test if an integer is prime, and
#	another to determine if a string is a palindrome.
#
###############################################################################

.data
	buffer: .space 1024				#Reserved for string input
	number_prompt: .asciiz "Enter a number (enter -1 to stop): "
	string_prompt: .asciiz "Type in a word (input empty string to stop): "
	palin_no_string: .asciiz " is not a palindrome.\n\n"
	palin_yes_string: .asciiz " is a palindrome.\n\n"
	prime_yes_string: .asciiz " is a prime number.\n\n"
	prime_no_string: .asciiz " is not a prime number.\n\n"
	goodbye_string: .asciiz "Goodbye.\n"
	newline: .asciiz "\n"
	
.text

main:
#Contines to prompt for integers and tests for prime numbers until "-1" is entered
number_input_loop:
	li $v0, 4						#Print prompt for numbers
	la $a0, number_prompt
	syscall
	
	li $v0, 5						#Get integer input
	syscall
	
	li $t0, -1
	beq $v0, $t0, string_input_loop	#Test for our exit signal
	
	move $s0, $v0					#Store a copy of our input for later
	
	move $a0, $v0					#Pass our input to is_prime
	jal is_prime					#Call is_prime
	move $t0, $v0					#Store result of is_prime
	
	li $v0, 1						#Print the number as part of the report
	move $a0, $s0
	syscall
	
	bnez $t0, prime_yes				#Result != zero, is prime

prime_no:
	la $a0, prime_no_string			#Print negative report
	li $v0, 4
	syscall
	j number_input_loop
	
prime_yes:
	la $a0, prime_yes_string		#Print positive report
	li $v0, 4
	syscall
	j number_input_loop

#Continues to prompt for string input and tests for palindromes until user
# enters an empty string
string_input_loop:
	li $v0, 4						#Print newline
	la $a0, newline
	syscall

	li $v0, 4						#Prompt for input
	la $a0, string_prompt
	syscall
	
	li $v0, 8						#Get string input
	la $a0, buffer
	li $a1, 1024					#Max of 1024 characters
	syscall
	
	lb $s0, 0($a0)					#Check if string is empty
	li $s1, 10						#10(dec) = ASCII newline, s1 = newline char
	beq $s0, $s1, exit				#Use empty string as our exit signal
	
	la $a0, buffer					#Set buffer as an argument
	jal is_palindrome				#Call is_palindrome
	move $s0, $v0					#Store result
	
	li $v0, 4						#Print string as part of report
	la $a0, buffer
	syscall
		
	bnez $s0, palindrome_yes
	
palindrome_no:
	la $a0, palin_no_string			#Print negative report
	syscall
	j string_input_loop
	
palindrome_yes:
	la $a0, palin_yes_string		#Print positive report
	syscall
	j string_input_loop
	
exit:
	li $v0, 4						#Print goodbye
	la $a0, goodbye_string
	syscall
	
	li $v0, 10						#Exit to system
	syscall
	
###############################################################################	
	
#is_prime - tests if a number is prime
# arguments: $a0 - a signed integer
# outputs: $v0 - 1 if prime, 0 otherwise
is_prime:
	#Check if argument < 0
	bltz $a0, return_not_prime
	
	#Check if argument is 1 or 2 (already prime)
	li $t0, 1				
	beq $a0, $t0, return_is_prime
	
	li $t0, 2
	beq $a0, $t0, return_is_prime
	
	#Check if argument is even (not prime)
	andi $t0, $a0, 0x00000001		#Check least significant bit
	beqz $t0, return_not_prime		#Result == 0, argument is even
	
	#Brute force check divisors [3..sqrt($a0)]
	li $t0, 3						#Start divisors with 3
	
	move $t2, $a0
	
	addi $sp, $sp, -16				#Store registers on stack - 4 items
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	
	jal square_root_int				#get square root of $a0
	
	lw $t2, 12($sp)					#Restore registers from stack
	lw $t1, 8($sp)
	lw $t0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 16
	
	move $t1, $v0					#sqrt($a0) is our final divisor check

divisor_loop:
	bgt $t0, $t1, return_is_prime	#Ending our loop here means that all
									# divisors gave a remainder
	div $t2, $t0
	mfhi $t3						#$HI holds the remainder
	beqz $t3, return_not_prime		#No remainder, $t1 is a multiple of $a0
	addi $t0, 2						#Increment divisor by 2
	j divisor_loop

return_not_prime:			
	li $v0, 0						#Failure! Return 0
	jr $ra
	
return_is_prime:
	li $v0, 1						#Success! Return 1
	jr $ra

###############################################################################	
	
#square_root_int - finds the integer part of a square root
# arguments: $a0 - an integer
# outputs $v0 - floor of square root of $a0, or -1 if $a0 is negative
#
# Behaves similarly to finding square roots by long division method
#
square_root_int:
	bgez $a0, real_result			#test for $al < 0
	li $v0, -1
	jr $ra							#Can't sqrt negative integers, return -1

real_result:
	move $t0, $a0					#remainder
	li $t1, 0						#root
	li $t2, 1						#place

	sll $t2, $t2, 30				#place = 1 << 30 = 0x40000000
	
while_srl:							#get highest power of four <= $a0
	ble $t2, $t0, while_place_nz 	#if $t2 <= $t1, exit loop
	srl $t2, $t2, 2					#decrease by power of four
	j while_srl

while_place_nz:
	beq $t2, $zero, while_place_nz_exit
	
	add $t3, $t1, $t2				#root + place
	blt $t0, $t3, end_if			#if remainder >= root + place
	sub $t0, $t0, $t3				#remainder = remainder - (root + place)
	add $t1, $t1, $t2				#root += (place * 2)
	add $t1, $t1, $t2
end_if:

	srl $t1, $t1, 1
	srl $t2, $t2, 2
	j while_place_nz				#repeat loop
while_place_nz_exit:

	move $v0, $t1					#store result for return
	jr $ra							#exit procedure
	
###############################################################################	
	
#is_palindrome - tests if the word stored in buffer is a palindrome
# arguments: $a0 - address of string buffer
# outputs: $v0 - 1 if palindrome, 0 otherwise
is_palindrome:
	move $t0, $a0					#Beginning address of string
	move $t1, $t0					#End address-to-be
	
find_end:
	lb $t2, 0($t1)
	li $t3, 10						#10(dec) = ASCII newline
	beq $t2, $t3, find_end_exit		#$t2 = '\n', found end of string
	addi $t1, 1						#Increment address
	j find_end
find_end_exit:

	beq $t0, $t1, not_palindrome	#Start and end address are equal, string is empty
									#Not a palindrome

	sb $0, 0($t1)					#Replace newline at the end with 0
	addi $t1, -1					#Back up one character
	
check_palindrome:
	bge $t0, $t1, palindrome		#$t0, $t1 are at, or have crossed, midpoint of string
	lb $t2, 0($t0)					#Get char from front-half of string
	lb $t3, 0($t1)					#Get char from back-half of string
	bne $t2, $t3, not_palindrome	#Check front and back chars
	addi $t0, 1						#Increment front counter
	addi $t1, -1					#Decrement back counter
	j check_palindrome

not_palindrome:
	li $v0, 0						#Failure! Return 0
	jr $ra

palindrome:
	li $v0, 1						#Success! Return 1
	jr $ra

###############################################################################	
