section .data
    stack_pointer       dq 0    ; the index of the currently selected stack item
    file_buffer_offset  dq 0    ; the index of the current token in the file
    skip_loop_count     dq 0    ; how many closing ']' to skip
    stack times 30000   dq 0    ; the stack

section .text
    global _start

; Read a file into a buffer and return it
; inputs:
;       rdi : filename
; outputs:
;       rax : file contents buffer
;       rdi : number of bytes allocated
;       rsi : the size of the buffer allocation
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

; increment the currently selected cell (stack_pointer)
inc_current_cell:
    mov     rsi, [stack_pointer]        ; the index of the current selected item in stack
    mov     rax, [stack + rsi * 8]      ; get the item at the current index in stack and store it in rax
    inc     rax                         ; increment the item by 1

    mov     [stack + rsi * 8], rax      ; overwrite the item with it's new value
    jmp     increment_file_ptr_and_continue

; decrement the currently selected cell (stack_pointer)
dec_current_cell:
    mov     rsi, [stack_pointer]        ; the index of the current selected item in stack
    mov     rax, [stack + rsi * 8]      ; get the item at the current index in stack and store it in rax
    dec     rax                         ; decrement the item by 1

    mov     [stack + rsi * 8], rax      ; overwrite the item with it's new value
    jmp     increment_file_ptr_and_continue

; seek left instruction. increments the stack pointer by 1
seek_left:
    mov     rax, [stack_pointer]    ; put the current stack pointer in rax
    dec     rax                     ; decrement the stack pointer by one (move it to the left)
    mov     [stack_pointer], rax    ; store new stack pointer
    jmp     increment_file_ptr_and_continue

; seek right instruction. decrements the stack pointer by 1
seek_right:
    mov     rax, [stack_pointer]    ; put the current stack pointer in rax
    inc     rax                     ; increment the stack pointer by one (move it to the right)
    mov     [stack_pointer], rax    ; store new stack pointer
    jmp     increment_file_ptr_and_continue

; print the currently selected cell as ASCII
print_current_cell:
    mov     rax, [stack_pointer]    ; the index of the current selected item in stack
    mov     rbx, [stack + rax * 8]  ; get the item at the current index in stack and store it in rbx
    push    rbx                     ; push rbx (the character to print) to the stack
    mov     rsi, rsp                ; the address of what to print (top of stack)
    mov     rax, 1                  ; write
    mov     rdi, 1                  ; stdout
    mov     rdx, 1                  ; len
    syscall

    add     rsp, 8                  ; pop character from stack
    jmp     increment_file_ptr_and_continue

; instructions for starting a loop (`[`)
start_loop:
    ; first, we check if we're currently skipping a loop
    ; this can happen if the current cell is 0 when '[' is encountered
    mov     rsi, [skip_loop_count]  ; load loop count into rsi
    cmp     rsi, 0
    jg      increment_skip_loop     ; if rsi > 0; increment the skip by 1

    ; now, we know that we aren't currently skipping a loop. check if we should be skipping the upcoming loop
    mov     rsi, [stack_pointer]    ; the index of the current selected item in stack
    mov     rax, [stack + rsi * 8]  ; get the item at the current index in stack and store it in rax
    cmp     rax, 0                  ; check if current cell is zero
    je      increment_skip_loop     ; if current_cell == 0; increment the skip counter

    ; we don't need to skip the loop, push the instruction ptr to the stack
    mov     rax, [file_buffer_offset]   ; load file buffer offset into rax
    push    rax                         ; push rax to stack
                                        ; now we can pop the stack and jump to read_file_byte to restart the loop
    jmp increment_file_ptr_and_continue ; resume program flow

; increment the skip loop count and continue program flow
increment_skip_loop:
    mov     rsi, [skip_loop_count]      ; load skip loop count into rsi
    inc     rsi                         ; increment rsi by 1
    mov     [skip_loop_count], rsi      ; store rsi to skip_loop_count
    jmp increment_file_ptr_and_continue ; resume program

; instructions for ending a loop (`]`)
end_loop:
    ; first, we check if we are currently skipping a loop
    mov     rsi, [skip_loop_count]  ; load loop count into rsi
    cmp     rsi, 0
    jg      decrement_skip_loop     ; if rsi > 0; decrement the skip by 1

    ; now, we know that we aren't currently skipping a loop. check if we should continue the loop or not
    pop     rax                                 ; pop the top item of the stack (instruction pointer) into rax
                                                ; we pop this off now because we need to pop it whether we're ending or not

    mov     rsi, [stack_pointer]                ; the index of the current selected item in stack
    mov     rbx, [stack + rsi * 8]              ; get the item at the current index in stack and store it in rbx
    cmp     rbx, 0                              ; check if current cell is zero
    je      increment_file_ptr_and_continue     ; if current_cell == 0; dont repeat the loop

    ; we must repeat the loop
    mov     [file_buffer_offset], rax   ; set that item as the current file buffer
    jmp read_file_byte                  ; loop to reading the file at that byte

; decrement the skip loop count and continue program flow
decrement_skip_loop:
    mov     rsi, [skip_loop_count]      ; load skip loop count into rsi
    dec     rsi                         ; decrement rsi by 1
    mov     [skip_loop_count], rsi      ; store rsi to skip_loop_count
    jmp increment_file_ptr_and_continue ; resume program

; take 1 byte of user input and store it in the currently selected cell
take_input:
    xor     rax, rax    ; clear out rax just in case
    push    rax         ; push rax onto the stack so we can read to it

    mov     rsi, rsp    ; the address of the rax we just pushed
    xor     rdi, rdi    ; stdin
                        ; rax is already 0 (read) from when we xor'd it at the beginning
    mov     rdx, 1      ; 1 byte
    syscall

    pop     rax                     ; pop rax for use
    mov     rsi, [stack_pointer]    ; the index of the current selected item in stack
    mov     [stack + rsi * 8], rax  ; put byte we read into the current cell

    jmp increment_file_ptr_and_continue

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

        ; loops are executed before loop checking to calculate the correct exit point
        cmp     rax, '['                    ; check if the current token is '['
        je      start_loop                  ; it is, execute instruction
        cmp     rax, ']'                    ; check if the current token is ']'
        je      end_loop                    ; it is, execute instruction

        ; check if we are inside a loop that we are skipping
        mov     rbx, [skip_loop_count]              ; load skip_loop_count into rbx
        cmp     rbx, 0                              ; if rbx > 0
        jg      increment_file_ptr_and_continue     ; skip the current token and continue

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
        cmp     rax, ','                    ; check if the current token is ','
        je      take_input                  ; it is, execute instruction

        increment_file_ptr_and_continue:
            mov     rax, [file_buffer_offset]   ; load the current file buffer offset into rax
            inc     rax                         ; increment file buffer pointer by 1
            mov     [file_buffer_offset], rax   ; save the new file buffer offset

            ; check if we've gone through the entire file
            cmp     [file_buffer_offset], r14   ; check if file_buffer_offset < buffer size
            jb      read_file_byte              ; we still have more to look through

exit:
    ; exit
    mov     rax, 60
    xor     rdi, rdi
    syscall
