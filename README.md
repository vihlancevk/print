# printf
The function outputs a message with specifiers.  
## Entry:
- message with specifiers (required parameter):  
1) *%c* - outputs a character;  
2) *%s* - outputs a string;  
3) *%d* - outputs a decimal representation of a number;  
4) *%b* - outputs a binary representation of a number;  
5) *%o* - outputs an octal representation of a number;  
6) *%x* - outputs the hexadecimal representation of a number;  
7) *%%* - outputs a percentage.  
- other parameters that are optional  
## Note:
- parameters are passed through the stack from right to left  
- the program does not clear the stack of arguments after its completion  
- if the number of specifiers (except %) in the message is less than the number of optional parameters then the behavior of the function is undefined  
## Exit:
the results of the function are transmitted via the RAX register  
- RAX = the number of parameters recorded in the message  - the function ended without errors  
- RAX = -1 - the function ended with errors

