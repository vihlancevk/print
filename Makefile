all:
	nasm -f elf64 -g -l unit_test.lst unit_test.asm
	ld -o unit_test unit_test.o
	./unit_test

