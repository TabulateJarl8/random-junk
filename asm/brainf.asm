section .data
    stack_pointer dw 0
    file_buffer_offset dw 0
    str_buffer db 0
    stack times 30000 dw 0

section .text
    global _start

; Read a file into a buffer and return it
; inputs:
;     rdi : filename
; outputs:
;     rax : file contents buffer
;     rdi : number of bytes allocated
;     rsi : the size of the buffer allocation
read_file:
    ; open file
    mov     rax, 2      ; open
    xor     rsi, rsi    ; readonly
    syscall

    mov     r14, rax    ; save fd

    ; seek to the end of the file
    mov     rdi, rax    ; file descriptor
    xor     rsi, rsi    ; offset
    mov     rdx, 2      ; SEEK_END
    mov     rax, 8      ; lseek
    syscall


    ; determine number of bytes to allocate
    mov     r15, rax    ; save filesize
    xor     rdx, rdx    ; set rdx to zero
                        ; rax contains the filesize since we just seeked to the end of the file
    mov     rsi, 4096   ; number of bytes per page  (4kb)
    idiv    rsi         ; bytes / 4096 = number of pages
    inc     rax         ; pages could be 0, inc by 1
    imul    rax, rsi    ; multiple by 4096 to get total bytes

    mov     r13, rax    ; save number of bytes to allocate

    ; allocate bytes
    mov     r10, 0x22   ; MAP_PRIVATE | MAP_ANONYMOUS
    mov     rdx, 3      ; PROT_READ | PROT_WRITE
    mov     rsi, rax    ; number of bytes to allocate
    xor     rdi, rdi    ; address=NULL (let OS choose)
    mov     rax, 9      ; mmap
    syscall

    ; rax has ptr to allocated memory
    ; NOTE: not checking for errors (rax == -1)
    mov     r12, rax    ; save addr of buffer

    ; rewind the file
    xor     rdx, rdx    ; whence (SEEK_SET)
    xor     rsi, rsi    ; offset
    mov     rdi, r14    ; file descriptor
    mov     rax, 8      ; lseek
    syscall

    ; read file into buffer
    mov     rdx, r13    ; number of bytes to read
    mov     rsi, r12    ; addr of buffer
    mov     rdi, r14    ; file descriptor
    mov     rax, 0      ; read
    syscall

    ; close file
    mov     rax, 3      ; close
    mov     rdi, r14    ; fd
    syscall

    ; return buffer
    mov     rax, r12    ; buffer
    mov     rsi, r15    ; file size
    mov     rdi, r13    ; buffer size

    ret

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

inc_current_cell:
    mov rsi, stack_pointer
    mov al, [stack + rsi]

    inc al
    mov [stack + rsi], al
    jmp increment_file_ptr_and_continue

_start:
    ; get arguments
    add     rsp, 16     ; skip argc and argv[0]
    pop     rdi         ; get first argument as file to read

    call read_file

    mov     r12, rdi    ; buffer size
    mov     r13, rax    ; buffer addr

    read_file_byte:
        mov rsi, [file_buffer_offset]
        mov     rsi, r13                    ; load buffer addr
        add     rsi, [file_buffer_offset]   ; increment it to get our current token
        movzx   rax, byte [rsi]             ; load the current token into rax
        cmp     rax, '+'
        je inc_current_cell

        increment_file_ptr_and_continue:
            ; increment file buffer pointer by 1
            mov rax, [file_buffer_offset]
            inc rax
            mov [file_buffer_offset], rax

            ; check if we've gone through the entire file
            cmp     [file_buffer_offset], r12  ; check if file_buffer_offset < buffer size
            jb      read_file_byte              ; we still have more to look through

exit:

    ; exit
    mov     rax, 60     ; exit
    xor     rdi, rdi
    syscall
