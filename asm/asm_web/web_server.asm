bits 64

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
    http_200_resp_len equ $ - http_200_resp

    ; CONTENT TYPE DEFINITIONS
    content_type_html       db "Content-Type: text/html", 0xa, 0xa
    content_type_html_len   equ $ - content_type_html
    content_type_css        db "Content-Type: text/css", 0xa, 0xa
    content_type_css_len    equ $ - content_type_css
    content_type_js         db "Content-Type: text/javascript", 0xa, 0xa
    content_type_js_len     equ $ - content_type_js
    content_type_ico        db "Content-Type: image/x-icon", 0xa, 0xa
    content_type_ico_len    equ $ - content_type_ico
    content_type_txt        db "Content-Type: text/plain", 0xa, 0xa
    content_type_txt_len    equ $ - content_type_txt
    content_type_xml        db "Content-Type: application/xml", 0xa, 0xa
    content_type_xml_len    equ $ - content_type_xml
    content_type_pdf        db "Content-Type: application/pdf", 0xa, 0xa
    content_type_pdf_len    equ $ - content_type_pdf
    content_type_png        db "Content-Type: image/png", 0xa, 0xa
    content_type_png_len    equ $ - content_type_png
    content_type_jpg        db "Content-Type: image/jpg", 0xa, 0xa
    content_type_jpg_len    equ $ - content_type_jpg
    content_type_woff       db "Content-Type: font/woff", 0xa, 0xa
    content_type_woff_len   equ $ - content_type_woff
    content_type_woff2      db "Content-Type: font/woff2", 0xa, 0xa
    content_type_woff2_len  equ $ - content_type_woff2
    content_type_ttf        db "Content-Type: font/ttf", 0xa, 0xa
    content_type_ttf_len    equ $ - content_type_ttf
    content_type_svg        db "Content-Type: image/svg+xml", 0xa, 0xa
    content_type_svg_len    equ $ - content_type_svg

    file_extension_html     db "html", 0
    file_extension_woff     db "woff", 0
    file_extension_woff2    db "woff2", 0
    file_extension_css      db "css", 0
    file_extension_ico      db "ico", 0
    file_extension_txt      db "txt", 0
    file_extension_xml      db "xml", 0
    file_extension_pdf      db "pdf", 0
    file_extension_png      db "png", 0
    file_extension_jpg      db "jpg", 0
    file_extension_ttf      db "ttf", 0
    file_extension_svg      db "svg", 0
    file_extension_js       db "js", 0

    ; ERROR RESPONSE DEFINITIONS
    http_400_resp:
        db "HTTP/1.0 400 Bad Request", 0xa
        db "Server: TabulateASM", 0xa
        db "Content-Type: text/html", 0xa, 0xa
        db "<html><head><title>Bad Request</title></head><body><center><h1>400 Bad Request</h1></center><hr></body></html>"
    http_400_resp_len equ $ - http_400_resp

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

    default_filename db "index.html", 0
    default_filename_len equ $ - default_filename

    BUFFER_READ_SIZE equ 2048

    original_sock_fd dq 0
    accepted_sock_fd dq 0

    default_port db "8000", 0 ; default port value as a string

    web_page_directory db "pages"
    web_page_directory_len equ $ - web_page_directory

    max_filesize equ 255

    path_filename_max_len equ max_filesize + web_page_directory_len

section .bss
    client_read_buffer resb BUFFER_READ_SIZE
    custom_port_string resb 6 ; 5 digit port + null
    port resw 1 ; port value as an integer
    path_filename resb max_filesize + web_page_directory_len ; pages + /filename

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

    mov     rax, 1              ; write
    mov     rdi, 1              ; stdout
                                ; rsi already contains our buffer address
    mov     rdx, rcx            ; our counter contains the amount of data to print
    syscall

    ret

; parse the filename out of a GET request header. throws a 400 if not GET
; i think this can crash the server if the filename is too long
; this does indeed crash the server
; inputs:
;       rdi : the address of the request header buffer
; outputs:
;       [path_filename] : a buffer containing the relative path to the requested file
parse_filename_from_get:
    cmp     byte [rdi],     'G'         ; check for a GET request
    jne     error_400                   ; not a GET request, throw a 400 error
    cmp     byte [rdi + 1], 'E'         ; check for a GET request
    jne     error_400                   ; not a GET request, throw a 400 error
    cmp     byte [rdi + 2], 'T'         ; check for a GET request
    jne     error_400                   ; not a GET request, throw a 400 error

    mov     rbx, rdi                    ; preserve request header buffer address

    ; clear the previous filename buffer
    mov     rdi, path_filename          ; destination address
    mov     rcx, path_filename_max_len  ; number of bytes to overwrite
    xor     rax, rax                    ; set rax to NULL
    rep     stosb                       ; set all bytes to null

    ; set up path filename variable with the directory containing html documents
    mov     rdi, path_filename          ; destination address
    mov     rsi, web_page_directory     ; source address
    mov     rcx, web_page_directory_len ; size of string to copy
    rep     movsb                       ; copy the string

    mov     rdi, rbx                    ; restore request header buffer address

    ; this is a GET request, get the file path
    add     rdi, 4      ; skip past 'GET ' and start at the filename
    xor     rcx, rcx    ; start a counter

    check_for_space:
        mov     al, [rdi + rcx]         ; load current character into rax
        inc     rcx                     ; increment the counter
        cmp     al, 0x20                ; check if the current character is a space (end of filename)
        jne     check_for_space         ; we haven't found it yet, continue

    ; we found the end, copy it into the path_filename buffer
    dec     rcx                         ; dont count the space at the end

    ; check if the ending character is a '/' (replace it with index.html)
    xor     rbx, rbx                    ; add index.html flag
    cmp     byte [rdi + rcx - 1], '/'   ; check if last char is '/'
    jne     skip_index_html_flag        ; if its not, then we dont need to change the rbx flag

    mov     rbx, rcx                    ; set rbx to non-zero (amount of bytes in page name) to trigger addition of index.html

    skip_index_html_flag:
    ; write the path from the URL into the path_filename variable
    mov     rsi, rdi                                    ; put our source string into rsi
    mov     rdi, path_filename + web_page_directory_len ; destination address (skips 'pages')
                                                        ; rcx already contains our count
    rep     movsb                                       ; copy the string into the destination

    cmp     rbx, 0                                      ; check if we need to append index.html
    je      skip_append_index_html                      ; we dont need to, skip to the end

    ; append index.html
    mov     rsi, default_filename                       ; source address
    mov     rdi, path_filename + web_page_directory_len ; dest address ('pages' + len(page))
    add     rdi, rbx                                    ; + len(page)

    mov     rcx, default_filename_len                   ; amount of data to copy
    rep     movsb                                       ; copy string

    skip_append_index_html:
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

; implementation of strlen
; inputs:
;       rdi : address of buffer
; outputs:
;       rax : length of the string, not including the null byte
strlen:
    xor     rax, rax                    ; clear count register
    strlen_inc:
        movzx   rcx, byte [rdi + rax]   ; get the byte at *(buffer + rax)
        test    rcx, rcx                ; test if the selected byte is NULL
        je      strlen_done             ; if NULL, jump to the end of the loop and return
        inc     rax                     ; not NULL, so we increment and check the next byte
        jmp     strlen_inc              ; jump back to the start of the loop
    strlen_done:
        ret

; write the content type header for the currently loaded file
write_content_type_header:
    mov     rdi, path_filename        ; move the currently loaded file into rdi
    call    strlen                      ; get the length of the filename in rax
    mov     rdi, rax                    ; save lngth into rdi

    ; find the file extension. seek back until we find a '.' or until we get to the end of the string
    write_content_type_header_loop:
        ; if we've gotten to the beginning of the string (rax == 0), then we jump to the not found portion of the loop
        test    rax, rax    ; check if rax == 0
        je      write_content_type_header_loop_not_found

        ; if we're not at the beginning of the string, we'll check if the current byte is a '.'
        dec     rax                                     ; dec rax to go back 1 byte since we're not at the beginning of the string
        cmp     byte [path_filename + rax], '.'         ; check if current character is a '.'
        je      write_content_type_header_loop_found    ; we found the '.', check the file extension

        jmp     write_content_type_header_loop          ; file extension hasnt been found yet, try again

    write_content_type_header_loop_found:
        ; file extension was found, try to match it to a known extension
        inc     rax         ; increment rax so that we're not pointing at the '.'
                            ; rdi already contains the length
        sub     rdi, rax    ; get the length of the file extension by doing (filename_len - start_of_extension_index) and store it in rdi

        cmp     rdi, 2      ; check if the extension length is 2
        je      write_content_type_header_2

        cmp     rdi, 3      ; check if the extension length is 3
        je      write_content_type_header_3

        cmp     rdi, 4      ; check if the extension length is 4
        je      write_content_type_header_4

        cmp     rdi, 5      ; check if the extension length is 5
        je      write_content_type_header_5

        ; extension doesn't match any known lengths; default to html
        jmp     write_content_type_header_loop_not_found

    write_content_type_header_2:
        ; FILE EXTENSIONS THAT ARE 2 LONG

        ; JS
        mov     rcx, 2                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_js         ; str2 (js) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_js   ; is js

        ; if we get here, nothing matched, so we default to html
        jmp     write_content_type_header_loop_not_found

    write_content_type_header_3:
        ; FILE EXTENSIONS THAT ARE 3 LONG

        ; CSS
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_css         ; str2 (CSS) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_css   ; is CSS

        ; ICO
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_ico         ; str2 (ico) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_ico   ; is ico

        ; TXT
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_txt         ; str2 (txt) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_txt   ; is txt

        ; XML
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_xml         ; str2 (xml) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_xml   ; is xml

        ; PDF
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_pdf         ; str2 (pdf) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_pdf   ; is pdf

        ; PNG
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_png         ; str2 (png) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_png   ; is png

        ; JPG
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_jpg         ; str2 (jpg) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_jpg   ; is jpg

        ; TTF
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_ttf         ; str2 (ttf) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_ttf   ; is ttf

        ; SVG
        mov     rcx, 3                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_svg         ; str2 (svg) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_svg   ; is svg

        ; if we get here, nothing matched, so we default to html
        jmp     write_content_type_header_loop_not_found

    write_content_type_header_4:
        ; FILE EXTENSIONS THAT ARE 4 LONG

        ; HTML
        mov     rcx, 4                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_html        ; str2 (HTML) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_html  ; is HTML

        ; HTML
        mov     rcx, 4                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_woff        ; str2 (woff) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_woff  ; is woff

        ; if we get here, nothing matched, so we default to html
        jmp     write_content_type_header_loop_not_found

    write_content_type_header_5:
        ; FILE EXTENSIONS THAT ARE 5 LONG

        ; woff2
        mov     rcx, 5                          ; length to compare
        lea     rsi, [path_filename + rax]                        ; str1 in rsi
        mov     rdi, file_extension_woff2        ; str2 (woff2) in rdi
        repe    cmpsb                           ; compare null terminated strings
        je      write_content_type_header_woff2  ; is woff2

    write_content_type_header_js:
        mov     rsi, content_type_js
        mov     rdx, content_type_js_len
        jmp     write_content_type_to_sock

    write_content_type_header_ttf:
        mov     rsi, content_type_ttf
        mov     rdx, content_type_ttf_len
        jmp     write_content_type_to_sock

    write_content_type_header_svg:
        mov     rsi, content_type_svg
        mov     rdx, content_type_svg_len
        jmp     write_content_type_to_sock

    write_content_type_header_html:
        mov     rsi, content_type_html
        mov     rdx, content_type_html_len
        jmp     write_content_type_to_sock

    write_content_type_header_woff:
        mov     rsi, content_type_woff
        mov     rdx, content_type_woff_len
        jmp     write_content_type_to_sock

    write_content_type_header_woff2:
        mov     rsi, content_type_woff2
        mov     rdx, content_type_woff2_len
        jmp     write_content_type_to_sock

    write_content_type_header_css:
        mov     rsi, content_type_css
        mov     rdx, content_type_css_len
        jmp     write_content_type_to_sock

    write_content_type_header_jpg:
        mov     rsi, content_type_jpg
        mov     rdx, content_type_jpg_len
        jmp     write_content_type_to_sock

    write_content_type_header_ico:
        mov     rsi, content_type_ico
        mov     rdx, content_type_ico_len
        jmp     write_content_type_to_sock

    write_content_type_header_txt:
        mov     rsi, content_type_txt
        mov     rdx, content_type_txt_len
        jmp     write_content_type_to_sock

    write_content_type_header_xml:
        mov     rsi, content_type_xml
        mov     rdx, content_type_xml_len
        jmp     write_content_type_to_sock

    write_content_type_header_pdf:
        mov     rsi, content_type_pdf
        mov     rdx, content_type_pdf_len
        jmp     write_content_type_to_sock

    write_content_type_header_png:
        mov     rsi, content_type_png
        mov     rdx, content_type_png_len
        jmp     write_content_type_to_sock

    write_content_type_header_loop_not_found:
        ; file extension not found, just use text/html
        mov     rsi, content_type_html      ; text/html content type
        mov     rdx, content_type_html_len  ; text/html content type length

    write_content_type_to_sock:
        mov     rax, [accepted_sock_fd]     ; socket fd
        call    sock_write                  ; write to the socket
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
    add     rsp, 16                     ; skip argc and argv[0]
    pop     rdi                         ; get first argument as file to read

    mov     rax, rdi                    ; store our argument in rax
    call    setup_port                  ; attempt to store string in port

    call    create_socket               ; create a socket and store it in rax
    mov     [original_sock_fd], rax     ; save socket fd in original_sock_fd

    ; bind
                                        ; rax contains the socket fd
    call    sock_bind                   ; bind the socket to 127.0.0.1:8000

    mov     rax, [original_sock_fd]     ; put the socket fd into rax
    call    sock_listen                 ; make the socket listen

    call print_server_ready_msg         ; print the server ready message

    connection_loop:
        mov     rax, [original_sock_fd]     ; put the socket fd into rax
        call    sock_accept                 ; accept incoming connections
        mov     [accepted_sock_fd], rax     ; move new fd into accepted_sock_fd

        ; read from socket into client_read_buffer
        mov     rax, 0                      ; read
        mov     rdi, [accepted_sock_fd]     ; new socket fd
        mov     rsi, client_read_buffer     ; buffer to read into
        mov     rdx, BUFFER_READ_SIZE       ; amount of bytes to read
        syscall

        mov     rdi, 5                      ; error code for sock_read
        test    rax, rax                    ; test rax
        js      exit                        ; if rax == -1; exit

        mov     rsi, client_read_buffer     ; the headers we recieved from the client
        call    print_first_line            ; print the first line for logging purposes

        mov     rdi, client_read_buffer     ; store the buffer that we read from the client into rdi
        call    parse_filename_from_get     ; parse out the filename that the client sent

        mov     rdi, path_filename          ; move the filename to rdi
        call    read_file                   ; read the file. rax is contents buffer, rsi is size of buffer. rdi is the size of the pages allocated

        mov     r13, rax                    ; preserve values
        mov     r14, rsi
        mov     r15, rdi

         ; write response headers to socket
        mov     rsi, http_200_resp          ; http 200 response
        mov     rdx, http_200_resp_len      ; http 200 response length
        mov     rax, [accepted_sock_fd]     ; socket fd
        call    sock_write                  ; write to the socket

        ; write the Content-Type header
        call    write_content_type_header

        mov     rdx, r14                    ; size of the file buffer
        mov     rsi, r13                    ; the file buffer address
        mov     rbx, r15                    ; save the size of the pages
        mov     rax, [accepted_sock_fd]     ; socket fd
        call    sock_write                  ; write to the socket

        ; unmap the memory from the file since we're done
        mov     rax, 11                     ; munmap
        mov     rdi, rsi                    ; the address of the buffer
        mov     rsi, rbx                    ; the length
        syscall

        mov     rax, [accepted_sock_fd]     ; put socket fd into rax
        call    sock_close                  ; close the new socket file descriptor

        jmp     connection_loop             ; accept more connections

; throw a 404 error and return to accepting connections
error_404:
    mov     rsi, http_404_resp      ; http 404 response
    mov     rdx, http_404_resp_len  ; http 404 response length
    mov     rax, [accepted_sock_fd] ; socket fd
    call    sock_write              ; write to the socket

    mov     rax, [accepted_sock_fd] ; load the current socket fd into rax
    call    sock_close              ; try to close the socket

    jmp     connection_loop         ; accept more connections

; throw a 400 error and return to accepting connections
error_400:
    mov     rsi, http_400_resp      ; http 400 response
    mov     rdx, http_400_resp_len  ; http 400 response length
    mov     rax, [accepted_sock_fd] ; socket fd
    call    sock_write              ; write to the socket

    mov     rax, [accepted_sock_fd] ; load the current socket fd into rax
    call    sock_close              ; try to close the socket

    jmp     connection_loop         ; accept more connections

; throw a 500 error and return to accepting connections
error_500:
    neg     rax                     ; negative rax for debugging (errno)
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
