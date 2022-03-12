section .rodata align = 8

jump_table: 
    dq ..@percent_C_out ; %c - 0
    dq ..@percent_S_out ; %s - 1
    dq ..@percent_D_out ; %d - 2
    dq ..@percent_B_out ; %b - 3
    dq ..@percent_O_out ; %o - 4
    dq ..@percent_X_out ; %x - 5
    dq ..@percent_P_out ; %% - 6

section .data

ERROR: db "Wrong format input string!", 0x0a ; messages warning the user about an error in the program
ERROR_LEN equ $ - ERROR                      ; the length of this message

MSG: db "%cello, %% %cor%cd%c %s %d %b %o %x", 0x0a, "$"

STR1: db "My name is Kostya!$"

NUM: db "" ; buffer for itoa

section .text

;------------------------------------------------
; String length counting function (the string must
; end with the character $)
;
; Entry:	RSI - address of the beginning of the string
; Note:		$ - 24h (ASCII code)
; Exit:		RCX - string length
; Destr:	RAX, RCX, RSI
;------------------------------------------------

my_strlen:

    mov rax, 0x24
	mov rcx, 0 ; rcx - length of the string	

.next_strlen:
    cmp [rsi], al
    je .stop_strlen
    
    inc rcx
    inc rsi
    jmp .next_strlen
	
.stop_strlen:
	
    ret

;------------------------------------------------
; Search function for the first occurrence
; of a character in a string (the string must
; end with the character $)
;
; Entry:	- RSI - the address of the beginning of the string
;           - RAX - the symbol to be found
; Note:     - $ - 24h (ASCII code)
;           - returns 0 if the character is not in the string
; Exit:		RCX - the address of the first occurrence
;           of the character in the string
; Destr:	RBX, RCX, RSI
;------------------------------------------------

my_strchr:

    mov rcx, 1
    mov rbx, 0x24

.next_chr:
    cmp [rsi], al
	je .stop_chr
		
    cmp [rsi], bl
    je .no_sym_in_str

    inc rcx
    inc rsi
    jmp .next_chr

.no_sym_in_str:
    mov rcx, 0 
        
.stop_chr:  
	ret

;------------------------------------------------
; Converting the number to the string (the string must
; end with the character $)
;
; Entry:	- RSI - the address of string for output answer
;           - RAX - the number
;           - RBX - the base of the number system
;                   (numbers that are not a power of two)
;
; Note:	    - $ - 24h (ASCII code)
;       	- the number cannot start with 0
;
; Exit:		- the address of str
; Destr:	RAX, RBX, RCX, RDX, RSI
;------------------------------------------------

my_itoa_no_binary:
    
	mov rcx, 0
.next_itoa:
	mov rdx, 0
    div rbx
    push rdx
    inc rcx
	cmp rax, 0
	jne .next_itoa
	    	
.reverse_itoa:
	cmp rcx, 0x0
    je .stop_itoa

    pop rax
    dec rcx
    mov rbx, 0x0a
    cmp rax, rbx
    jl .num

    add rax, 07h
                        
.num:
	add rax, 30h
    mov [rsi], rax
    inc rsi
    jmp .reverse_itoa
    
.stop_itoa:
	mov rbx, 0x24
    mov [rsi], rbx
    
    ret

;------------------------------------------------
; Printf the string on the screen
;
; Entry:	args in the stack
; Exit:		none
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10, R14
;------------------------------------------------

%macro percent_num_out 1

    mov rsi, NUM           ;
    mov rax, [rbp + r10]   ; preparing arguments for itoa
    sub r10, 8             ; (rsi, rax, rbx)
    mov rbx, %1            ;
    call my_itoa_no_binary ;

    mov rsi, NUM   ; preparing arguments for my_strlen
    call my_strlen ;

    mov rax, 0x1 ; output of the NUM string
    mov rdi, 1   ;
    mov rsi, NUM ;
    mov rdx, rcx ; (rdx = length of the string NUM)
    syscall      ;

    mov rsi, [rbp + r13] ; rsi = the address of the original line to output

%endmacro

my_printf:

    push rbp     ; prolog
	mov rbp, rsp ;

    mov r10, [rbp + 16] ; r10 = r12
    mov r13, [rbp + 16] ; r13 = r12
    add r13, 8

.next_specifier:
    mov rsi, [rbp + r13]
    mov rax, "%"
    call my_strchr
    cmp rcx, 0
    je .no_one_specifier

    push rcx

    mov rax, 0x1         ;
    mov rdi, 1           ; output of the string up to %
    mov rsi, [rbp + r13] ;
    mov rdx, rcx         ;
    dec rdx              ;
    syscall              ; (registers rcx and r11 will be destroyed)
    
    pop rcx
    
    add rsi, rcx         ; changing the address of the beginning of the string
    mov [rbp + r13], rsi ;

    mov al, [rsi] ; al = one of nimbers 0 ... 6
    sub al, 0x30  ;

    lea r14, [jump_table + rax * 8] ; interaction with the jump table
    jmp [r14]                       ;

..@percent_C_out:
    mov rax, [rbp + r10] ; replacing the %c specifier with the character
    sub r10, 8           ;
    mov [rsi], al        ;

    sub rsi, 1           ; changing the address of the beginning of the string
    mov [rbp + r13], rsi ;

    jmp .default

..@percent_S_out:
    mov rax, 0x1         ; output of the string that is marked with the %s specifier
    mov rdi, 1           ;
    mov rsi, [rbp + r10] ;
    sub r10, 8           ;
    mov rdx, [rbp + r10] ;
    sub r10, 8           ;
    syscall              ;

    mov rsi, [rbp + r13] ; changing the address of the beginning of the string

    jmp .default

..@percent_D_out:
    percent_num_out 10
    jmp .default

..@percent_B_out:
    percent_num_out 2
    jmp .default

..@percent_O_out:
    percent_num_out 8
    jmp .default

..@percent_X_out:
    percent_num_out 16
    jmp .default

..@percent_P_out:
    mov rsi, [rbp + r13] ; replacing the %c specifier with the character
    mov rax, "%"         ;
    mov [rsi], al        ;

    mov rax, 0x1 ; output %
    mov rdi, 1   ;
    mov rdx, 1   ;
    syscall      ;

    jmp .default

.default:
    add rsi, 1           ; changing the address of the beginning of the string
    mov [rbp + r13], rsi ;

    jmp .next_specifier
    
.no_one_specifier:
    mov rsi, [rbp + r13] ; output of the part of the string in which there are no specifiers left
    call my_strlen       ;
    mov rdx, rcx         ;
    mov rsi, [rbp + r13] ;
    mov rdi, 1           ;
    mov rax, 0x1         ;
    syscall              ;

    pop rbp ;  epilogue
    ret     ;

;------------------------------------------------
; Preparing the string for the my_printf function
;
; Entry:	RDI - the address of the beginning of the string
; Exit:		R12 - the number * 8 of elements in the stack for the my_printf function
; Note:     c - 0, s - 1, d - 2, b - 3, o - 4, x - 5, % - 6
; Destr:	RAX, RCX, RSI, RDI, R12
;------------------------------------------------

%macro check_sym 3 
    mov rax, %2
    cmp [rdi], al
    jne .no_%1_specifier

    mov rax, %3
    mov [rdi], al
    jmp .no_specifier

.no_%1_specifier:
%endmacro

parser_string:

    xor r12, r12

.next_specifier:
    mov rsi, rdi
    mov rax, "%"
    call my_strchr
    cmp rcx, 0
    je .no_one_specifier

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
    jne .wrong_specifier

    mov rax, "6"
    mov [rdi], al
    sub r12, 8
    jmp .no_specifier

.wrong_specifier:
    mov rax, 0x1       ; error message output
    mov rdi, 1         ;
    mov rsi, ERROR     ;
    mov rdx, ERROR_LEN ;
    syscall            ;

    xor r12, r12
    ret

.no_specifier:
    add rdi, 1
    jmp .next_specifier

.no_one_specifier:
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
    call my_strlen
    push rcx
    add r12, 8
%endmacro

global _start

_start:

    mov rdi, MSG       ; preparing a string for the my_printf function
    call parser_string ;
    cmp r12, 0         ;
    je .return

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
    call my_printf
    mov rcx, r12 ; clearing the stack after calling the my_printf function
.lp:             ;
    pop r10      ;
    sub rcx, 7   ;
    loop .lp     ;

.return:
    mov rax, 0x3C ; completion of the program
    xor rdi, rdi  ;
    syscall       ;
