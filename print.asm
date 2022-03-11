; nasm -f elf64 -g -l print.lst print.asm
; ld -o print print.o

section .data

Msg: db "Hello, %cor%cd!", 0x0a

section .text

global _start

_start:

    mov r10, "o"
    push r10
    mov r10, "k"
    push r10
    mov rsi, Msg
    push rsi
    call print
            
    mov rax, 0x3C
    xor rdi, rdi
    syscall

;------------------------------------------------
; Print str on screen
;
; Entry:	RSI - addr of the beginning of the string
; Exit:		
; Destr:	RAX, RCX, RDX, RSI, RDI, RBP, RSP, R10
;------------------------------------------------

print:

    push rbp
	mov rbp, rsp

    mov r10, 24     ; 24 = 3 * 8

next_specifier:
    mov rsi, [rbp + 16]     ; 16 = 2 * 8
    mov rax, "%"
    call strchr
    cmp rcx, 0
    je no_specifier

    push rcx
    mov rax, 0x1
    mov rdi, 1
    mov rsi, [rbp + 16]
    mov rdx, rcx
    dec rdx
    syscall     ; registers rcx and r11 will be destroyed
    pop rcx
    add rsi, rcx
    mov [rbp + 16], rsi
    mov rax, "c"
    cmp [rsi], al
    jne no_c_specifier

    ; ToDo
    add rbp, r10
    mov rax, [rbp]
    sub rbp, r10
    add r10, 8
    mov [rsi], al
    sub rsi, 1
    mov [rbp + 16], rsi

no_c_specifier:
    add rsi, 1
    mov [rbp + 16], rsi
    jmp next_specifier
    
no_specifier:
    mov rsi, [rbp + 16]
    call strlen
    mov rdx, rcx
    mov rsi, [rbp + 16]
    mov rdi, 1
    mov rax, 0x1
    syscall

    pop rbp

    ret 3 * 4

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