section .data
    input_msg db "Enter assembly instruction: ", 0
    start_msg db "Start", 10, 0
    capture_msg db "Captured: %s", 10, 0
    fmt_string db `%[^\n]`, 0

section .bss
    instruction resb 50

section .text
    extern printf, scanf, ExitProcess
    global main

main:
    sub rsp, 40

    ; Start Message
    lea rcx, [rel start_msg]
    call printf

    ; Input Prompt
    lea rcx, [rel input_msg]
    call printf

    ; Capture Input
    lea rcx, [rel fmt_string]
    lea rdx, [rel instruction]
    call scanf

    ; Debugging: Print Captured Instruction
    lea rcx, [rel capture_msg]
    lea rdx, [rel instruction]
    call printf

    add rsp, 40
    xor ecx, ecx
    call ExitProcess
