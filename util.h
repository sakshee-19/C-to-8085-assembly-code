#include <stdio.h>      // printf
#include <string.h>     // strncpy, strcmp

int nameGenCounter;
char name[16];
char mainAddress[5];
char tempAddress[5];

int mainAddressCounter;
int tempAddressCounter;

int labelCounter;

// initializes the name generator
void initNameGenerator();

// generates a variable name sequentially
char* generateVariableName();

void initAddressGenerator();

// generates an address for temp(intermediate) variables
char* generateTempAddress();

// generates an address for variables
char* generateMainAddress();

// generates sequential numbers
void initNumberGenerator();
// returns generated numbers as integer
int generateLabelNumber();
