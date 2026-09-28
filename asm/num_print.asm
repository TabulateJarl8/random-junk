bits 64
; Print "number i" for i in range(5,60)
section .data
    line_text db "number "
    line_text_len equ $ - line_text

section .text
    global _start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Integer printing system ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Print a multi-digit integer
; inputs:
;       rax : the integer to print
print_integer:
    sub     rsp, 24     ; allocate 24 bytes in rcx (20 digit max for 64bit int)
    mov     rcx, 24     ; ptr at end of buffer (RTL digit extraction, we work backwards)
    mov     rbx, 10     ; divisor

    ; check if negative
    xor     r8, r8      ; r8 = is_negative
    test    rax, rax
    jns     .digit_loop ; if not negative, continue as normal

    neg     rax         ; make positive if negative
    mov     r8, 1       ; set is_negative true

    .digit_loop:
        xor     rdx, rdx
        div     rbx                 ; rax = rax / 10; rdx = rax % 10
        add     dl, '0'             ; convert to ASCII
        dec     rcx                 ; move index backwards
        mov     [rsp + rcx], dl     ; store digit at rsp + offset

        ; while quotient > 0, loop
        test    rax, rax
        jnz     .digit_loop

    ; if not negative, skip adding '-' in front
    test    r8, r8
    jz      .print_buffer

    ; we are negative, add '-'
    dec     rcx
    mov     [rsp + rcx], '-'

    .print_buffer:
    mov     rax, 1              ; write
    mov     rdi, 1              ; stdout
    lea     rsi, [rsp + rcx]    ; buffer addr
    mov     rdx, 24             ; length = 24 - rcx
    sub     rdx, rcx            ; ...
    syscall

    add     rsp, 24     ; reset stack
    ret

_start:
    mov rax, 5
    call print_integer

    exit:
        mov rax, 60
        mov rdi, 0
        syscall ; call kernel
