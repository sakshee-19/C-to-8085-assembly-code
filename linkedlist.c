#include "linkedlist.h" // custom linkedlist

void initSymbolTable()
{
        symbolTable = (struct symbol*) malloc ( sizeof(struct symbol) );
        symbolTable->next = NULL;
}

// value is the address of this variable
void addToSymbolTable( char newVariable[], char value[] )
{
        struct symbol* conductor = symbolTable;
        //printf("Adding to symbol table\n");
        if( conductor != NULL )
        {
                while ( conductor->next != NULL )
                {
                        /*check existance here and give error if already defined*/
                        conductor = conductor -> next;
                }
        }
        conductor->next = malloc (sizeof(struct symbol));
	conductor->next->definedWithoutKnowing = 0;
        strncpy ( conductor->next->varName, newVariable, sizeof(conductor->next->varName) );
	strncpy ( conductor->next->varValue, value, sizeof(conductor->next->varValue) );
	// conductor->next->varValue = value;
        conductor->next->next = NULL;
}

void printSymbolTable()
{
	struct symbol* conductor = symbolTable;

	if(conductor != NULL)	// need to move away from the root because the root doesn't have a symbol 
	{
		conductor = conductor -> next;	
	}

        while ( conductor != NULL )
        {
		//printf("Symbol: %s\t,\tValue: %d\n", conductor -> varName, conductor -> varValue );                
		printf("%s %s -> %s\n", conductor->varName, conductor->pseudoName, conductor->varValue);                
		conductor = conductor -> next;
        }
}

struct symbol* lookForSymbol ( char wantedVariable[] )	// return found symbol or null
{
        struct symbol* conductor = symbolTable;

        if(conductor != NULL)   // need to move away from the root because the root doesn't have a symbol 
        {
                conductor = conductor -> next;
        }

        while ( conductor != NULL )
        {
		if( !strcmp(wantedVariable, conductor->varName) ) // if they are equal
		{
			return conductor;
		}
                conductor = conductor -> next;
        }
	return NULL;	// couldn't find variable
}

void freeLinkedList ()
{
        struct symbol* conductor = symbolTable;
        struct symbol* prev = NULL;

        if(conductor != NULL)   // need to move away from the root because the root doesn't have a symbol 
        {
                conductor = conductor -> next;
        }

        while ( conductor != NULL )
        {
		prev = conductor;
                conductor = conductor -> next;
		free(prev);
        }
}

// BELOW THIS LINE IS MOSTLY COPIED FROM ABOVE CODE
// BELOW THIS LINE IS MOSTLY COPIED FROM ABOVE CODE

void addToSymbolTableOnlyPseudo( char newPseudo[], char value[] )
{
        struct symbol* conductor = symbolTable;
        //printf("Adding to symbol table\n");

        if( conductor != NULL )
        {
                while ( conductor->next != NULL )
                {
                        /*check existance here and give error if already defined*/
                        conductor = conductor -> next;
                }
        }

        conductor->next = malloc (sizeof(struct symbol));
        strncpy ( conductor->next->pseudoName, newPseudo, sizeof(conductor->next->pseudoName) );
	strncpy ( conductor->next->varValue, value, sizeof(conductor->next->varValue) );
	conductor->next->definedWithoutKnowing = 0;
       // conductor->next->varValue = value;

        conductor->next->next = NULL;
}

// looks for a pseudo variable name and returns the pointer for that
struct symbol* lookForPseudoName ( char wantedPseudoName[] )
{
        struct symbol* conductor = symbolTable;
        if(conductor != NULL)   // need to move away from the root because the root doesn't have a symbol 
        {
                conductor = conductor -> next;
        }

        while ( conductor != NULL )
        {
                //printf("Looked at Symbol: %s\n", conductor -> varName );
                if( !strcmp(wantedPseudoName, conductor->pseudoName) ) // if they are equal
                {
                        return conductor;
                }
                conductor = conductor -> next;
        }
        return NULL;    // couldn't find variable
}
