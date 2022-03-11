; nasm -f elf64 -g -l print.lst print.asm
; ld -o print print.o

section .data

Msg: db "%cello, %cor%cd%c", 0x0a

section .text

;------------------------------------------------
; String length counting function
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
    cmp [rsi], ah
    je stop_strlen
    
    inc rcx
    inc rsi
    jmp next_strlen
	
stop_strlen:
	
    ret

;------------------------------------------------
; Search function for the first occurrence
; of a character in a string
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
; Entry:	RSI - addr of the beginning of the string
; Exit:		None
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10
;------------------------------------------------

print:

    push rbp
	mov rbp, rsp

    mov r10, [rbp + 16]     ; r10 = r12
    mov r13, [rbp + 16]     ; r13 = r12
    add r13, 8

next_specifier1:
    mov rsi, [rbp + r13]
    mov rax, "%"
    call strchr
    cmp rcx, 0
    je no_specifier1

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
    mov rax, "0"
    cmp [rsi], al
    jne no_c_specifier1

    add rbp, r10
    mov rax, [rbp]
    sub rbp, r10
    sub r10, 8
    mov [rsi], al
    sub rsi, 1
    mov [rbp + r13], rsi
    jmp no_one_specifier1

no_c_specifier1:
no_one_specifier1:
    add rsi, 1
    mov [rbp + r13], rsi
    jmp next_specifier1
    
no_specifier1:
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
    jmp no_one_specifier

no_%1_specifier:
%endmacro

parser_string:

    xor r12, r12

next_specifier:
    mov rsi, rdi
    mov rax, "%"
    call strchr
    cmp rcx, 0
    je no_specifier

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
    jne no_percent_specifier

    mov rax, "6"
    mov [rdi], al
    sub r12, 8
    jmp no_one_specifier

no_percent_specifier:
no_one_specifier:
    add rdi, 1
    jmp next_specifier

no_specifier:
    add r12, 16
    ret

;------------------------------------------------
; main
;------------------------------------------------

%macro percent_c 1 
    mov r10, %1
    push r10
%endmacro

global _start

_start:

    mov rdi, Msg
    call parser_string

    mov rsi, Msg
    push rsi
    percent_c "H"
    percent_c "W"
    percent_c "L"
    percent_c "!"
    push r12
    call print
    mov rcx, 5
lp1:
    pop r10    
    loop lp1

    mov rax, 0x3C
    xor rdi, rdi
    syscall      