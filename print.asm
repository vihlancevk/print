; nasm -f elf64 -g -l print.lst print.asm
; ld -s -o print print.o

section .data

Msg:    db "Hello, %cworld!", 0x0a

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
	mov rcx, 0x0		; rcx - length of the string	

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
	mov rcx, 0x1

next_chr:
    cmp [rsi], al
	je stop_chr
		
    inc rcx
    inc rsi
    cmp rcx, rbx
    jl next_chr

    mov rcx, 0x0 
        
stop_chr:
        
	ret      

;------------------------------------------------
; Print str on screen
;
; Entry:	RSI - addr of the beginning of the string
; Exit:		
; Destr:	RAX, RCX, RDX, RSI, RDI
;------------------------------------------------

print:

next_specifier:
    push si
    mov rax, "%"
    call strchr
    pop si
    cmp rcx, 0x0
    je no_specifier

    push rcx
    mov rax, 0x1
    mov rdi, 1
    mov rdx, rcx
    dec rdx
    syscall     ; registers rcx and r11 will be destroyed
    pop rcx
    add rsi, rcx
    ; ToDo
    add rsi, 1
    jmp next_specifier
    
no_specifier:
    push si
    call strlen
    pop si
    mov rdx, rcx
    mov rdi, 1
    mov rax, 0x1
    syscall

    ret

global _start

_start:

    mov rsi, Msg
    call print
            
    mov rax, 0x3C
    xor rdi, rdi
    syscall