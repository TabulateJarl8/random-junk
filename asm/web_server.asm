section .data
    server_ready_msg db  "Bound and listening on 127.0.0.1:8000...", 0xa
    server_ready_msg_len equ $ - server_ready_msg

    http_200_resp:
        db "HTTP/1.0 200 OK", 0xa
        db "Server: best-asm", 0xa
        db "Content-Type: text/html", 0xa, 0xa
        db "<html>IVE DONE IT IT WORKS AT LONG LAST</html>"
    http_200_resp_len equ $ - http_200_resp

    BUFFER_READ_SIZE equ 2048

section .bss
    client_read_buffer resb BUFFER_READ_SIZE

section .text
    global _start

; print the first line of a buffer. something will go terribly wrong if it doesn't contain a newline
; because im too lazy to also take in the buffer length
; inputs:
;       rsi : the address of the buffer
print_first_line:
    xor     rcx, rcx                ; init a counter
    check_for_newline:
        mov     al, [rsi + rcx]     ; load current character into rax
        inc     rcx                 ; increment the counter (this includes the newline in the write once we encounter it at the end)
        cmp     al, 0xa             ; compare current character with newline
        jne     check_for_newline   ; check the next character, we haven't found the newline

    end_newline_loop:
        mov     rax, 1              ; write
        mov     rdi, 1              ; stdout
                                    ; rsi already contains our buffer address
        mov     rdx, rcx            ; our counter contains the amount of data to print
        syscall

        ret

; create a socket and return it's file descriptor. exits on error
; outputs:
;       rax : socket file descriptor
create_socket:
    mov     rax, 41     ; socket
    mov     rdi, 2      ; domain = AF_INET (IPv4 IPs)
    mov     rsi, 1      ; type = SOCK_STREAM
    xor     rdx, rdx    ; protocol = automatic
    syscall             ; create socket and store fd in rax

    mov     rdi, 1      ; set exit return value to 1 in case we jump
    test    rax, rax    ; socket fd will be -1 if error
    js      exit        ; jump to exit if sign flag is present

    ret

; bind a socket to localhost at PORT. exits on error
; inputs:
;       r15 : socket fd
sock_bind:
    mov     rdi, r15            ; move socket fd into rdi

    ; set up sockaddr struct in the stack. see bind(2)
    push    dword   0           ; 4-byte address padding
    push    dword   0x0100007F  ; 127.0.0.1
    push    word    0x401f      ; 8000 (port)
    push    word    2           ; AF_INET

    mov     rax, 49             ; bind
    mov     rsi, rsp            ; put address of struct into rsi
    mov     rdx, 32             ; size of struct
    syscall

    add     rsp, 20             ; restore stack pointer to correct address

    mov     rdi, 2              ; bind error code
    test    rax, rax            ; test if rax == -1
    js      exit                ; if it is, jump to exit

    ret

; listen for connections on a given socket. exits on error
; inputs:
;       r15 : socket fd
sock_listen:
    mov     rax, 50     ; listen
    mov     rdi, r15    ; store socket fd in rdi
    mov     rsi, 4096   ; socket max backlog connections (SOMAXCONN)
    syscall

    mov     rdi, 3      ; listen error code
    test    rax, rax    ; test rax
    js      exit        ; if rax == -1; exit

    ret

; accept a connection on a socket
; inputs:
;       r15 : socket fd
; outputs:
;       rax : new socket fd for the accepted connection
sock_accept:
    mov     rax, 43     ; accept
    mov     rdi, r15    ; put socket fd into rdi
    xor     rsi, rsi    ; null out address ptr
    xor     rdx, rdx    ; size of 0
    syscall

    mov     rdi, 4      ; error code for sock_accept
    test    rax, rax    ; test rax
    js      exit        ; if rax == -1; exit

    ret

; closes a socket connection so that it can be reused
; inputs:
;       rax : socket fd
sock_close:
    mov     rdi, rax    ; fd to close
    mov     rax, 3      ; close
    syscall

    ret

_start:
    call    create_socket   ; create a socket and store it in rax
    mov     r15, rax        ; save socket fd in r15

    ; bind
    call    sock_bind       ; bind the socket to 127.0.0.1:8000

    call    sock_listen     ; make the socket listen

    ; print server ready message
    mov     rax, 1                      ; write
    mov     rdi, 1                      ; stdout
    mov     rsi, server_ready_msg       ; buffer
    mov     rdx, server_ready_msg_len   ; buffer length
    syscall

    connection_loop:
        call    sock_accept             ; accept incoming connections 
        mov     r14, rax                ; move new fd into r14

        ; read from socket into client_read_buffer
        mov     rax, 0                  ; read
        mov     rdi, r14                ; new socket fd
        mov     rsi, client_read_buffer ; buffer to read into
        mov     rdx, BUFFER_READ_SIZE   ; amount of bytes to read
        syscall

        mov     rdi, 5                  ; error code for sock_read
        test    rax, rax                ; test rax
        js      exit                    ; if rax == -1; exit

        mov     rsi, client_read_buffer ; the headers we recieved from the client
        call    print_first_line        ; print the first line for logging purposes

        ; write to socket
        mov     rax, 1                  ; write
        mov     rdi, r14                ; put the new fiile descriptor in rdi
        mov     rsi, http_200_resp      ; http 200 response
        mov     rdx, http_200_resp_len  ; http 200 response length
        syscall

        mov     rdi, 6                  ; error code for socket write
        test    rax, rax                ; test rax
        js      exit                    ; if rax == -1; exit

        mov     rax, r14                ; move new file descriptor into rax
        call    sock_close              ; close the new socket file descriptor

        jmp     connection_loop         ; accept more connections

; exit the program. rdi must be set before jumping here
; error codes:
;   1 - socket creation error
;   2 - socket bind error
;   3 - socket listen error
;   4 - socket accept error
;   5 - socket read error
;   6 - socket write error

exit:
    neg     rax         ; negate rax to see errno in debugging
    mov     rax, 60     ; exit
    syscall