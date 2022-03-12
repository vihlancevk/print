; nasm -f elf64 -g -l print.lst print.asm
; ld -o print print.o
; ./print

section .rodata align = 8

jump_table:
    .L1 dq percent_C_out ; %c - 0
    .L2 dq percent_S_out ; %s - 1
    .L3 dq percent_D_out ; %d - 2
    .L4 dq percent_B_out ; %b - 3
    .L5 dq percent_O_out ; %o - 4
    .L6 dq percent_X_out ; %x - 5
    .L7 dq percent_P_out ; %% - 6

section .data

ERROR: db "Wrong format input string!", 0x0a
ERROR_LEN equ $ - ERROR

MSG: db "%cello, %% %cor%cd%c %s", 0x0a, "$"

STR1: db "My name is Kostya!$"

section .text

;------------------------------------------------
; String length counting function (the string must
; end with the character $)
;
; Entry:	RSI - addr of the beginning of the string
; Note:		$ - 24h (ASCII code)
; Exit:		RCX - string length
; Destr:	RAX, RCX, RSI
;------------------------------------------------

strlen:

    mov rax, 0x24
	mov rcx, 0      ; rcx - length of the string	

next_strlen:
    cmp [rsi], al
    je stop_strlen
    
    inc rcx
    inc rsi
    jmp next_strlen
	
stop_strlen:
	
    ret

;------------------------------------------------
; Search function for the first occurrence
; of a character in a string (the string must
; end with the character $)
;
; Entry:	- RSI - addr of the beginning of the string
;           - RAX - the symbol to be found
; Note:     - $ - 24h (ASCII code)
;           - returns 0 if the character is not in the string
; Exit:		RCX - address of the first occurrence of the character in the str
; Destr:	RAX, RBX, RCX, RSI, R8, R9
;------------------------------------------------

strchr:

    mov r8, rsi
    mov r9, rax
	call strlen
	mov rbx, rcx
    mov rsi, r8
    mov rax, r9
	mov rcx, 1

next_chr:
    cmp [rsi], al
	je stop_chr
		
    inc rcx
    inc rsi
    cmp rcx, rbx
    jl next_chr

    mov rcx, 0 
        
stop_chr:
        
	ret

;------------------------------------------------
; Print str on screen
;
; Entry:	args in the stack
; Exit:		None
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10, R14
;------------------------------------------------

print:

    push rbp
	mov rbp, rsp

    mov r10, [rbp + 16]     ; r10 = r12
    mov r13, [rbp + 16]     ; r13 = r12
    add r13, 8

_next_specifier_:
    mov rsi, [rbp + r13]
    mov rax, "%"
    call strchr
    cmp rcx, 0
    je _no_one_specifier_

    push rcx
    mov rax, 0x1
    mov rdi, 1
    mov rsi, [rbp + r13]
    mov rdx, rcx
    dec rdx
    syscall     ; registers rcx and r11 will be destroyed
    pop rcx
    add rsi, rcx
    mov [rbp + r13], rsi
    mov al, [rsi]
    sub al, 0x30

    lea r14, [jump_table + rax * 8]
    jmp [r14]

percent_C_out:
    add rbp, r10
    mov rax, [rbp]
    sub rbp, r10
    sub r10, 8
    mov [rsi], al
    sub rsi, 1
    mov [rbp + r13], rsi
    jmp _default_

percent_S_out:
    add rbp, r10
    mov rsi, [rbp]
    call strlen
    mov rdx, rcx
    mov rsi, [rbp]
    sub rbp, r10
    sub r10, 8
    mov rdi, 1
    mov rax, 0x1
    jmp _default_


percent_D_out:


percent_B_out:


percent_O_out:


percent_X_out:
    ; ToDo
    jmp _default_

percent_P_out:
    mov rsi, [rbp + r13]
    mov rax, "%"
    mov [rsi], al
    mov rax, 0x1
    mov rdi, 1
    mov rdx, 1
    syscall
    jmp _default_

_default_:
    add rsi, 1
    mov [rbp + r13], rsi
    jmp _next_specifier_
    
_no_one_specifier_:
    mov rsi, [rbp + r13]
    call strlen
    mov rdx, rcx
    mov rsi, [rbp + r13]
    mov rdi, 1
    mov rax, 0x1
    syscall

    pop rbp
    ret

;------------------------------------------------
; Preparing a string for the print function
;
; Entry:	RDI - addr of the beginning of the string
; Exit:		R12 - the number of elements in the stack for the print function
; Note:     c - 0, s - 1, d - 2, b - 3, o - 4, x - 5, % - 6
; Destr:	RAX, RCX, RSI, RDI, R12
;------------------------------------------------

%macro check_sym 3 
    mov rax, %2
    cmp [rdi], al
    jne no_%1_specifier

    mov rax, %3
    mov [rdi], al
    jmp no_specifier

no_%1_specifier:
%endmacro

parser_string:

    xor r12, r12

next_specifier:
    mov rsi, rdi
    mov rax, "%"
    call strchr
    cmp rcx, 0
    je no_one_specifier

    add rdi, rcx
    add r12, 8
    check_sym c, "c", "0"
    check_sym s, "s", "1"
    check_sym d, "d", "2"
    check_sym b, "b", "3"
    check_sym o, "o", "4"
    check_sym x, "x", "5"
    mov rax, "%"        ; check_sym %, "%", 6
    cmp [rdi], al
    jne wrong_specifier

    mov rax, "6"
    mov [rdi], al
    sub r12, 8
    jmp no_specifier

wrong_specifier:
    mov rax, 0x1
    mov rdi, 1
    mov rsi, ERROR
    mov rdx, ERROR_LEN
    syscall
    xor r12, r12
    ret

no_specifier:
    add rdi, 1
    jmp next_specifier

no_one_specifier:
    add r12, 16
    ret

;------------------------------------------------
; main
;------------------------------------------------

%macro percent_specifier_in 1 
    mov r10, %1
    push r10
%endmacro

global _start

_start:

    mov rdi, MSG
    call parser_string
    cmp r12, 0
    je return

    ; mov rsi, MSG
    ; call strlen
    ; mov rdx, rcx
    ; mov rsi, MSG
    ; mov rax, 0x1
    ; mov rdi, 1
    ; syscall

    mov rsi, MSG
    push rsi
    percent_specifier_in "H"
    percent_specifier_in "W"
    percent_specifier_in "L"
    percent_specifier_in "!"
    percent_specifier_in STR1
    push r12
    call print
    mov rcx, 5
lp1:
    pop r10    
    loop lp1

    ; mov r8, jump_table.L1
    ; mov r9, jump_table.L2
    ; mov r10, jump_table.L3
    ; mov r11, jump_table.L4
    ; mov r12, jump_table.L5
    ; mov r13, jump_table.L6
    ; mov r14, jump_table.L7

return:
    mov rax, 0x3C
    xor rdi, rdi
    syscall      