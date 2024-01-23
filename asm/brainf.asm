section .data
    stack_pointer dq 0
    file_buffer_offset dq 0
    str_buffer db 0
    stack times 30000 dq 0

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
    mov     rcx, [rsp+8]    ; rcx should be the integer to find the power of 10 for

    mov     rax, 1          ; we need to calculate the power of 10 that corresponds to rcx
                            ; for example 100 for 543 and 1000 for 8753
    mov     rbx, 10         ; we're multiplying the value in rax by 10 each time, load into rbx
    calculate_ten:
        mul     rbx                 ; rax * rbx (10)
        cmp     rax, rcx            ; compare rax to our target number
        jg      finish_power_ten    ; if number is greater than target, divide by 10 and ret
        jmp     calculate_ten       ; not greater than target, continue multiplying

    finish_power_ten:
        xor     rdx, rdx    ; clear our rdx (remainder)
        div     rbx         ; divide rax by 10 to finish the calculation
                            ; now rax contains the power of 10
        mov     rcx, rax    ; put rax in rcx
        ret


print_digit:
    ; print a digit
    ; takes an argument on the stack
    ; returns nothing
    push    rcx                     ; push rcx to the stack
    mov     rcx, [rsp+16]           ; get the third argument on the stack. [return address (+0)] -> [rcx (+8)] -> [digit to print (+16)]
    add     rcx, '0'                ; convert digit to ASCII

    mov     byte [str_buffer], cl   ; assign lower 8 bits of rcx to buffer

    mov     rsi, str_buffer         ; buffer pointer
    mov     rax, 1                  ; write
    mov     rdi, 1                  ; stdout
    mov     rdx, 1                  ; len
    syscall                         ; call kernel

    pop     rcx                     ; restore rcx

    ret


print_integer:
    ; takes the integer to print in from rax
    push    rax                 ; push rax it for the next function to consume
    call    calculate_ten_power ; power of 10 is now in rcx

    pop     rax                 ; mov the argument (number to print) that was pushed into rax

    iter_number:
        ; num_to_print: rax
        ; base_10_place: rcx
        ; formula for accessing number: (num_to_print // base_10_place) % 10
        ; base_10_place is the power of 10 that corresponds to the place of number to print
        ; using 123 for example, 100 will get the 1, 10 will get the 2, and 1 will get the 3

        push    rax         ; first, make sure we have a copy of rax

        mov     rbx, 10     ; 10 for use in modulo

        
        xor     rdx, rdx    ; clear out rdx (remainder)
        div     rcx         ; next, floor divide rax by rcx (num_to_print // base_10_place)
                            ; result is stored in rax, mod 10
        xor     rdx, rdx    ; clear out rdx because thats where remainder is stored
        div     rbx         ; divide rax by rbx (rax % 10)
                            ; rdx now contains our digit to print
        push    rdx         ; save rdx
        call    print_digit ; print the digit we extracted
        add     rsp, 8      ; remove the rdx that never got popped from print_digit from the stack


        mov     rax, 1
        cmp     rax, rcx            ; check if rcx is equal to 1. if so, we just did the last digit
        je      exit_print_integer  ; we juts did the last digit, exit printing

        xor     rdx, rdx    ; clear rdx (remainder)
        mov     rbx, 10     ; put 10 in rbx
        mov     rax, rcx    ; put our power of 10 in rax

        div     rbx         ; divide power of 10 by 10 to get the next digit
        mov     rcx, rax    ; move result into rcx

        pop     rax         ; restore our original number to print

        jmp iter_number     ; loop to iter_number until rcx is 1 (we've done the last digit)

    exit_print_integer:
        pop     rax     ; pop off our original number so that we return to the correct address
        ret

; increment the currently selected cell (stack_pointer)
inc_current_cell:
    mov     rsi, [stack_pointer]    ; the index of the current selected item in stack
    mov     rax, [stack + rsi]      ; get the item at the current index in stack and store it in rax
    inc     rax                     ; increment the item by 1

    mov     [stack + rsi], rax      ; overwrite the item with it's new value
    jmp     increment_file_ptr_and_continue

; decrement the currently selected cell (stack_pointer)
dec_current_cell:
    mov     rsi, [stack_pointer]    ; the index of the current selected item in stack
    mov     rax, [stack + rsi]      ; get the item at the current index in stack and store it in rax
    dec     rax                     ; increment the item by 1

    mov     [stack + rsi], rax      ; overwrite the item with it's new value
    jmp     increment_file_ptr_and_continue

; seek left
seek_left:
    mov     rax, [stack_pointer]    ; put the current stack pointer in rax
    dec     rax                     ; decrement the stack pointer by one (move it to the left)
    mov     [stack_pointer], rax    ; store new stack pointer
    jmp     increment_file_ptr_and_continue

; seek right
seek_right:
    mov     rax, [stack_pointer]    ; put the current stack pointer in rax
    inc     rax                     ; increment the stack pointer by one (move it to the right)
    mov     [stack_pointer], rax    ; store new stack pointer
    jmp     increment_file_ptr_and_continue

; print the currently selected cell
print_current_cell:
    mov     rax, [stack_pointer]    ; the index of the current selected item in stack
    mov     rbx, [stack + rax]      ; get the item at the current index in stack and store it in rbx
    push    rbx                     ; push rbx (the character to print) to the stack
    mov     rsi, rsp                ; the address of what to print (top of stack)
    mov     rax, 1                  ; write
    mov     rdi, 1                  ; stdout
    mov     rdx, 1                  ; len
    syscall

    add     rsp, 8                  ; pop character from stack
    jmp     increment_file_ptr_and_continue

_start:
    ; get arguments
    add     rsp, 16     ; skip argc and argv[0]
    pop     rdi         ; get first argument as file to read

    cmp     rdi, 0      ; check for no arguments
    je      exit

    call    read_file

    mov     r12, rdi    ; number of allocates bytes (pages)
    mov     r13, rax    ; buffer addr
    mov     r14, rsi    ; buffer size 

    read_file_byte:
        mov     rsi, r13                    ; load buffer addr
        add     rsi, [file_buffer_offset]   ; increment it to get our current token
        movzx   rax, byte [rsi]             ; load the current token into rax

        cmp     rax, '+'                    ; check if the current token is '+'
        je      inc_current_cell            ; it is, execute instruction
        cmp     rax, '-'                    ; check if the current token is '-'
        je      dec_current_cell            ; it is, execute instruction
        cmp     rax, '<'                    ; check if the current token is '<'
        je      seek_left                   ; it is, execute instruction
        cmp     rax, '>'                    ; check if the current token is '>'
        je      seek_right                  ; it is, execute instruction
        cmp     rax, '.'                    ; check if the current token is '.'
        je      print_current_cell          ; it is, execute instruction

        increment_file_ptr_and_continue:
            mov     rax, [file_buffer_offset]   ; load the current file buffer offset into rax
            inc     rax                         ; increment file buffer pointer by 1
            mov     [file_buffer_offset], rax   ; save the new file buffer offset

            ; check if we've gone through the entire file
            cmp     [file_buffer_offset], r14   ; check if file_buffer_offset < buffer size
            jb      read_file_byte              ; we still have more to look through

exit:

    ; exit
    mov     rax, 60     ; exit
    xor     rdi, rdi
    syscall
