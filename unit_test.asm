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

    percent_specifier_in "H"
    percent_specifier_in "W"
    percent_specifier_in "L"
    percent_specifier_in "!"
    percent_specifier_in STR1
    percent_specifier_in 0
    percent_specifier_in 10
    percent_specifier_in 10
    percent_specifier_in 389

    mov rsi, MSG
    push rsi
    call my_printf

    mov rax, 0x3C ; completion of the program
    xor rdi, rdi  ;
    syscall       ;
