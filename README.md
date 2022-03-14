# printf
The function outputs a message with specifiers.  
Entry:  - message with specifiers (required parameter):  
          1) *%c* - outputs a character;  
          2) *%s* - outputs a string;  
          3) *%d* - outputs a decimal representation of a number;  
          4) *%b* - outputs a binary representation of a number;  
          5) *%o* - outputs an octal representation of a number;  
          6) *%x* - outputs the hexadecimal representation of a number;  
          7) *%%* - outputs a percentage.  
        - other parameters that are optional  
Note:   first, the optional parameters must be passed to the function, and then the mandatory parameter  
Exit:   the results of the function are transmitted via the RAX register  
        - RAX = 0  - the function ended without errors  
        - RAX = -1 - the function ended with errors

