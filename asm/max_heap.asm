bits 64

section .data
    array times 12 dd 0
    ARRAY_SIZE equ 12
    ARRAY_ITEM_SIZE equ 1 ; 4-byte ints (dd)
    array_current_items dq 0

section .text
    global _start

; check if a specified value is in the bounds 0 <= val < ARRAY_SIZE
; jumps to return_none if not in bounds, which returns -1 in rax
%macro jump_not_in_bounds 1
    cmp     %1, 0           ; if %1 < 0
    jl      return_none     ; return -1

    cmp     %1, ARRAY_SIZE  ; if %1 >= ARRAY_SIZE
    jge     return_none     ; return -1
%endmacro

; swap two elements in an array
; inputs:
;       1 : array pointer
;       2 : first index to swap
;       3 : second index to swap
%macro swap 3
    push    rdi     ; save rdi
    push    rsi     ; save rsi

    mov     rdi, [%1 + %2 * ARRAY_ITEM_SIZE]
    mov     rsi, [%1 + %3 * ARRAY_ITEM_SIZE]
    mov     [%1 + %2 * ARRAY_ITEM_SIZE], rsi
    mov     [%1 + %3 * ARRAY_ITEM_SIZE], rdi

    pop     rsi     ; restore rsi
    pop     rdi     ; restore rdi
%endmacro

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

    iter_number:
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
        je      exit_print_integer  ; we juts did the last digit, exit printing

        xor     rdx, rdx    ; clear rdx (remainder)
        mov     rbx, 10     ; put 10 in rbx
        mov     rax, rcx    ; put our power of 10 in rax

        div     rbx         ; divide power of 10 by 10 to get the next digit
        mov     rcx, rax    ; move result into rcx

        pop     rax         ; restore our original number to print

        jmp iter_number     ; loop to iter_number until rcx is 1 (we've done the last digit)

    exit_print_integer:
        pop     rax     ; pop off our original number so that we return to the correct address
        ret

; return the index of the parent of an index
; inputs:
;       rdi : the index to find the parent of
; outputs:
;       rax : the parent of the index
parent_index:
    test    rdi, rdi        ; if rdi != 0
    jz      exit_failure    ; return -1

    jump_not_in_bounds  rdi ; return -1 if rdi not in bounds

    mov     rax, rdi        ; rax = rdi
    ; (int)(rax - 1) / 2
    dec     rax             ; rax--
    mov     rdi, 2          ; rdi = 2
    xor     rdx, rdx        ; clear rdx since theres no high order bits
    idiv    rdi             ; rax /= rdi (rax / 2)

    ; rax now contains the parent index
    ret

; return the index of the left child of an index
; inputs:
;       rdi : the index to find the child of
; outputs:
;       rax : the left child of the index
left_child_index:
    cmp     rdi, ARRAY_SIZE     ; if (rdi < ARRAY_SIZE)
    jl      return_none         ; return -1

    jump_not_in_bounds  rdi     ; return -1 if rdi not in bounds

    ; rdi = 2 * rdi + 1
    imul    rdi, 2              ; rdi *= 2
    inc     rdi                 ; rdi++

    mov     rax, rdi            ; rax = rdi
    ret

; return the index of the right child of an index
; inputs:
;       rdi : the index to find the child of
; outputs:
;       rax : the right child of the index
right_child_index:
    cmp     rdi, ARRAY_SIZE     ; if (rdi < ARRAY_SIZE)
    jl      return_none         ; return -1

    jump_not_in_bounds  rdi     ; return -1 if rdi not in bounds

    ; rdi = 2 * rdi + 2
    imul    rdi, 2              ; rdi *= 2
    add     rdi, 2              ; rdi += 2

    mov     rax, rdi            ; rax = rdi
    ret

; return the index of the left sibling of an index
; inputs:
;       rdi : the index to find the sibling of
; outputs:
;       rax : the left sibling of the index
left_sibling_index:
    ; check if rdi is even
    mov     rax, rdi        ; rax = rdi
    mov     rsi, 2          ; rsi = 2
    xor     rdx, rdx        ; clear rdx since theres no high order bits
    idiv    rsi             ; rax /= 2

    test    rdx, rdx        ; rdx % 2 == 0
    jnz     return_none     ; not even, return -1

    ; rdi != 0
    test    rdi, rdi
    jz      return_none     ; rdi == 0, return -1

    jump_not_in_bounds  rdi ; return -1 if rdi not in bounds

    ; rax = rdi - 1
    mov     rax, rdi        ; rax = rdi
    dec     rax             ; rax--
    ret

; return the index of the right sibling of an index
; inputs:
;       rdi : the index to find the sibling of
; outputs:
;       rax : the right sibling of the index
right_sibling_index:
    ; check if rdi is not even
    mov     rax, rdi        ; rax = rdi
    mov     rsi, 2          ; rsi = 2
    xor     rdx, rdx        ; clear rdx since theres no high order bits
    idiv    rsi             ; rax /= 2

    test    rdx, rdx        ; rdx % 2 != 0
    jz      return_none     ; even, return -1

    jump_not_in_bounds  rdi ; return -1 if rdi not in bounds

    ; rdi + 1 < ARRAY_SIZE
    inc     rdi             ; rdi++
    cmp     rdi, ARRAY_SIZE ; if (rdi >= ARRAY_SIZE)
    jge     return_none     ; return -1

    mov     rax, rdi        ; rax = rdi
    ret

; checks whether an index is a leaf
; inputs:
;       rdi : the index to check
;       rsi : number of items in the array
; outputs:
;       rax : 1 if rdi is a leaf, 0 if not
is_leaf:
    ; not a leaf if rdi >= rsi
    cmp     rdi, rsi    ; if rdi >= rsi
    jge     not_leaf    ; return 0

    ; not a leaf if rsi / 2 > rdi
    mov     rax, rsi    ; rax = rsi
    mov     rsi, 2      ; rsi = 2
    xor     rdx, rdx        ; clear rdx since theres no high order bits
    idiv    rsi         ; rax /= rsi (rax /= 2)
    cmp     rax, rdi    ; if rax > rdi
    jg      not_leaf    ; return 0

    ; all leaf checks have passed, return 1
    mov     rax, 1      ; rax = 1
    ret

    not_leaf:
    ; not a leaf, return 0
    mov     rax, 0
    ret

; Moves an element down to its correct place
; inputs:
;       rdi : pointer to the array
;       rsi : the index of the current item
;       rdx : the number of items in the array
sift_down:
    push    r12                     ; save r12
    push    r13                     ; save r13
    push    r14                     ; save r14

    mov     r12, rdi                ; set r12 to array pointer
    mov     r13, rsi                ; set r13 to index of current item
    mov     r14, rdx                ; set r14 to num of items in array

    jmp sift_down_test              ; start with loop test

    sift_down_loop:
        mov     rdi, r13            ; set rdi to current item
        call    left_child_index    ; get left child index of current item and store in rax

        ; if (child + 1 < items_in_arr) && arr[child + 1] > arr[child]
        mov     rdi, rax            ; set rdi to child index
        inc     rdi                 ; increment rdi

        cmp     rdi, r14            ; skip if child + 1 >= items_in_arr
        jge     sift_down_no_increment

        mov     rdi, [r12 + rdi * ARRAY_ITEM_SIZE]  ; set rdi to arr[child + 1]
        mov     rsi, [r12 + rax * ARRAY_ITEM_SIZE]  ; set rsi to arr[child]
        cmp     rdi, rsi                            ; skip if arr[child + 1] <= arr[child]
        jle     sift_down_no_increment

        inc     rax                                 ; checks pass, we increment child

    sift_down_no_increment:                         ; label for skipping child++
    ; return early if arr[child] <= arr[current_item]
    mov     rdi, [r12 + rax * ARRAY_ITEM_SIZE]  ; set rdi to arr[child]
    mov     rsi, [r12 + r13 * ARRAY_ITEM_SIZE]  ; set rsi to arr[current_item]
    cmp     rdi, rsi                            ; check if arr[child] <= arr[current_item]
    jle     sift_down_end                       ; return early

    swap    r12, r13, rax                       ; swap current_item and child index
    mov     r13, rax                            ; current_item = child

    sift_down_test:
    ; while (!is_leaf())
    mov     rdi, r13                ; set rdi to current item
    mov     rsi, r14                ; set rsi to num of items in array
    call    is_leaf                 ; check if current item is leaf
    test    rax, rax                ; check if rax is not 0 (not a leaf)
    jnz     sift_down_loop          ; jump to loop if not a leaf

    sift_down_end:
    pop     r14                     ; restore r14
    pop     r13                     ; restore r13
    pop     r12                     ; restore r12
    ret

; Moves an element up to its correct place
; inputs:
;       rdi : pointer to the array
;       rsi : the index of the current item
sift_up:
    push    r12             ; save r12
    push    r13             ; save r13
    mov     r12, rdi        ; r12 = rdi (array)
    mov     r13, rsi        ; r13 = rsi (current index)
    jmp     sift_up_test    ; start while loop

    sift_up_loop:
        ; main loop body
        ; current index should be in rdi
        mov     rdi, r13        ; rdi = r13, r13 holds the current index
        call    parent_index    ; sets rax to the parent index

        mov     rax, [r12 + rax * ARRAY_ITEM_SIZE]      ; rax = array[parent_index]
        mov     r10, [r12 + r13 * ARRAY_ITEM_SIZE]      ; r10 = array[current_index]
        cmp     rax, r10                                ; if parent > current
        jg      sift_up_end                             ; return early


        swap    r12, r13, rax                           ; swap current and parent index (uses rdi and rsi)
        mov     r13, rax                                ; update r13 (current index) with parent index

    sift_up_test:
    ; while (rcx > 0)
        cmp     rcx, 0          ; is rcx > 0
        jg      sift_up_loop    ; if it is, redo the loop

    ; loop end, return
    sift_up_end:
    pop     r13                 ; restore r13
    pop     r12                 ; restore r12
    ret

; The value at pos has been changed, restore the heap property
; inputs:
;       rdi : pointer to the array
;       rsi : the index of the current item
;       rdx : the number of items in the array
update:
    call    sift_up     ; sift up current item
    call    sift_down   ; sift down current item
    ret

; Modify the value at the given position
; inputs:
;       rdi : pointer to the array
;       rsi : the index of the item to modify
;       rdx : the number of items in the array
;       rcx : the new value for the item
modify:
    mov     [array + rsi * ARRAY_ITEM_SIZE], rcx    ; array[rsi] = rcx
    call    update                                  ; since value has changed, update the current index
    ret

; insert a value into the max heap
; inputs:
;       rdi : pointer to the array
;       rsi : pointer to the number of items in the array
;       rdx : the value to insert
insert_into_heap:
    mov     rcx, [rsi]                          ; load the number of items in the array into rcx
    mov     [rdi + rcx * ARRAY_ITEM_SIZE], rdx  ; set the index in the array to rdx

    push    rsi                                 ; save rsi
    push    rcx                                 ; save *rsi
    mov     rsi, rcx                            ; set second argument of sift_up to the item we just inserted
    call    sift_up                             ; rdi is already array pointer, so sift up new item

    pop     rcx                                 ; restore *rsi
    pop     rsi                                 ; restore rsi
    inc     rcx                                 ; increment num of items in array
    mov     [rsi], rcx                          ; update pointer with new value
    ret

; Build an array into a heap
; inputs:
;       rdi : pointer to the array
;       rsi : number of items in the array
build_heap:
    push    r12             ; save r12
    push    r13             ; save r13
    push    r14             ; save r14

    mov     r12, rdi        ; save array pointer in r12
    mov     r13, rsi        ; save num of items in r13

    mov     rdi, rsi        ; set rdi to num of items in array
    dec     rdi             ; rdi--
    call    parent_index    ; store parent index in rax

    mov     r14, rax        ; save rax in r14

    ; for (r14 = parent_index(items_in_arr - 1); r14 >= 0; r14--) {
    build_heap_loop:
        mov     rdi, r12        ; set array pointer
        mov     rsi, r14        ; set current item index
        mov     rdx, r13        ; set num items

        call    sift_down       ; sift down the current item

        dec     r14             ; r14--

        ; check if r14 is still >= 0
        cmp     r14, 0
        jge     build_heap_loop

    ; loop is over, restore and return
    pop     r14             ; restore r14
    pop     r13             ; restore r13
    pop     r12             ; restore r12
    ret

; removes and returns the item at the max index
; inputs:
;       rdi : pointer to the array
;       rsi : pointer to the number of items in the array
remove_max:
    mov     rdx, [rsi]  ; load number of items in array into rdx
    dec     rdx         ; decrement rdx
    mov     [rsi], rdx  ; save new value to pointer

    swap    rdi, 0, rdx ; swap the first value with the last value

    mov     rsi, 0      ; current_item = 0

    push    rdi         ; save array pointer
    push    rdx         ; save current item index

    call    sift_down   ; rdi already contains the array pointer and rdx already contains num_items
    pop     rdx         ; restore current item index
    pop     rdi         ; restore array pointer

    mov     rax, [rdi + rdx * ARRAY_ITEM_SIZE]  ; get item we just removed

    ret

; removes an item at a specified index
; inputs:
;       rdi : pointer to the array
;       rsi : index of the item to remove
;       rdx : pointer to the number of items in the array
remove_index:
    mov     rcx, [rdx]      ; load number of array items into rcx
    dec     rcx             ; decrement rcx
    mov     [rdx], rcx      ; write new value to pointer

    swap    rdi, rsi, rcx   ; swap given index with last position (rcx)

    push    rdi             ; save rdi (array pointer)
    push    rcx             ; save rcx (current_item index)

    call    update          ; update with new values

    pop     rcx             ; restore rcx
    pop     rdi             ; restore rdi

    mov     rax, [rdi + rcx * ARRAY_ITEM_SIZE]  ; get old value to return

    ret

; return early from a call with -1
; outputs:
;       rax : -1
return_none:
    mov     rax, -1     ; rax = -1 (child/parent/sibling doesn't exist)
    ret

print_array:
    push    rbx         ; save rbx
    xor     rbx, rbx    ; clear rbx

    print_array_loop:
        cmp     rbx, [array_current_items]
        je      print_array_end

        mov     rax, [array + rbx * ARRAY_ITEM_SIZE]
        push    rbx
        call    print_integer
        pop     rbx

        cmp     rbx, ARRAY_SIZE - 1
        je      print_array_end

        ; print space
        inc     rbx
        jmp     print_array_loop

    print_array_end:
        pop     rbx     ; restore rbx
        ret


_start:
    mov     rdi, array
    mov     rsi, array_current_items
    mov     rdx, 1
    call    insert_into_heap

    mov     rdi, array
    mov     rsi, array_current_items
    mov     rdx, 2
    call    insert_into_heap

    call    print_array

    mov     rax, 60     ; exit
    mov     rdi, 0      ; exit code 0
    syscall

exit_failure:
    mov     rax, 60     ; exit
    mov     rdi, 1      ; exit code 1
    syscall
