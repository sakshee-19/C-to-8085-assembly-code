%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
int linenum;
%}

%%
"int"				return INT;
"if"				return IF;
"else"				return ELSE;
"return"			return RETURN;
[0-9]+				{yylval.number = atoi(yytext); return INTEGER;}
[_a-zA-Z][_a-zA-Z0-9]*		{yylval.string = strdup(yytext); return IDENTIFIER;}
"<"                             return LESSTHAN; 
">"                             return GREATERTHAN; 
"<="                            return LESSEQUAL; 
">="                            return GREATEQUAL; 
"."                             return DOT; 
","                             return COMMA; 
"=="                            return EQUAL; 
"!="                            return NOTEQUAL; 
"-"				return MINUSOP;
"+"				return PLUSOP;
"("				return OPENPAR;
")"				return CLOSEPAR;
"{"				return OPENCURL;
"}"				return CLOSECURL;
"/"				{;} // ignore DIVIDEOP;
"*"				return MULTOP;
"="				return ASSIGNOP;
";"				return SEMICOLON;
"\n"				linenum++;	
"#".*\n				{;}	/*ignore macros*/
[ \t]+				{;}	/*ignore whitespaces*/
"/*".*"*/"|"//".*\n		{;}	/*ignore comments*/	
.				/*unexpected character*/
%%
