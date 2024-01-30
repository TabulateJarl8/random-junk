section .data
    server_ready_msg_pt1 db "Bound and listening on http://127.0.0.1:"
    server_ready_msg_pt1_len equ $ - server_ready_msg_pt1

    server_ready_msg_pt2 db  "...", 0xa
    server_ready_msg_pt2_len equ $ - server_ready_msg_pt2

    error_messages:
        db "Error in socket creation",          0xa
        db "Error in socket bind", 0, 0, 0, 0,  0xa
        db "Error in socket listen", 0, 0,      0xa
        db "Error in socket accept", 0, 0,      0xa
        db "Error in socket read", 0, 0, 0, 0,  0xa
        db "Error in socket write", 0, 0, 0,    0xa

    error_message_length equ 25

    http_200_resp:
        db "HTTP/1.0 200 OK", 0xa
        db "Server: TabulateASM", 0xa
        db "Content-Type: text/html", 0xa, 0xa
    http_200_resp_len equ $ - http_200_resp

    http_404_resp:
        db "HTTP/1.0 404 Not Found", 0xa
        db "Server: TabulateASM", 0xa
        db "Content-Type: text/html", 0xa, 0xa
        db "<html><head><title>Page Not Found</title></head><body><center><h1>404 Not Found</h1></center><hr></body></html>"
    http_404_resp_len equ $ - http_404_resp

    http_500_resp:
        db "HTTP/1.0 500 Internal Server Error", 0xa
        db "Server: TabulateASM", 0xa
        db "Content-Type: text/html", 0xa, 0xa
        db "<html><head><title>Internal Server Error</title></head><body><center><h1>500 Internal Server Error</h1></center><hr></body></html>"
    http_500_resp_len equ $ - http_500_resp

    filename db "index.html", 0

    BUFFER_READ_SIZE equ 2048

    original_sock_fd dq 0
    accepted_sock_fd dq 0

    default_port db "8000", 0 ; default port value as a string

section .bss
    client_read_buffer resb BUFFER_READ_SIZE
    custom_port_string resb 6 ; 5 digit port + null
    port resw 1 ; port value as an integer

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

    test    rax, rax    ; test if we couldn't open the file
    js      error_404   ; throw 404 error

    mov     r14, rax    ; save fd

    ; seek to the end of the file
    mov     rdi, rax    ; file descriptor
    xor     rsi, rsi    ; offset
    mov     rdx, 2      ; SEEK_END
    mov     rax, 8      ; lseek
    syscall

    test    rax, rax    ; test if we couldn't seek the file
    js      error_500   ; throw 500 error

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

    test    rax, rax    ; test if we couldn't allocate memory
    js      error_500   ; throw 500 error

    ; rax has ptr to allocated memory
    mov     r12, rax    ; save addr of buffer

    ; rewind the file
    xor     rdx, rdx    ; whence (SEEK_SET)
    xor     rsi, rsi    ; offset
    mov     rdi, r14    ; file descriptor
    mov     rax, 8      ; lseek
    syscall

    test    rax, rax    ; test if we couldn't rewind the file
    js      error_500   ; throw 500 error

    ; read file into buffer
    mov     rdx, r13    ; number of bytes to read
    mov     rsi, r12    ; addr of buffer
    mov     rdi, r14    ; file descriptor
    mov     rax, 0      ; read
    syscall

    test    rax, rax    ; test if we couldn't read the file
    js      error_500   ; throw 500 error

    ; close file
    mov     rax, 3      ; close
    mov     rdi, r14    ; fd
    syscall
    ; we can probably ignore errors when closing the file
    ; whats the worst that could happen

    ; return buffer
    mov     rax, r12    ; buffer
    mov     rsi, r15    ; file size
    mov     rdi, r13    ; buffer size

    ret

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

; bind a socket to localhost at a specific port. exits on error
; inputs:
;       rax : socket fd
sock_bind:
    mov     rdi, rax            ; move socket fd into rdi

    ; set up sockaddr struct in the stack. see bind(2)
    xor     rax, rax            ; clear out rax
    mov     ax, [port]          ; load port variable
    xchg    al, ah              ; htons(port)

    push    dword   0           ; 4-byte address padding
    push    dword   0x0100007F  ; 127.0.0.1
    push    ax                  ; port
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
;       rax : socket fd
sock_listen:
    mov     rdi, rax    ; store socket fd in rdi
    mov     rax, 50     ; listen
    mov     rsi, 4096   ; socket max backlog connections (SOMAXCONN)
    syscall

    mov     rdi, 3      ; listen error code
    test    rax, rax    ; test rax
    js      exit        ; if rax == -1; exit

    ret

; accept a connection on a socket
; inputs:
;       rax : socket fd
; outputs:
;       rax : new socket fd for the accepted connection
sock_accept:
    mov     rdi, rax    ; put socket fd into rdi
    mov     rax, 43     ; accept
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

; write to a socket. exits on error
; inputs:
;       rax : file descriptor
;       rsi : buffer address
;       rdx : buffer length
sock_write:
    mov     rdi, rax                ; put the new file descriptor in rdi
    mov     rax, 1                  ; write
                                    ; rsi and rdx contain the buffer information
    syscall

    mov     rdi, 6                  ; error code for socket write
    test    rax, rax                ; test rax
    js      exit                    ; if rax == -1; exit

    ret                             ; write was successful, return

; convert a string value to an integer and store it in the port variable
; inputs:
;       rax : the string number
; outputs:
;       rax : the integer number
setup_port:
    xor     cx, cx                      ; the result value
    mov     rdi, custom_port_string     ; store port string address

    test    rax, rax                    ; check if input is 0
    jnz     convert_digit               ; dont set a default port since one was provided

    mov     rax, default_port           ; default port

    convert_digit:
        movzx   rdx, byte [rax]         ; load current character
        cmp     rdx, 0                  ; check for end of string
        je      finish_int_conversion   ; we're finished

        ; check for invalid characters
        cmp     rdx, '0'
        jl      skip_storing_number     ; check lower bound
        cmp     rdx, '9'
        jg      skip_storing_number     ; check upper bound

        mov     [rdi], dl               ; append current character to string representation variable
        sub     rdx, '0'                ; convert ascii to integer
        imul    cx, cx, 10              ; multiple result by 1 to increase the tens place
        add     cx, dx                  ; add current digit to sum

        inc     rax                     ; increment to next digit
        inc     rdi                     ; increment the index of the character we're appending to the string repr
        jmp     convert_digit           ; continue loop



    finish_int_conversion:
        mov     [port], cx              ; store final value in port variable

        skip_storing_number: ret

; print server ready message
print_server_ready_msg:
    mov     rax, 1                          ; write
    mov     rdi, 1                          ; stdout
    mov     rsi, server_ready_msg_pt1       ; buffer
    mov     rdx, server_ready_msg_pt1_len   ; buffer length
    syscall

    mov     rax, 1                          ; write
    mov     rdi, 1                          ; stdout
    mov     rsi, custom_port_string         ; port string
    mov     rdx, 6                          ; the port string length
    syscall

    mov     rax, 1                          ; write
    mov     rdi, 1                          ; stdout
    mov     rsi, server_ready_msg_pt2       ; buffer
    mov     rdx, server_ready_msg_pt2_len   ; buffer length
    syscall

    ret

_start:
    ; get arguments
    add     rsp, 16                 ; skip argc and argv[0]
    pop     rdi                     ; get first argument as file to read

    mov     rax, rdi                ; store our argument in rax
    call    setup_port              ; attempt to store string in port

    call    create_socket           ; create a socket and store it in rax
    mov     [original_sock_fd], rax ; save socket fd in original_sock_fd

    ; bind
                                    ; rax contains the socket fd
    call    sock_bind               ; bind the socket to 127.0.0.1:8000

    mov     rax, [original_sock_fd] ; put the socket fd into rax
    call    sock_listen             ; make the socket listen

    call print_server_ready_msg     ; print the server ready message

    connection_loop:
        mov     rax, [original_sock_fd] ; put the socket fd into rax
        call    sock_accept             ; accept incoming connections 
        mov     [accepted_sock_fd], rax ; move new fd into accepted_sock_fd

        ; read from socket into client_read_buffer
        mov     rax, 0                  ; read
        mov     rdi, [accepted_sock_fd] ; new socket fd
        mov     rsi, client_read_buffer ; buffer to read into
        mov     rdx, BUFFER_READ_SIZE   ; amount of bytes to read
        syscall

        mov     rdi, 5                  ; error code for sock_read
        test    rax, rax                ; test rax
        js      exit                    ; if rax == -1; exit

        mov     rsi, client_read_buffer ; the headers we recieved from the client
        call    print_first_line        ; print the first line for logging purposes

        mov     rdi, filename           ; the filename to respond with
        call    read_file               ; read the file. rax is contents buffer, rsi is size of buffer. rdi is the size of the pages allocated

        mov     r13, rax                ; preserve values
        mov     r14, rsi
        mov     r15, rdi

         ; write response headers to socket
        mov     rsi, http_200_resp      ; http 200 response
        mov     rdx, http_200_resp_len  ; http 200 response length
        mov     rax, [accepted_sock_fd] ; socket fd
        call    sock_write              ; write to the socket

        mov     rdx, r14                ; size of the file buffer
        mov     rsi, r13                ; the file buffer address
        mov     rbx, r15                ; save the size of the pages
        mov     rax, [accepted_sock_fd] ; socket fd
        call    sock_write              ; write to the socket

        ; unmap the memory from the file since we're done
        mov     rax, 11                 ; munmap
        mov     rdi, rsi                ; the address of the buffer
        mov     rsi, rbx                ; the length
        syscall

        mov     rax, [accepted_sock_fd] ; put socket fd into rax
        call    sock_close              ; close the new socket file descriptor

        jmp     connection_loop         ; accept more connections

; throw a 404 error and return to accepting connections
error_404:
    mov     rsi, http_404_resp      ; http 404 response
    mov     rdx, http_404_resp_len  ; http 404 response length
    mov     rax, [accepted_sock_fd] ; socket fd
    call    sock_write              ; write to the socket

    mov     rax, [accepted_sock_fd] ; load the current socket fd into rax
    call    sock_close              ; try to close the socket

    jmp     connection_loop         ; accept more connections

; throw a 500 error and return to accepting connections
error_500:
    mov     rsi, http_500_resp      ; http 500 response
    mov     rdx, http_500_resp_len  ; http 500 response length
    mov     rax, [accepted_sock_fd] ; socket fd
    call    sock_write              ; write to the socket

    mov     rax, [accepted_sock_fd] ; load the current socket fd into rax
    call    sock_close              ; try to close the socket

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
    mov     r15, rdi                    ; save the error code
    neg     rax                         ; negate rax to see real errno
    mov     r14, rax                    ; save the errno code
    mov     rax, [accepted_sock_fd]     ; load the current socket fd into rax
    call    sock_close                  ; try to close the socket
    mov     rax, [original_sock_fd]     ; load the original socket fd into rax
    call    sock_close                  ; try to close the socket

    mov     rbx, error_message_length   ; get the length of each error message
    imul    rbx, r15                    ; multiply by the index of the error
    sub     rbx, error_message_length   ; subtract the error message length since error codes start with 1

    mov     rax, 1                      ; write
    mov     rdi, 1                      ; stdout
    lea     rsi, [error_messages + rbx] ; error message buffer address
    mov     rdx, error_message_length   ; length of error messages
    syscall

    mov     rax, 60                 ; exit
    mov     rdi, r14                ; restore the errno code
    syscall