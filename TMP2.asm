section .data
    fmt_string db "%s %s %s", 0
    fmt_hex db "%02X ", 0
    instruction db "mov eax, ebx", 0
    operation db "mov", 0
    operand1 db "eax", 0
    operand2 db "ebx", 0

section .bss
    output resb 128

section .text
global main
extern printf

main:
    sub rsp, 40             ; Align stack to 16-byte boundary (shadow space + alignment)

    lea rcx, [rel instruction]  ; Load address of the instruction string into rcx
    call parse_instruction  ; Call the function to parse the instruction

    lea rcx, [rel output]       ; Load address of the output buffer into rcx
    call print_result       ; Call the function to print the result

    add rsp, 40             ; Restore stack pointer
    ret

parse_instruction:
    sub rsp, 40             ; Align stack to 16-byte boundary

    ; Example parsing logic:
    ; Assume parsing results in separating "mov", "eax", "ebx"
    mov r11, operation  ; Load address of operation into r11 (for further use)
    mov rdx, operand1      ; Load address of first operand into rdx
    mov r8, operand2        ; Load address of second operand into r8

    ; Assume we're copying parsed values to a buffer or performing some operations
    mov rax, rcx              ; Copy instruction pointer for some operation
    ; Additional parsing and processing logic would go here

    ; Prepare to print results using printf
    mov rcx, fmt_hex       ; Load format string into rcx
    mov rdx, r11              ; Load operation into rdx
    mov r8, operand1        ; Load first operand into r8
    mov r9, operand2        ; Load second operand into r9
    call printf               ; Call printf to output the parsed instruction

    add rsp, 40               ; Restore stack pointer
    ret

print_result:
    sub rsp, 40               ; Align stack to 16-byte boundary

    ; Print the output buffer
    mov rcx, fmt_string       ; Load format string into rcx
    lea rdx, [rel output]         ; Load output buffer into rdx
    call printf               ; Call printf to print the output

    add rsp, 40               ; Restore stack pointer
    ret
