; Print "number i" for i in range(5,60)
section .data
	line_text db "number "
	line_text_len equ $ - line_text

	str_buffer db 0 ; for printing integers

section .text
	global _start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Integer printing system ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calculate_ten_power:
	; calculate the power of 10 that corresponds to an integer
	; for example, 100 for 543, 1000 for 8956, and 10000 for 15236
	; takes an argument on the stack
	; returns the integer in rcx

	; rsp is the return address, add 8 to get the argument
	mov rcx, [rsp+8] ; rcx should be the integer to find the power of 10 for

	mov rax, 1 ; we need to calculate the power of 10 that corresponds to rcx
	; for example 100 for 543 and 1000 for 8753
	mov rbx, 10
	calculate_ten:
		mul rbx
		cmp rax, rcx
		jg finish_power_ten ; if number is greater than target, divide by 10 and ret
		jmp calculate_ten

	finish_power_ten:
		; divide ax by 10 to finish the calculation
		xor rdx, rdx
		div rbx
		; now rax contains the power of 10
		mov rcx, rax
	ret


print_digit:
	; print a digit
	; takes an argument on the stack
	; returns nothing
	push rcx
	mov rcx, [rsp+16] ; get the third argument on the stack. [return address (+0)] -> [rcx (+8)] -> [digit to print (+16)]
	add rcx, '0' ; convert digit to ASCII

	mov byte [str_buffer], cl ; assign lower 8 bits of rcx to buffer

	mov rsi, str_buffer ; buffer pointer
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rdx, 1 ; len
	syscall   ; call kernel

	pop rcx ; restore rcx

	ret


print_integer:
	; takes the integer in from rax
	push rax ; push rax it for the next function to consume
	call calculate_ten_power ; power of 10 is now in rcx

	pop rax ; mov the argument (number to print) that was pushed into rax

	iter_number:
		; num_to_print: rax
		; base_10_place: rcx
		; formula for accessing number: (num_to_print // base_10_place) % 10
		; base_10_place is the power of 10 that corresponds to the place of number to print
		; using 123 for example, 100 will get the 1, 10 will get the 2, and 1 will get the 3

		; first, make sure we have a copy of rax
		push rax

		; 10 for use in modulo
		mov rbx, 10

		; next, floor divide rax by rcx
		xor rdx, rdx
		div rcx
		; result is stored in rax, mod 10
		; clear out rdx because thats where remainder is stored
		xor rdx, rdx
		div rbx

		; rdx now contains our digit to print
		push rdx
		call print_digit
		add rsp, 8 ; remove the rdx that never got popped from print_digit from the stack


		; check if rcx is equal to 1. if so, we just did the last digit
		mov rax, 1
		cmp rax, rcx
		je exit_print_integer

		; divide out power of 10 by 10 to get the next digit
		xor rdx, rdx
		mov rbx, 10
		mov rax, rcx

		div rbx
		mov rcx, rax

		; restore our original number to print
		pop rax

		; loop to iter_number until rcx is 1 (we've done the last digit)
		jmp iter_number

	exit_print_integer:
	pop rax ; pop off our original number so that we return to the correct address

	ret

_start:
	mov rcx, 5
	loop_start:	
		cmp rcx, 61 ; if at 61, jump to exit
		je exit

		push rcx

		; print line text
		mov rax, 1
		mov rdi, 1
		mov rsi, line_text
		mov rdx, line_text_len
		syscall

		mov rax, [rsp] ; put current increment in rax to print

		call print_integer

		; print newline
		push 0xa ; newline
		mov rax, 1
		mov rdi, 1
		mov rsi, rsp
		mov rdx, 1
		syscall

		; pop newline from stack
		add rsp, 8
		pop rcx

		inc rcx
		jmp loop_start

	exit:
		mov rax, 60
		mov rdi, 0
		syscall ; call kernel