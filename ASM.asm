; Assembler-Disassembler Tool
; Supports basic instructions: MOV, ADD, SUB, JMP

section .data
    input_msg db "Enter assembly instruction: ", 0
    output_msg db "Machine code: ", 0
    invalid_msg db "Invalid instruction or operands!", 10, 0

    ; Opcode definitions
    opcode_mov db 0xB8      ; MOV opcode base
    opcode_add db 0x01      ; ADD opcode
    opcode_sub db 0x29      ; SUB opcode
    opcode_jmp db 0xE9      ; JMP opcode

    ; Register codes
    reg_eax db 0x00
    reg_ecx db 0x01
    reg_edx db 0x02
    reg_ebx db 0x03

    ; Format strings
    fmt_string db "%s", 0
    fmt_hex db "%02X ", 0
    fmt_dec db "%d", 0

section .bss
    instruction resb 50     ; Buffer for user input
    opcode resb 5           ; Buffer for generated opcode
    op_len resd 1           ; Length of opcode
    operand1 resb 10        ; Buffer for operand1
    operand2 resb 10        ; Buffer for operand2
    atoi_result resd 1

section .text
    extern printf, scanf, ExitProcess, sscanf
    global main

main:
    ; Stack alignment
    sub rsp, 40

    ; Prompt user for input
    lea rcx, [rel input_msg]
    call printf

    ; Read user input
    lea rcx, [rel fmt_string]
    lea rdx, [rel instruction]
    call scanf

    ; Parse instruction
    lea rcx, [rel instruction]
    lea rdx, [rel operand1]
    lea r8, [rel operand2]
    call parse_instruction

    ; Check if parsing was successful
    cmp dword [rel op_len], 0
    je invalid_instruction

    ; Display machine code
    lea rcx, [rel output_msg]
    call printf

    mov rcx, 0
    mov ecx, [rel op_len]
    mov rsi, opcode
display_loop:
    cmp rcx, rdx
    je display_end
    mov al, [rsi]
    lea rcx, [rel fmt_hex]
    movzx rdx, al
    call printf
    inc rsi
    dec ecx
    jmp display_loop

display_end:
    ; New line
    lea rcx, [rel fmt_string]
    lea rdx, [10]    ; ASCII newline
    call printf

    ; Clean up and exit
    add rsp, 40
    xor ecx, ecx
    call ExitProcess

invalid_instruction:
    lea rcx, [rel invalid_msg]
    call printf
    add rsp, 40
    xor ecx, ecx
    call ExitProcess

; -----------------------------------------
; parse_instruction:
; Parses the input instruction and generates machine code.
; Inputs:
;   rcx - pointer to instruction string
;   rdx - pointer to operand1 buffer
;   r8  - pointer to operand2 buffer
; Outputs:
;   [opcode] - generated machine code
;   [op_len] - length of machine code
; -----------------------------------------
parse_instruction:
    push rbp
    mov rbp, rsp

    ; Initialize op_len to 0
    mov dword [rel op_len], 0

    ; Extract operation and operands
    lea r9, [rel operation]
    lea r10, [rel operand1]
    lea r11, [rel operand2]
    lea rax, [rel fmt_string]
    mov rcx, rax
    mov rdx, rcx
    mov r8, rcx
    lea rax, [rel instruction]
    call sscanf_wrapper

    ; Compare operation
    lea rax, [rel operation]
    call str_compare_mov
    cmp al, 1
    je handle_mov

    call str_compare_add
    cmp al, 1
    je handle_add

    call str_compare_sub
    cmp al, 1
    je handle_sub

    call str_compare_jmp
    cmp al, 1
    je handle_jmp

    ; Invalid instruction
    jmp parse_end

handle_mov:
    ; MOV reg, imm
    ; opcode: 0xB8 + reg_code | imm (4 bytes)
    mov rdi, [rel operand1]
    call get_register_code
    cmp al, 0xFF
    je parse_end
    mov bl, [rel opcode_mov]
    add bl, al             ; opcode = 0xB8 + reg_code
    mov [rel opcode], bl
    ; Convert immediate value
    mov rdi, [rel operand2]
    call atoi_wrapper
    mov eax, [rel atoi_result]
    lea rbx, [rel opcode]
    mov [rbx + 1], eax
    mov dword [rel op_len], 5  ; 1 byte opcode + 4 bytes immediate
    jmp parse_end

handle_add:
    ; ADD reg1, reg2
    ; opcode: 0x01 | modrm_byte
    mov al, byte [rel opcode_add]          ; Move byte value from opcode_add to AL register
    mov [rel opcode], al                   ; Then move the byte value from AL to the memory location at opcode
    mov rdi, [rel operand1]
    mov rsi, [rel operand2]
    call get_modrm_byte
    lea rbx, [rel opcode]
    mov [rbx + 1], al
    mov dword [rel op_len], 2  ; 1 byte opcode + 1 byte modrm
    jmp parse_end

handle_sub:
    ; SUB reg1, reg2
    ; opcode: 0x29 | modrm_byte
    mov al, [rel opcode_sub]               ; Load byte from opcode_sub into AL register
    mov [rel opcode], al                   ; Store byte from AL into the memory location at opcode
    mov rdi, [rel operand1]
    mov rsi, [rel operand2]
    call get_modrm_byte
    lea rbx, [rel opcode]
    mov [rbx + 1], al
    mov dword [rel op_len], 2
    jmp parse_end

handle_jmp:
    ; JMP rel32
    ; opcode: 0xE9 | offset (4 bytes)
    mov al, [rel opcode_jmp]               ; Load byte from opcode_jmp into AL register
    mov [rel opcode], al                   ; Store byte from AL into the memory location at opcode
    mov rdi, [rel operand1]
    call atoi_wrapper
    mov eax, [rel atoi_result]
    lea rbx, [rel opcode]
    mov [rbx + 1], eax
    mov dword [rel op_len], 5
    jmp parse_end

parse_end:
    pop rbp
    ret

; -----------------------------------------
; get_register_code:
; Returns register code for given register name.
; Input:
;   rdi - pointer to register name string
; Output:
;   al - register code or 0xFF if invalid
; -----------------------------------------
get_register_code:
    push rbp
    mov rbp, rsp

    lea rax, [rdi]
    call str_compare_eax
    cmp al, 1
    je reg_eax_label

    call str_compare_ecx
    cmp al, 1
    je reg_ecx_label

    call str_compare_edx
    cmp al, 1
    je reg_edx_label

    call str_compare_ebx
    cmp al, 1
    je reg_ebx_label

    mov al, 0xFF    ; Invalid code
    jmp reg_code_end

reg_eax_label:
    mov al, 0x00
    jmp reg_code_end

reg_ecx_label:
    mov al, 0x01
    jmp reg_code_end

reg_edx_label:
    mov al, 0x02
    jmp reg_code_end

reg_ebx_label:
    mov al, 0x03
    jmp reg_code_end

reg_code_end:
    pop rbp
    ret

; -----------------------------------------
; get_modrm_byte:
; Generates ModRM byte for two registers.
; Inputs:
;   rdi - pointer to dest register string
;   rsi - pointer to src register string
; Output:
;   al - ModRM byte
; -----------------------------------------
get_modrm_byte:
    push rbp
    mov rbp, rsp

    ; Get dest register code
    mov rdi, [rdi]
    call get_register_code
    mov bl, al

    ; Get src register code
    mov rdi, [rsi]
    call get_register_code
    mov bh, al

    ; Build ModRM byte: 11|src|dest
    mov al, 0xC0
    shl bh, 3
    or al, bh
    or al, bl

    pop rbp
    ret

; -----------------------------------------
; Helper functions for string comparisons
; and conversions
; -----------------------------------------

; strcmp functions
str_compare_mov:
    push rbp
    mov rbp, rsp
    mov rdi, [rel operation]
    lea rsi, [rel mov_str]
    call strcmp
    pop rbp
    ret

str_compare_add:
    push rbp
    mov rbp, rsp
    mov rdi, [rel operation]
    lea rsi, [rel add_str]
    call strcmp
    pop rbp
    ret

str_compare_sub:
    push rbp
    mov rbp, rsp
    mov rdi, [rel operation]
    lea rsi, [rel sub_str]
    call strcmp
    pop rbp
    ret

str_compare_jmp:
    push rbp
    mov rbp, rsp
    mov rdi, [rel operation]
    lea rsi, [rel jmp_str]
    call strcmp
    pop rbp
    ret

str_compare_eax:
    push rbp
    mov rbp, rsp
    mov rdi, [rdi]
    lea rsi, [rel eax_str]
    call strcmp
    pop rbp
    ret

str_compare_ecx:
    push rbp
    mov rbp, rsp
    mov rdi, [rdi]
    lea rsi, [rel ecx_str]
    call strcmp
    pop rbp
    ret

str_compare_edx:
    push rbp
    mov rbp, rsp
    mov rdi, [rdi]
    lea rsi, [rel edx_str]
    call strcmp
    pop rbp
    ret

str_compare_ebx:
    push rbp
    mov rbp, rsp
    mov rdi, [rdi]
    lea rsi, [rel ebx_str]
    call strcmp
    pop rbp
    ret

; strcmp implementation
strcmp:
    push rbp
    mov rbp, rsp
    mov rcx, -1
    xor al, al
    repe cmpsb
    sete al
    pop rbp
    ret

; atoi wrapper
atoi_wrapper:
    ; TODO: Implement atoi function or use C library
    ret

; sscanf wrapper
sscanf_wrapper:
    ; TODO: Implement or link to sscanf function
    ret

; String constants
section .data
    operation db 10, 0
    mov_str db "mov", 0
    add_str db "add", 0
    sub_str db "sub", 0
    jmp_str db "jmp", 0
    eax_str db "eax", 0
    ecx_str db "ecx", 0
    edx_str db "edx", 0
    ebx_str db "ebx", 0
