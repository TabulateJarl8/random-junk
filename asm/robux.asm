section .data
    string_buffer times 35  db 0
    string_buffer_len       equ $ - string_buffer       ; string buffer lenth
    filename_len            equ string_buffer_len - 5   ; subtract 5 for the extension and null byte at the end
    first_half              db "HERE IS "
    first_half_len          equ $ - first_half
    second_half             db " ROBUXES FOR YOU!!!!"
    second_half_len         equ $ - second_half
    character_set           db "abcdefghijklmnopqrstuvwxyz0123456789"
    character_set_len       equ $ - character_set

    seed                    dd 0

section .text
    global _start

; Get the current time in ms to use as the seed
srand:
    mov     rax, 96         ; gettimeofday
    lea     rdi, [rsp - 16] ; load address of time struct into rdi
    xor     esi, esi        ; clear esi (second arg for syscall)
    syscall
    mov     ecx, 1000
    mov     rax, [rdi + 8]  ; load microseconds portion into rax
    xor     edx, edx        ; clear edx for division
    div     rcx             ; divide by 1000 to get milliseconds
    mov     rdx, [rdi]      ; load seconds portion of time into rdx
    imul    rdx, rcx        ; multiply seconds by 1000 to get ms
    add     rax, rdx        ; add the ms from the microseconds and seconds together to get the current ms

    ; milliseconds are in rax now
    mov     [seed], rax     ; Store the seed in the 'seed' variable

    ret


; Algorithm to generate a pseudo-random number.
; outputs:
;       rax : the pseudo-random number.
rand:
    mov     rax, [seed]         ; load seed value into rax
    imul    rax, 1103515245     ; multiply seed
    add     rax, 12345          ; add 12345 to seed
    mov     rbx, rax            ; preserve generated number in rbx
    mov     [seed], rbx         ; update seed with new value

    mov     rax, rbx            ; Return the generated number in rax
    and     rax, 0x7FFFFFFF     ; Ensure rax is a positive number
    ret


; generate random integer in inclusive range
; (rand() % (max - min + 1)) + min
; inputs:
;       rax : min
;       rbx : max
; outputs:
;       rax : result
randint:
    push    rax         ; preserve parameters
    push    rbx
    
    call    rand        ; store random int in rax

    mov     rcx, rax    ; transfer random int into rcx
    
    pop     rbx         ; restore saved parameters
    pop     rax

    sub     rbx, rax    ; calculate divisor of modulo (rbx - rax + 1)
    inc     rbx         ; increment rbx by 1
                        ; divisor is now stored in rbx.

    push    rax         ; preserve rax (min value)

    xor     rdx, rdx    ; clear rdx for modulo operation
    mov     rax, rcx    ; transfer random number (dividend) to rax
    div     rbx         ; rbx contains our divisor
                        ; rdx now contains the modulo result
    pop     rax         ; restore rax

    add     rax, rdx    ; add rax and rdx to get our result

    ret                 ; return rax

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
    calculate_ten:
        mul     rbx                 ; rax * rbx (10)
        cmp     rax, rcx            ; compare rax to our target number
        jg      finish_power_ten    ; if number is greater than target, divide by 10 and ret
        jmp     calculate_ten       ; not greater than target, continue multiplying

    finish_power_ten:
        xor     rdx, rdx    ; clear our rdx (remainder)
        div     rbx         ; divide rax by 10 to finish the calculation
                            ; now rax contains the power of 10
        ret

; Writes a single digit to a fd
; inputs:
;       rsi : the digit to write
;       r15 : the fd to write to
write_digit:
    add     rsi, '0'                ; convert digit to ASCII
    push    rsi                     ; put the digit on the stack
    mov     rsi, rsp                ; put pointer to stack for *buf
    mov     rax, 1                  ; write
    mov     rdi, r15                ; fd
    mov     rdx, 1                  ; len
    syscall                         ; call kernel

    add     rsp, 8                  ; remove digit from stack

    ret

; Write a multi-digit integer
; inputs:
;       rax : the integer to write
;       r15 : the fd to write to
write_integer:
    ; takes the integer to write in from rax
    push    rax                 ; push rax it for the next function to consume
    call    calculate_ten_power ; power of 10 is now in rax
    mov     rcx, rax            ; save the power of 10 into rcx
    pop     rax                 ; mov the argument (number to write) that was pushed into rax

    iter_number:
        ; num_to_write: rax
        ; base_10_place: rcx
        ; formula for accessing number: (num_to_write // base_10_place) % 10
        ; base_10_place is the power of 10 that corresponds to the place of number to write
        ; using 123 for example, 100 will get the 1, 10 will get the 2, and 1 will get the 3

        push    rax         ; first, make sure we have a copy of rax

        mov     rbx, 10     ; 10 for use in modulo

        
        xor     rdx, rdx    ; clear out rdx (remainder)
        div     rcx         ; next, floor divide rax by rcx (num_to_write // base_10_place)
                            ; result is stored in rax, mod 10
        xor     rdx, rdx    ; clear out rdx because thats where remainder is stored
        div     rbx         ; divide rax by rbx (rax % 10)
                            ; rdx now contains our digit to write
        mov     rsi, rdx    ; move rdx into rsi
        push    rcx         ; preserve our power of 10
        call    write_digit ; write the digit we extracted
        pop     rcx         ; pop the power of 10 from the stack

        mov     rax, 1
        cmp     rax, rcx            ; check if rcx is equal to 1. if so, we just did the last digit
        je      exit_write_integer  ; we juts did the last digit, exit writing

        xor     rdx, rdx    ; clear rdx (remainder)
        mov     rbx, 10     ; put 10 in rbx
        mov     rax, rcx    ; put our power of 10 in rax

        div     rbx         ; divide power of 10 by 10 to get the next digit
        mov     rcx, rax    ; move result into rcx

        pop     rax         ; restore our original number to write

        jmp iter_number     ; loop to iter_number until rcx is 1 (we've done the last digit)

    exit_write_integer:
        pop     rax     ; pop off our original number so that we return to the correct address
        ret


; Writes a file with permissions of 644. file is created if it doesn't exist
; inputs:
;       rax : the filename
;       rbx : the number of robux
write_file:
    ; open file
    mov     rdi, rax                ; filename
    mov     rax, 2                  ; open
    mov     rsi, 0x241              ; O_WRONLY | O_CREAT | O_TRUNC
    mov     rdx, 0o644              ; file permissions
    syscall                         ; stores fd in rax

    mov     r15, rax                ; save fd

    ; write file with first half of message
    mov     rax,    1               ; write
    mov     rdi,    r15             ; fd
    mov     rsi,    first_half      ; first half of the message
    mov     rdx,    first_half_len  ; len
    syscall

    mov     rax, rbx                ; move number of robux into rax
    call    write_integer           ; write number of robux to fd (r15)

    ; write second half of message
    mov     rax,    1               ; write
    mov     rdi,    r15             ; fd
    mov     rsi,    second_half     ; second half of the message
    mov     rdx,    second_half_len ; len
    syscall

    ; close file
    mov     rax, 3                  ; close
    mov     rdi, r15                ; fd
    syscall

    ret

; null out the string buffer variable
clear_string_buffer:
    mov     rdi, string_buffer      ; load address of string buffer into rdi
    mov     rsi, string_buffer_len  ; length of string buffer
    xor     rcx, rcx                ; index counter
    xor     rax, rax                ; null character

    clear_char:
        mov     [rdi + rcx], al     ; move null byte into current char address
        inc     rcx                 ; increment index counter
        cmp     rcx, rsi            ; check if we've reached the end of the string
        jl      clear_char

        ret

; create a filename between 1-30 characters with a random 3 character extension
; outputs:
;       clears string_buffer and fills it with a random filename
create_filename:
    call    clear_string_buffer     ; clear the string buffer

    ; generate length of filename
    mov     rax, 1                  ; min - 1
    mov     rbx, filename_len       ; max
    call    randint                 ; rax contains our filename length
    add     rax, 4                  ; add 4 to the length for the extension. the length will now be at least 5
    mov     r13, rax                ; move our length into r13
    xor     r12, r12                ; initialize a counter

    generate_char:
        mov     rsi, r13                            ; our full string length
        sub     rsi, 4                              ; subtract 4 from the string length (the position for the . in the filename)
        cmp     r12, rsi                            ; should we be inserting a . or a character
        je      insert_dot                          ; we should be, insert a .
        xor     rax, rax                            ; min - 0
        mov     rbx, character_set_len              ; max
        call    randint                             ; get a random integer
                                                    ; rax contains our random int now

        mov     al, [character_set + rax]           ; load the selected character into al
        mov     [string_buffer + r12], al           ; get the randomly selected character and append it to the string buffer

        inc     r12                                 ; increment our counter
        cmp     r12, r13                            ; check if we've reached the end of the loop
        je      finish_filename                     ; we have, return
        jmp     generate_char                       ; we're not done, create another character

    insert_dot:
        mov     byte [string_buffer + r12], 0x2e    ; append '.' to the string buffer
        inc     r12                                 ; increment our loop counter
        jmp     generate_char                       ; continue generation

    finish_filename:
        ret

_start:
    call    srand   ; seed rng
    mov     r14, 0  ; store robux amount in r14

    file_creation_loop:
        call    create_filename     ; create a filename and store it in string_buffer
        mov     rax, string_buffer  ; put address of string_buffer in rax
        mov     rbx, r14            ; move robux count to rbx
        call    write_file          ; write the file
        inc     r14                 ; increment robux count by 1
        jmp     file_creation_loop  ; create another file

    exit:
        mov     rax, 60
        mov     rdi, 0
        syscall ; call kernel