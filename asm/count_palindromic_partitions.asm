bits 64

section .data

section .text
    global _start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Integer printing system ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Calculate the power of 10 that corresponds to an integer
; for example, 100 for 543, 1000 for 8956, and 10000 for 15236
; inputs:
;       rax : the integer to calculate the 10 power for
; outputs:
;       rax : the power of 10
calculate_ten_power:
    mov     rcx, rax        ; rcx should be the integer to find the power of 10 for

    mov     rax, 1          ; we need to calculate the power of 10 that corresponds to rcx
                            ; for example 100 for 543 and 1000 for 8753
    mov     rbx, 10         ; we're multiplying the value in rax by 10 each time, load into rbx
    .calculate_ten:
        mul     rbx                 ; rax * rbx (10)
        cmp     rax, rcx            ; compare rax to our target number
        jg      .finish_power_ten    ; if number is greater than target, divide by 10 and ret
        jmp     .calculate_ten       ; not greater than target, continue multiplying

    .finish_power_ten:
        xor     rdx, rdx    ; clear our rdx (remainder)
        div     rbx         ; divide rax by 10 to finish the calculation
                            ; now rax contains the power of 10
        ret

; Prints a single digit
; inputs:
;       rsi : the digit to print
print_digit:
    add     rsi, '0'                ; convert digit to ASCII
    push    rsi                     ; put the digit on the stack
    mov     rsi, rsp                ; put pointer to stack for *buf
    mov     rax, 1                  ; write
    mov     rdi, 1                  ; stdout
    mov     rdx, 1                  ; len
    syscall                         ; call kernel

    add     rsp, 8                  ; remove digit from stack

    ret

; Print a multi-digit integer
; inputs:
;       rax : the integer to print
print_integer:
    ; takes the integer to print in from rax
    push    rax                 ; push rax it for the next function to consume
    call    calculate_ten_power ; power of 10 is now in rax
    mov     rcx, rax            ; save the power of 10 into rcx
    pop     rax                 ; mov the argument (number to print) that was pushed into rax

    .iter_number:
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
        mov     rsi, rdx    ; move rdx into rsi
        push    rcx         ; preserve our power of 10
        call    print_digit ; print the digit we extracted
        pop     rcx         ; pop the power of 10 from the stack

        mov     rax, 1
        cmp     rax, rcx            ; check if rcx is equal to 1. if so, we just did the last digit
        je      .exit_print_integer  ; we juts did the last digit, exit printing

        xor     rdx, rdx    ; clear rdx (remainder)
        mov     rbx, 10     ; put 10 in rbx
        mov     rax, rcx    ; put our power of 10 in rax

        div     rbx         ; divide power of 10 by 10 to get the next digit
        mov     rcx, rax    ; move result into rcx

        pop     rax         ; restore our original number to print

        jmp .iter_number     ; loop to iter_number until rcx is 1 (we've done the last digit)

    .exit_print_integer:
        pop     rax     ; pop off our original number so that we return to the correct address
        ret

;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM BODY ;;
;;;;;;;;;;;;;;;;;;;;;;;

; check if a portion of a given string is a palindrome
; inputs:
;       rdi : pointer to string
;       rsi : start index
;       rdx : end index
; outputs:
;       rax : 1 if true, 0 if false
is_palindrome:
    dec     rdx
    jmp     .is_palindrome_cnd      ; execute while loop conditional first
    .is_palindrome_loop:
    ; loop body

    mov     al, byte [rdi + rsi]    ; get char at s[start]
    cmp     al, byte [rdi + rdx]    ; if s[start] != s[end]
    jne     .is_palindrome_false

    ; keep checking palindrome
    inc     rsi
    dec     rdx

    .is_palindrome_cnd:             ; conditional check
    cmp     rsi, rdx
    jl      .is_palindrome_loop     ; while start < end

    ; out of loop body, return 1
    mov     rax, 1                  ; return 1
    ret

    ; false branch
    .is_palindrome_false:
    mov     rax, 0                  ; return 0
    ret

; implementation of strlen
; inputs:
;       rdi : address of buffer
; outputs:
;       rax : length of the string, not including the null byte
strlen:
    xor     rax, rax                    ; clear count register
    .strlen_inc:
        movzx   rcx, byte [rdi + rax]   ; get the byte at *(buffer + rax)
        test    rcx, rcx                ; test if the selected byte is NULL
        je      .strlen_done             ; if NULL, jump to the end of the loop and return
        inc     rax                     ; not NULL, so we increment and check the next byte
        jmp     .strlen_inc              ; jump back to the start of the loop
    .strlen_done:
        ret

; count number of palindrome partitions in a string
; inputs:
;       rdi : pointer to string
;       rsi : index
;       rdx : length of string
; outputs:
;       rax : number of partitions
count:
    cmp     rsi, rdx        ; if index == length_s
    je      .base_case      ; return 1

    ; recursive step
    xor     r8, r8          ; partitions count = 0
    ; for loop
    mov     rcx, rsi        ; int i = index + 1
    inc     rcx
    .loop:
    ; loop body

    ; save length of string and index
    push    rsi
    push    rdx

    ; rsi is already start index, set rdx to i
    mov     rdx, rcx
    call    is_palindrome

    ; restore lenght of string and index
    pop     rdx
    pop     rsi

    ; if is_palindrome == 0
    test    rax, rax
    jz     .no_partitions      ; if palindrome was not found, just continue looping

    ; here, partitions were found so we update r8
    ; recursively call the count function with our current i value
    push    rcx
    push    r8
    push    rsi

    mov     rsi, rcx            ; set current i as index for next call
    call    count

    ; restore
    pop     rsi
    pop     r8
    pop     rcx

    ; update paritions count with return value
    add     r8, rax

    .no_partitions:

    ; end of for loop
    inc     rcx          ; i++
    cmp     rcx, rdx     ; loop while i <= length_s
    jle     .loop

    ; end of loop, return partition count
    mov     rax, r8
    ret

    .base_case:
    mov     rax, 1      ; return 1
    ret


_start:
    add     rsp, 16     ; skip argc and argv[0]
    pop     rdi         ; get first argument as string to check

    call    strlen      ; get length of string in rax
    mov     rdx, rax    ; store in rdx

    xor     rsi, rsi    ; start with index = 0

    call    count

    ; result is in rax, print it
    call    print_integer

    mov     rax, 1      ; write
    mov     rdi, 1      ; stdout
    push    0xa         ; newline
    mov     rsi, rsp    ; print stack pointer
    mov     rdx, 1      ; 1 char
    syscall             ; print

    pop     rax         ; remove junk

    mov     rdi, 0      ; code 0
    mov     rax, 60     ; exit
    syscall
