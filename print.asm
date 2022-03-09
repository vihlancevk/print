; nasm -f elf64 -g -l print.lst print.asm
; ld -s -o print print.o

section .data

Msg:        db "Hello, world!", 0x0a

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
; Print str on screen
;
; Entry:	RSI - addr of the beginning of the string
; Exit:		
; Destr:	RAX, RCX, RDX, RSI, RDI
;------------------------------------------------

print:

    push si
    call strlen
    mov rdx, rcx
    pop si
    mov rdi, 1
    mov rax, 0x01
    syscall

    ret

global _start

_start:
    mov rsi, Msg
    call print
            
    mov rax, 0x3C
    xor rdi, rdi
    syscall