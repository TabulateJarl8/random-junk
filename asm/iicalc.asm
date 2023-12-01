section .text
  global _start

section .data
  startup_msg db "Welcome to iiCalc super edition",0xa
  startup_msg_len equ $ - startup_msg

  input_msg db "> "
  input_msg_len equ $ - input_msg

  answer_msg db "Answer: "
  answer_msg_len equ $ - answer_msg

  newline db 0xa

  buffer_len equ 100

section .bss
  user_input resb 100 ; user input buffer

section .text

_start:
  ; write startup message
  mov edx,startup_msg_len
  mov ecx,startup_msg
  mov ebx,1
  mov eax,4
  int 0x80

take_input:
  ; write input message
  mov edx,input_msg_len
  mov ecx,input_msg
  mov ebx,1
  mov eax,4
  int 0x80

  ; read user input
  mov eax,3
  mov ebx,0
  lea ecx, user_input
  mov edx,buffer_len
  int 0x80

  ; check if user inputs 'q' to quit
  mov al, byte [user_input]  ; Load the first character of the input
  cmp al, 'q'
  je exit_program

  ; display user input as answer
  mov edx,answer_msg_len
  mov ecx,answer_msg
  mov ebx,1
  mov eax,4
  int 0x80

  mov edx,buffer_len
  mov ecx,user_input
  mov ebx,1
  mov eax,4
  int 0x80

  ; clear user input buffer
  xor eax, eax           ; Set AL register to 0
  mov edi, user_input    ; Load user_input address into EDI
  mov ecx, buffer_len    ; Load buffer length into ECX
  rep stosb              ; Repeat store 0 in memory (clear buffer)

  jmp take_input

exit_program:
  ; exit with status code 0
  mov ebx,0
  mov eax,1
  int 0x80
