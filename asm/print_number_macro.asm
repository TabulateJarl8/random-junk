section .text
    global _start

%macro print_integer 1
    ;    mov      [%1], ax
    %assign i 1
%endmacro

_start:
    exit:
        mov     rax, 60
        mov     rdi, 0
        syscall ; call kernel