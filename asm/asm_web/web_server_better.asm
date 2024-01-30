section .data
    filename db "/usr/bin/nginx", 0

section .text
    global _start

_start:
    mov     rax, 59         ; execve
    mov     rdi, filename   ; filename
    xor     rsi, rsi        ; no args
    xor     rdx, rdx        ; nothing in envp
    syscall

    mov     rax, 60         ; exit
    xor     rdi, rdi        ; status 0
    syscall