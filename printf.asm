; nasm -f elf64 -g -l printf.lst printf.asm
; ld -o printf printf.o
; ./printf

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

MSG: db "%cello, %% %cor%cd%c %s %d %b %o %x", 0x0a, "$"

STR1: db "My name is Kostya!$"

NUM: db ""  ; buffer for itoa

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
; Converting a number to a string (the string must
; end with the character $)
;
; Entry:	- RSI - addr of string for output answer
;           - RAX - the number
;           - RBX - the base of the number system
;
; Note:	    - $ - 24h (ASCII code)
;       	- a number cannot start with 0
;
; Exit:		- addr of str
; Destr:	RAX, RBX, RCX, RDX, RSI
;------------------------------------------------

itoa:
    
	mov rcx, 0
next_itoa:
	mov rdx, 0
    div rbx
    push rdx
    inc rcx
	cmp rax, 0
	jne next_itoa
	    	
reverse_itoa:
	cmp rcx, 0x0
    je stop_itoa

    pop rax
    dec rcx
    mov rbx, 0x0a
    cmp rax, rbx
    jl num

    add rax, 07h
                        
num:
	add rax, 30h
    mov [rsi], rax
    inc rsi
    jmp reverse_itoa
    
    
stop_itoa:
	mov rbx, 0x24
    mov [rsi], rbx
    
    ret

;------------------------------------------------
; Printf str on screen
;
; Entry:	args in the stack
; Exit:		None
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10, R14
;------------------------------------------------

%macro percent_num_out 1

    mov rsi, NUM
    add rbp, r10
    mov rax, [rbp]
    sub rbp, r10
    sub r10, 8
    mov rbx, %1
    call itoa
    mov rsi, NUM
    call strlen
    mov rdx, rcx
    mov rsi, NUM
    mov rdi, 1
    mov rax, 0x1
    syscall
    mov rsi, [rbp + r13]

%endmacro

printf:

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
    mov rax, 0x1
    mov rdi, 1
    add rbp, r10
    mov rsi, [rbp]
    sub rbp, r10
    sub r10, 8
    add rbp, r10
    mov rdx, [rbp]
    sub rbp, r10
    sub r10, 8
    syscall
    mov rsi, [rbp + r13]
    jmp _default_


percent_D_out:
    percent_num_out 10
    jmp _default_

percent_B_out:
    percent_num_out 2
    jmp _default_

percent_O_out:
    percent_num_out 8
    jmp _default_

percent_X_out:
    percent_num_out 16
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
; Preparing a string for the printf function
;
; Entry:	RDI - addr of the beginning of the string
; Exit:		R12 - the number of elements in the stack for the printf function
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

%macro percent_sym_or_num_in 1
    mov r10, %1
    push r10
%endmacro

%macro percent_str_in 1
    mov r10, STR%1
    push r10
    mov rsi, STR%1
    call strlen
    push rcx
    add r12, 8
%endmacro

global _start

_start:

    mov rdi, MSG
    call parser_string
    cmp r12, 0
    je return

    mov rsi, MSG
    push rsi
    percent_sym_or_num_in "H"
    percent_sym_or_num_in "W"
    percent_sym_or_num_in "L"
    percent_sym_or_num_in "!"
    percent_str_in 1
    percent_sym_or_num_in 10
    percent_sym_or_num_in 10
    percent_sym_or_num_in 10
    percent_sym_or_num_in 10
    push r12
    call printf
debug:    mov rcx, r12
lp1:
    pop r10
    sub rcx, 7    
    loop lp1

return:
    mov rax, 0x3C
    xor rdi, rdi
    syscall