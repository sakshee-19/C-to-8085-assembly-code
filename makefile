all: yacc lex
	gcc lex.yy.c y.tab.c linkedlist.c util.c -o project

# -d flag is for creating "y.tab.h" file. this file is used by lex
yacc: project.y
	yacc -d project.y

# Command to run lex file
lex: project.l
	lex project.l
