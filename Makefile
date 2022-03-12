all:
	nasm -f elf64 -g -l printf.lst printf.asm
	ld -o printf printf.o
	./printf 

