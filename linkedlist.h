#define VARLEN 32

#include <stdio.h>      // printf
#include <stdlib.h>     // malloc
#include <string.h>     // strncpy, strcmp

// a structure for the symbol table
struct symbol
{
	char varName[VARLEN];
	char varValue[VARLEN];		// address for its value
    struct symbol* next;
	int definedWithoutKnowing;	// this flag is used for determining if defining it before knowing 
					//if this had been defined before was a good choice 
	char pseudoName[VARLEN];	// pseudoName is fake variable name associated with that symbol
};

// root of symbol table
struct symbol* symbolTable;

// initializes symbol table
void initSymbolTable();

// adds a new variable and its value to the symbol table. 
// since following two add functions are present;
// this function is basically obsolete
void addToSymbolTable( char newVariable[], char value[] );

// add only pseudo because some pseudos dont have an associated value
void addToSymbolTableOnlyPseudo( char newPseudo[], char value[] );

// prints whole symbol table to the console
void printSymbolTable();

// looks for a variable name and returns the pointer for that
struct symbol* lookForSymbol ( char wantedVariable[] );

// looks for a pseudo variable name and returns the pointer for that
struct symbol* lookForPseudoName ( char wantedPseudoName[] );

// frees whole linked list
void freeLinkedList();
