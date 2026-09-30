.global _start

.text

# print a multi-digit integer
# inputs:
#   a0 : the integer to print
print_integer:
    # reserve 32 bytes on the stack and start a ptr (t0) at the end
    # t0 = ptr
    # t1 = divisor
    addi    sp, sp, -32
    addi    t0, zero, 32
    addi    t1, zero, 10

    # negative check
    # t2 = is_negative
    add     t2, zero, zero
    bge     a0, zero, _PI_digit_loop

    # a0 is negative, make it positive and set flag
    neg     a0, a0
    addi    t2, zero, 1

    _PI_digit_loop:
        rem     t3, a0, t1  # t3 = a0 % 10
        addi    t3, t3, '0' # convert to ASCII
        addi    t0, t0, -1  # move ptr backwards

        # store byte in stack
        add     t4, sp, t0
        sb      t3, 0(t4)

        # while quotient > 0, loop
        div     a0, a0, t1  # a0 = a0 // 10
        bne     a0, zero, _PI_digit_loop

    # if not negative, skip adding '-' in front
    beq     t2, zero, _PI_print_buffer

    # we are negative, add '-'
    addi    t0, t0, -1
    add     t4, sp, t0
    li      t5, '-'
    sb      t5, 0(t4)

    _PI_print_buffer:
    li      a7, 64      # write
    li      a0, 1       # stdout
    add     a1, sp, t0  # buffer addr
    li      t4, 32      # length = 32 - rcx
    sub     a2, t4, t0  # ...
    ecall

    # reset stack
    addi    sp, sp, 32
    ret

_start:
    li      a0, 54
    call    print_integer

    exit:
    li  a7, 93
    li  a0, 0
    ecall
