section .data

MSG: db "%cello, %%%% %cor%cd%c %s %d %b %o %x", 0x0a, "$"

STR1: db "My name is Kostya!$"

section .text

%include "printf.asm"

%macro percent_specifier_in 1
    mov r10, %1
    push r10
%endmacro

global _start

_start:

    mov rdi, MSG
    mov rsi, "H"
    mov rdx, "W"
    mov rcx, "L"
    mov r8, "!"
    mov r9, STR1
    percent_specifier_in 389
    percent_specifier_in 10
    percent_specifier_in 10
    percent_specifier_in 0
    call my_printf_stdcall

    mov rax, 0x3C ; completion of the program
    xor rdi, rdi  ;
    syscall       ;
