%{
	#define BUFFERLEN 32	// size for one symbol name string: var1, var22, etc.
				// note: there is a possible bug: max variable name is 8 characters
	#include <stdio.h>	// printf()
	#include <stdlib.h>	// exit()
	#include "linkedlist.h" // custom linkedlist
	#include "util.h"	// temp variable name generator, address generator

	void yyerror(char *);
	int yylex(void);
	extern FILE *yyin;
	extern int linenum;
	FILE* outputFile;	// for outputing variable values to a  file
	int yydebug=1;	/*this actives the debug mode of yacc*/
	int verbose=0;	// indicetes if this program is verbose
	int labelNumber;	// this is for passing label number around
	char stateConditionOfIf[BUFFERLEN];	// this is for passing around if's condition
/*expression is defined as string to pass its varible name around*/
%}

%union
{
// is used to get the type of lexemes
int number;
char* string;
}
%token <number> INTEGER 
%token <string> IDENTIFIER 
%token MINUSOP PLUSOP OPENPAR CLOSEPAR MULTOP ASSIGNOP SEMICOLON 
%token OPENCURL CLOSECURL EQUAL NOTEQUAL LESSEQUAL GREATEQUAL
%token INT IF ELSE RETURN LESSTHAN GREATERTHAN DOT COMMA
%type <string> expression assign assignment
%type <string> equality
%type <number> if_begin
%left ASSIGNOP
%left EQUAL NOTEQUAL LESSEQUAL GREATEQUAL LESSTHAN GREATERTHAN
%left PLUSOP MINUSOP
%left MULTOP 
%%

program		: statement
		| statement program
		;

statement	: assignment SEMICOLON
		{
			struct symbol* dollarOne  = lookForSymbol( $1 );	// string in IDENTIFIER

			if ( dollarOne == NULL )
			{
				// give an error and exit because variable isn't defined yet
				fprintf(stderr, "The variable %s is not defined yet! +++++ %d\n", $1, linenum);
				exit(1);
			}
		}
		| INT assignment SEMICOLON
		{
			struct symbol* dollarTwo  = lookForSymbol( $2 );		// string in IDENTIFIER
			char nameBuffer[BUFFERLEN];

			if ( dollarTwo != NULL && dollarTwo->definedWithoutKnowing == 0 )	// means "i knew it was not definded
												// but i declared anyway. and good thing 
												// that i did because it was needed
												// anyway" to the program
												// this solves problem that if a variable
												// was defined or not
			{
				// give an error and exit because variable is already defined
				fprintf(stderr, "The variable %s has already been defined! +++++ %d\n", $2, linenum);
				exit(1);
			}

		}
		
		| INT IDENTIFIER SEMICOLON	// int b1;
		{
			struct symbol* dollarTwo  = lookForSymbol( $2 );
			char nameBuffer[BUFFERLEN];
			char addressBuffer[BUFFERLEN];

			if ( dollarTwo == NULL )
			{
				strncpy( addressBuffer, generateMainAddress(), sizeof(addressBuffer) );				   
				strncpy( nameBuffer, $2, sizeof(nameBuffer) );
				addToSymbolTable( nameBuffer, addressBuffer );
			}
			else if ( dollarTwo->definedWithoutKnowing == 0 )
			{
				// give an error and exit because variable is already defined
				fprintf(stderr, "The variable %s has already been defined!! +++++ %d\n", $2, linenum);
				exit(1);
			}
		}

		| if_statement
		| return
		;

assignment	: assign
		{
			$$ = $1;
		}

		| assign COMMA assignment
		{
			$$ = $1;
		}
		;

assign		: IDENTIFIER
		{
			$$ = $1;
		}

		| IDENTIFIER ASSIGNOP expression 
		{
			// act like its a variable decleration. if it isn't give the error at "statement"
			// addToSymbolTable( $look ofr symbol here for $1, generateMainAddress() );

			struct symbol* dollarOne  = lookForSymbol( $1 );	// string in IDENTIFIER
			struct symbol* dollarThree   = lookForSymbol( $3 );	// look for $3 to access its 6800 address
			struct symbol* temp;
			int value;
			char nameBuffer[BUFFERLEN];
			char addressBuffer[BUFFERLEN];
			int pseudoIsUsed = 0;	// a flag to keep what is used
			if(dollarOne == NULL)	// if symbol is not in the symbol table
			{	
				strncpy( addressBuffer, generateMainAddress(), sizeof(addressBuffer) );
				strncpy( nameBuffer, $1, sizeof(nameBuffer) );
				addToSymbolTable( nameBuffer, addressBuffer );
				dollarOne = lookForSymbol($1);
				dollarOne->definedWithoutKnowing = 1;
			}
			value = atoi($3);
			if( value != 0 )	//$3 is a numerical value
			{ 
				fprintf(outputFile, "\tLD #%d\n", value);		// this is the numeric value that 
				fprintf(outputFile, "\tST $%s\n\n", dollarOne->varValue);		// store to address

				// write to file
			}
	
			if (dollarThree == NULL)	// if this is not the real variable name find for the pseudo name
			{
				dollarThree = lookForPseudoName( $3 );
				pseudoIsUsed = 1;
			}
			if (dollarThree != NULL)	// $3 is in the symbol table
			{
				fprintf(outputFile, "\tLD $%s\n", dollarThree->varValue);
				fprintf(outputFile, "\tST $%s\n\n", dollarOne->varValue);
				// write to output
			}

			//printf("T: %s",$1);
			$$ = $1;
		};

if_statement : if_begin assignment SEMICOLON
		{
            fprintf(outputFile, "if%d\tNOP\n\n", $1);
            fprintf(outputFile, "belse%d\tNOP\n\n", $1);

		}

		| if_begin assignment SEMICOLON else_statement
		{
            fprintf(outputFile, "if%d\tNOP\n\n", $1);
		}


		| if_begin OPENCURL program CLOSECURL
		{
            fprintf(outputFile, "if%d\tNOP\n\n", $1);
            fprintf(outputFile, "belse%d\tNOP\n\n", $1);
		}

		| if_begin OPENCURL program CLOSECURL else_statement
		{
            fprintf(outputFile, "if%d\tNOP\n\n", $1);
		};

if_begin : IF OPENPAR expression CLOSEPAR
		{
			labelNumber = generateLabelNumber();
			strncpy ( stateConditionOfIf, $3, sizeof(stateConditionOfIf) );

			if( !strcmp( $3, "eequal" ) ) // if they are equal; jump if they are not equal
        	{
				
				fprintf(outputFile, "\tJNE bfalse%d\n\n", labelNumber);

      		}

        	if( !strcmp( $3, "enotequal" ) )	// jump if they are equal
			{
                fprintf(outputFile, "\tJE bfalse%d\n\n", labelNumber);

			}
            if( !strcmp( $3, "egreaterthan" ) )
			{
            
                fprintf(outputFile, "\tJNZ bfalse_%d\n\n", labelNumber);
                fprintf(outputFile, "\tbfalse_%d:\n\n", labelNumber);
				fprintf(outputFile, "\tJC bfalse%d\n\n", labelNumber);

			}	

            if( !strcmp( $3, "elessthan" ) )
			{
                fprintf(outputFile, "\tJNC bfalse%d\n\n", labelNumber);
			}

            if( !strcmp( $3, "elessequal" ) )
			{
            	fprintf(outputFile, "\tJC btrue%d\n", labelNumber);
                fprintf(outputFile, "\tJNZ bfalse%d\n\n", labelNumber);
                fprintf(outputFile, "\tbtrue%d:\n", labelNumber);

			}
			if( !strcmp( $3, "egreatequal" ) )	// if(>=) so jump if <
			{
                fprintf(outputFile, "\tJNC bfalse_%d\n", labelNumber);
                fprintf(outputFile, "\tbfalse_%d:\n", labelNumber);
                fprintf(outputFile, "\tJNZ bfalse%d\n", labelNumber);
			}

			$$ = labelNumber;
		};

else_statement	: else_begin assignment SEMICOLON
		| else_begin if_statement
		| else_begin OPENCURL program CLOSECURL
		;

else_begin	: ELSE
		{
			if( !strcmp( stateConditionOfIf, "eequal" ) ) // if they are equal; jump if they are not equal
        	{
                fprintf(outputFile, "\tJMP if%d\n\n", labelNumber);				
				fprintf(outputFile, "\tbfalse%d:\n", labelNumber);
        	}
			if( !strcmp( stateConditionOfIf, "enotequal" ) )	// jump if they are equal
			{
				fprintf(outputFile, "\tJMP if%d\n\n", labelNumber);				
				fprintf(outputFile, "\tbfalse%d:\n", labelNumber, labelNumber);
			}
            if( !strcmp( stateConditionOfIf, "egreaterthan" ) )
			{
                fprintf(outputFile, "\tJMP if%d\n", labelNumber);				
				fprintf(outputFile, "\tbfalse%d:\n",labelNumber);
			}	

            if( !strcmp( stateConditionOfIf, "elessthan" ) )
			{
				fprintf(outputFile, "\tJMP if%d\n\n", labelNumber);
                fprintf(outputFile, "\tbfalse%d:\n",labelNumber);
			}

            if( !strcmp( stateConditionOfIf, "elessequal" ) )
			{
                fprintf(outputFile, "\tJMP if%d\n\n", labelNumber);
                fprintf(outputFile, "\tbfalse%d:\n", labelNumber);
			}

            if( !strcmp( stateConditionOfIf, "egreatequal" ) )	// if(>=) so jump if <
			{
                fprintf(outputFile, "\tJMP if%d\n\n", labelNumber);             
			    fprintf(outputFile, "\tbfalse%d:\n", labelNumber);
			}
		};

expression	: INTEGER
		{
			// here you get expression as an integer. so convert it to string.
			char buffer[BUFFERLEN];
			sprintf(buffer, "%d", $1);
			$$ = strdup(buffer);
		}
	  
		| IDENTIFIER
		{
			$$ = $1;
		}

		| expression PLUSOP expression
		{
			char tempPseudo[BUFFERLEN];	// make a new temp variable.
							// generate a new name for that.
							// generate a new address for that.
			char tempPseudoAddress[BUFFERLEN];
			strncpy ( tempPseudoAddress, generateTempAddress(), sizeof(tempPseudoAddress) );
			strncpy( tempPseudo, generateVariableName(), sizeof(tempPseudo) );
			addToSymbolTableOnlyPseudo( tempPseudo, tempPseudoAddress );
			struct symbol* tempPseudoNode = lookForPseudoName( tempPseudo );

			struct symbol* dollarOne   = lookForSymbol( $1 );
			struct symbol* dollarThree = lookForSymbol( $3 );
			// if they are not variable names look for them in pseudoname. may introduce errors (bugs) to the program
			if (dollarOne == NULL)
				dollarOne   = lookForPseudoName( $1 );
			if (dollarThree == NULL)
				dollarThree = lookForPseudoName( $3 );

			if (dollarOne != NULL && dollarThree != NULL)// both first and second are in symbol table and are not numeric values
			{
				char c = getRegister() + 'A';
				char c_ = getRegister() + 'A';

				fprintf(outputFile, "\t MOV %c, $%s\n",c, dollarOne->varValue);		  // load $1's address
				fprintf(outputFile, "\t MOV %c, $%s\n",c_, dollarThree->varValue);		  // load $3's address
				fprintf(outputFile, "\tADD %c, %c\n", c,c_);
				fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);		  // store to tempPseudo's address
				// write to file
			}	

			if (dollarOne != NULL && atoi($3) != 0 )	// first exists and second is a numeric value
			{
				char c = getRegister() + 'A';
				fprintf(outputFile, "\tMOV %c, $%s\n",c ,dollarOne->varValue);
				fprintf(outputFile, "\tADD %c, #%s\n",c , $3);
				fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);
			}
			if ( atoi($1) != 0 && dollarThree != NULL )	// second exists and first is a numeric value
			{
				char c = getRegister() +'A';
				fprintf(outputFile, "\tMOV %c, $%s\n",c, dollarThree->varValue);
				fprintf(outputFile, "\tADD #%s, %c\n",$1, c);
			  	fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);
			}
			if ( atoi($1) && atoi($3) != 0 )	// both are numeric values
			{
				char c = getRegister() + 'A';
				fprintf(outputFile, "\tMOV %c, #%s\n",c, $1);
				fprintf(outputFile, "\tADD %c, #%s\n",c, $3);
				fprintf(outputFile, "\tST $%s, %c\n\n", tempPseudoAddress,c);
			}

			$$ = strdup(tempPseudo);
			// this will assign pseudo name to $$
		}

		| expression MINUSOP expression
		{
			char tempPseudo[BUFFERLEN];	// make a new temp variable.
							// generate a new name for that.
							// generate a new address for that.
			char tempPseudoAddress[BUFFERLEN];
			strncpy ( tempPseudoAddress, generateTempAddress(), sizeof(tempPseudoAddress) );
			strncpy( tempPseudo, generateVariableName(), sizeof(tempPseudo) );
			addToSymbolTableOnlyPseudo( tempPseudo, tempPseudoAddress );
			struct symbol* tempPseudoNode = lookForPseudoName( tempPseudo );
				struct symbol* dollarOne   = lookForSymbol( $1 );
				struct symbol* dollarThree = lookForSymbol( $3 );
				if (dollarOne == NULL)
					dollarOne   = lookForPseudoName( $1 );
				if (dollarThree == NULL)
					dollarThree = lookForPseudoName( $3 );
					
			if (dollarOne != NULL && dollarThree != NULL)	// both first and second are in symbol table and are not numeric values
			{
				char c = getRegister() + 'A';
				char c_ = getRegister() + 'A';

				fprintf(outputFile, "\t MOV %c, $%s\n",c, dollarOne->varValue);		  // load $1's address
				fprintf(outputFile, "\t MOV %c, $%s\n",c_, dollarThree->varValue);		  // load $3's address
				fprintf(outputFile, "\tSUB %c, %c\n", c,c_);
				fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);		  // store to tempPseudo's address

			}	

			if (dollarOne != NULL && atoi($3) != 0 )	// first exists and second is a numeric value
			{
				char c = getRegister() + 'A';

				fprintf(outputFile, "\tMOV %c, $%s\n",c ,dollarOne->varValue);
				fprintf(outputFile, "\tSUB %c, #%s\n",c , $3);
				fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);
			}


			if ( atoi($1) != 0 && dollarThree != NULL )	// second exists and first is a numeric value
			{
				char c = getRegister() +'A';
				fprintf(outputFile, "\tMOV %c, $%s\n",c, dollarThree->varValue);
				fprintf(outputFile, "\tSUB #%s, %c\n",$1, c);
			  	fprintf(outputFile, "\tST $%s\n\n", tempPseudoAddress);
			}


			if ( atoi($1) && atoi($3) != 0 )	// both are numeric values
			{
				char c = getRegister() + 'A';
				fprintf(outputFile, "\tMOV %c, #%s\n",c, $1);
				fprintf(outputFile, "\tSUB %c, #%s\n",c, $3);
				fprintf(outputFile, "\tST $%s, %c\n\n", tempPseudoAddress,c);
			}

			$$ = strdup(tempPseudo);
			// this will assign pseudo name to $$

		}
		 | expression MULTOP expression
        	{
            char tempPseudo[BUFFERLEN]; // make a new temp variable.
                            // generate a new name for that.
                            // generate a new address for that.
            char tempPseudoAddress[BUFFERLEN];
            strncpy ( tempPseudoAddress, generateTempAddress(), sizeof(tempPseudoAddress) );
            strncpy( tempPseudo, generateVariableName(), sizeof(tempPseudo) );
            addToSymbolTableOnlyPseudo( tempPseudo, tempPseudoAddress );
            struct symbol* tempPseudoNode = lookForPseudoName( tempPseudo );

            struct symbol* dollarOne = lookForSymbol( $1 );
            struct symbol* dollarThree = lookForSymbol( $3 );

            int shiftLabelNumber = generateLabelNumber();
			 int decLabelNumber = generateLabelNumber();



            // if they are not variable names look for them in pseudoname. may introduce errors (bugs) to the program
            if (dollarOne == NULL)
                dollarOne = lookForPseudoName( $1 );
            if (dollarThree == NULL)
                dollarThree = lookForPseudoName( $3 );


		if (dollarOne != NULL && dollarThree != NULL)    // both first and second are in symbol table and are not numeric values
            {
                char c1 = getRegister() + 'A';
                char c2 = getRegister() + 'A';
                char c3 = getRegister() + 'A';
                char c4 = getRegister() + 'A';
                fprintf(outputFile, "\tMVI %c 00\n",c4);    // load accumulator to 0                
                fprintf(outputFile, "\tMVI A 00\n");    // load accumulator to 0
                fprintf(outputFile, "\tMOV %c $%s\n",c2, dollarOne->varValue);    // load from $1's address
                fprintf(outputFile, "\tMOV %c $%s\n",c3, dollarThree->varValue);    // load from $1's address
                fprintf(outputFile, "\tLOOP:\n\tADD %c\n", c2);  // load from $3's address
                fprintf(outputFile, "\tJNC NEXT\n");                     
                fprintf(outputFile, "\tINR %c\n",c4);                    
                fprintf(outputFile, "\tNEXT:\n\tDCR %c\n",c3);           
                fprintf(outputFile, "\tJNZ LOOP\n");                           
                // write to file

            }   

            if (dollarOne != NULL && atoi($3) != 0 )    // first exists and second is a numeric value
            {
                char c1 = getRegister() + 'A';
                char c2 = getRegister() + 'A';
                char c3 = getRegister() + 'A';
                char c4 = getRegister() + 'A';
                fprintf(outputFile, "\tMVI %c 00\n",c4);    // load accumulator to 0                
                fprintf(outputFile, "\tMVI A 00\n");    // load accumulator to 0
                fprintf(outputFile, "\tMOV %c $%s\n",c2, dollarOne->varValue);    // load from $1's address
                fprintf(outputFile, "\tMOV %c #%s\n",c3, $3);    // load from $1's address
                fprintf(outputFile, "\tLOOP:\n\tADD %c\n", c2);  // load from $3's address
                fprintf(outputFile, "\tJNC NEXT\n");                     
                fprintf(outputFile, "\tINR %c\n",c4);                    
                fprintf(outputFile, "\tNEXT:\n\tDCR %c\n",c3);           
                fprintf(outputFile, "\tJNZ LOOP\n");                           
                // write to file
            }

            if ( atoi($1) != 0 && dollarThree != NULL ) // second exists and first is a numeric value
            {
                char c1 = getRegister() + 'A';
                char c2 = getRegister() + 'A';
                char c3 = getRegister() + 'A';
                char c4 = getRegister() + 'A';
                fprintf(outputFile, "\tMVI %c 00\n",c4);    // load accumulator to 0                
                fprintf(outputFile, "\tMVI A 00\n");    // load accumulator to 0
                fprintf(outputFile, "\tMOV %c #%s\n",c2, $1);    // load from $1's address
                fprintf(outputFile, "\tMOV %c $%s\n",c3, dollarThree->varValue);    // load from $1's address
                fprintf(outputFile, "\tLOOP:\n\tADD %c\n", c2);  // load from $3's address
                fprintf(outputFile, "\tJNC NEXT\n");                     
                fprintf(outputFile, "\tINR %c\n",c4);                    
                fprintf(outputFile, "\tNEXT:\n\tDCR %c\n",c3);           
                fprintf(outputFile, "\tJNZ LOOP\n");                           
                // write to file            
			}
            if ( atoi($1) && atoi($3) != 0 )    // both are numeric values
            {
                char c1 = getRegister() + 'A';
                char c2 = getRegister() + 'A';
                char c3 = getRegister() + 'A';
                char c4 = getRegister() + 'A';
                fprintf(outputFile, "\tMVI %c 00\n",c4);    // load accumulator to 0                
                fprintf(outputFile, "\tMVI A 00\n");    // load accumulator to 0
                fprintf(outputFile, "\tMOV %c #%s\n",c2, $1);    // load from $1's address
                fprintf(outputFile, "\tMOV %c #%s\n",c3, $3);    // load from $1's address
                fprintf(outputFile, "\tLOOP:\n\tADD %c\n", c2);  // load from $3's address
                fprintf(outputFile, "\tJNC NEXT\n");                     
                fprintf(outputFile, "\tINR %c\n",c4);                    
                fprintf(outputFile, "\tNEXT:\n\tDCR %c\n",c3);           
                fprintf(outputFile, "\tJNZ LOOP\n");                           
                // write to file            }
			}
            $$ = strdup(tempPseudo);
            // this will assign pseudo name to $$


        }
		| OPENPAR expression CLOSEPAR 
		{
			$$ = $2;
		}

		| expression equality expression
		{
			struct symbol* dollarOne   = lookForSymbol( $1 );
			struct symbol* dollarThree = lookForSymbol( $3 );
			// if they are not variable names look for them in pseudoname. may introduce errors (bugs) to the program
			if (dollarOne == NULL)
				dollarOne   = lookForPseudoName( $1 );
			if (dollarThree == NULL)
				dollarThree = lookForPseudoName( $3 );

			if (dollarOne != NULL && dollarThree != NULL)	// both first and second are in symbol table and are not numeric values
			{
				char c = getRegister() +'A';
				char c_ = getRegister() +'A';
				fprintf(outputFile, "\tMOV %c, $%s\n",c, dollarOne->varValue);		  // load $1's address
				fprintf(outputFile, "\tMOV %c, $%s\n",c, dollarThree->varValue);		  // load $3's address				
				fprintf(outputFile, "\tCMP %c, %c\n",c, c_);		// add $3's address
				// write to file

			}	

			if (dollarOne != NULL && atoi($3) != 0 )	// first exists and second is a numeric value
			{

				char c = getRegister() +'A';
				fprintf(outputFile, "\tMOV %c, $%s\n", c, dollarOne->varValue);
				fprintf(outputFile, "\tCMP %c, #%s\n",c, $3);
			
			}

			if ( atoi($1) != 0 && dollarThree != NULL )	// second exists and first is a numeric value
			{
				char c = getRegister() +'A';
				fprintf(outputFile, "\tMOV %c, $%s\n",c, dollarThree->varValue);
				fprintf(outputFile, "\tCMP #%s, %c\n",$1,c);

			}

			if ( atoi($1) && atoi($3) != 0 )	// both are numeric values
			{
				char c = getRegister() + 'A';
				fprintf(outputFile, "\tMOV %c, #%s\n",c, $1);
				fprintf(outputFile, "\tCMP %c, #%s\n",c, $3);
			}
			$$=$2;	
		};

equality : EQUAL
		{
			$$ = "eequal";
		}

		| NOTEQUAL
		{
			$$ = "enotequal";

		}

		| GREATERTHAN
		{
			$$ = "egreaterthan";
		}

		| LESSTHAN
		{
			$$ = "elessthan";
		}

		| LESSEQUAL
		{
			$$ = "elessequal";
			
		}

		| GREATEQUAL
		{
			$$ = "egreatequal";
		};

function_decl : INT IDENTIFIER OPENPAR CLOSEPAR OPENCURL program CLOSECURL;

return	: RETURN expression SEMICOLON;

%%

void yyerror(char *s) {
	fprintf(stderr, "%s in line No. - %d\n", s,linenum);
}
int yywrap(){
	return 1;
}
int main(int argc, char *argv[])
{
	verbose = 0;
	if (argv[2] != NULL)	// decide if this program is verbose (run with -v as its 2nd argument)
		if ( !strncmp(argv[2], "-v", 2) )
			verbose = 1;
	initSymbolTable();

	fclose(fopen("output.asm", "w"));	// reset output file


	outputFile = fopen("output.asm", "a");	// open a file pointer in append mode to 
						// write assembly code

	if (outputFile == NULL)
	{
		fprintf(stderr, "Can't open output file!\n");
		exit(1);
	}

	initNameGenerator();	// initialize variable name generator 
	initAddressGenerator();	// initialize address generator 
	initNumberGenerator();	// initialize number generator for label numbers. (to make labels unique)
	/* Call the lexer, then quit. */
	yyin=fopen(argv[1],"r");
	yyparse();
	fclose(yyin);
        fprintf(outputFile, "return\t.end\n");
	if (verbose)
		printSymbolTable();
	fclose(outputFile);	// close output file

	freeLinkedList();	// free the linked list because i used malloc before
	return 0;
}
