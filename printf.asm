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
;                   (numbers that are a power of two)
;
; Note:	    - $ - 24h (ASCII code)
;       	- the number cannot start with 0
;
; Exit:		- the address of str
; Destr:	RAX, RBX, RCX, RDX, RSI, R11, R15
;------------------------------------------------

my_itoa_binary:

    mov rcx, 0 ; degree of two of the base of the number system
.check_next_bit:
    shr rbx, 1

    jc .stop_check_bit

    inc rcx
    jmp .check_next_bit

.stop_check_bit:

	mov rdx, 0 ; number of digits in the number
.next_itoa:
    mov r11, 0 ; r11 - the register in which the digit will be written
    mov rbx, 1 ; bit multiplier

    mov r15, rcx ; save value rcx

.lp:
	shr rax, 1 ; dividing the rax register by 2
    jnc .cf_0  ; comparing the last bit of the rax number before dividing by 2 with 0

    add r11, rbx

.cf_0:
    shl rbx, 1 ; multiplying the rbx register by 2
    loop .lp

    push r11 ; 

    mov rcx, r15

    inc rdx
	cmp rax, 0
	jne .next_itoa
	    	
.reverse_itoa:
	cmp rdx, 0x0
    je .stop_itoa

    pop rax
    dec rdx
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
; Preparing the string for the my_printf function
;
; Entry:	RDI - the address of the beginning of the string
; Exit:		R12 - the number * 8 of elements in the stack
;                 for the my_printf function
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

    mov r12, 1

.next_specifier:
    mov rsi, rdi
    mov rax, "%"
    call my_strchr
    cmp rcx, 0
    je .no_one_specifier

    add rdi, rcx
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
    ret

;------------------------------------------------
; Printf the string on the screen
;
; Entry:	args in the stack
;           (address of the string - required argument)
; Exit:		none
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10, R12, R14
;------------------------------------------------

%macro percent_num_binary_out 1

    mov rsi, NUM         ; preparing arguments for itoa (rsi, rax, rbx)
    mov rax, [rbp + r12] ;
    add r12, 8           ;
    mov rbx, %1          ;
    call my_itoa_binary  ;

    mov rsi, NUM   ; preparing arguments for my_strlen
    call my_strlen ;

    mov rax, 0x1 ; output of the NUM string
    mov rdi, 1   ;
    mov rsi, NUM ;
    mov rdx, rcx ; (rdx = length of the string NUM)
    syscall      ;

    mov rsi, [rbp + 16] ; rsi = the address of the original line to output

%endmacro

%macro percent_num_no_binary_out 1

    mov rsi, NUM           ; preparing arguments for itoa (rsi, rax, rbx)
    mov rax, [rbp + r12]   ;
    add r12, 8             ;
    mov rbx, %1            ;
    call my_itoa_no_binary ;

    mov rsi, NUM   ; preparing arguments for my_strlen
    call my_strlen ;

    mov rax, 0x1 ; output of the NUM string
    mov rdi, 1   ;
    mov rsi, NUM ;
    mov rdx, rcx ; (rdx = length of the string NUM)
    syscall      ;

    mov rsi, [rbp + 16] ; rsi = the address of the original line to output

%endmacro

my_printf:

    push rbp     ; prolog
	mov rbp, rsp ;

    mov rdi, [rbp + 16] ; preparing a string
    call parser_string  ;

    cmp r12, 0            ; determining the correctness of a string
    je .return_with_error ;

    mov r10, 0 ; counter of successfully derived specifiers (except %%)
    mov r12, 24 ; offset of parameters in the stack

.next_specifier:
    mov rsi, [rbp + 16] ; search for the first character %
    mov rax, "%"        ;
    call my_strchr      ;

    cmp rcx, 0           ; determining the presence of a symbol %
    je .no_one_specifier ;

    push rcx ; saving the register value before calling syscall

    mov rax, 0x1        ;
    mov rdi, 1          ; output of the string up to %
    mov rsi, [rbp + 16] ;
    mov rdx, rcx        ;
    dec rdx             ;
    syscall             ; (registers rcx and r11 will be destroyed)
    
    pop rcx ; restoring the register value
    
    add rsi, rcx        ; changing the address of the beginning of the string
    mov [rbp + 16], rsi ;

    mov al, [rsi] ; al = one of nimbers 0 ... 6
    sub al, 0x30  ;

    lea r14, [jump_table + rax * 8] ; interaction with the jump table
    jmp [r14]                       ;

..@percent_C_out:
    mov rax, [rbp + r12] ; replacing the %c specifier with the character
    add r12, 8           ;
    mov [rsi], al        ;

    sub rsi, 1          ; changing the address of the beginning of the string
    mov [rbp + 16], rsi ;

    jmp .default

..@percent_S_out:
    mov rsi, [rbp + r12] ; output of the string that is marked with the %s specifier
    call my_strlen       ;
    mov rdx, rcx         ;
    mov rsi, [rbp + r12] ;
    add r12, 8           ;
    mov rdi, 1           ;
    mov rax, 0x1         ;
    syscall              ;

    mov rsi, [rbp + 16] ; changing the address of the beginning of the string

    jmp .default

..@percent_D_out:
    percent_num_no_binary_out 10
    jmp .default

..@percent_B_out:
    percent_num_binary_out 2
    jmp .default

..@percent_O_out:
    percent_num_binary_out 8
    jmp .default

..@percent_X_out:
    percent_num_binary_out 16
    jmp .default

..@percent_P_out:
    mov rsi, [rbp + 16] ; replacing the %c specifier with the character
    mov rax, "%"        ;
    mov [rsi], al       ;

    mov rax, 0x1 ; output %
    mov rdi, 1   ;
    mov rdx, 1   ;
    syscall      ;

    sub r10, 1; decrease by one the number of successfully derived specifiers (except %%)

    jmp .default

.default:
    add r10, 1 ; increase by one the number of successfully derived specifiers

    add rsi, 1          ; changing the address of the beginning of the string
    mov [rbp + 16], rsi ;

    jmp .next_specifier
    
.no_one_specifier:
    mov rsi, [rbp + 16] ; output of the part of the string in which there are no specifiers left
    call my_strlen      ;
    mov rdx, rcx        ;
    mov rsi, [rbp + 16] ;
    mov rdi, 1          ;
    mov rax, 0x1        ;
    syscall             ;

    mov rax, r10  ; rax = 0 - the function ended without errors

    pop rbp ; epilogue

    pop r12 ; saving the return address from the stack

;     add r10, 1   ; the original string has been successfully output

;     mov rcx, r10 ; clearing the stack after calling the my_printf function
; .lp:             ;
;     pop r10      ;
;     loop .lp     ;

    push r12 ; exiting the function 
    ret      ;

.return_with_error:
    mov rax, -1 ; rax = -1 - the function ended with errors

    pop rbp ;  epilogue
    ret     ;
    