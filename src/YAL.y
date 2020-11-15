%{

#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;

void yyerror(const char* s);
%}

%token INIT
%token BLOCK_B
%token BLOCK_E

//Types
%token INTEGER
%token FLOAT
%token CHAR
%token STRING

//IO
%token IN
%token OUT

//Relational
%token EQUAL
%token DIF
%token GREAT
%token LESS
%token GE
%token LE

//Arithmetich
%token SUM
%token SUB
%token MULT
%token DIV
%token POW
%token MOD

//Logical
%token AND
%token OR
%token NOT
%token XOR

//Structures
%token FOR
%token WHILE
%token IF
%token ELSE

%%
block: BLOCK_B BLOCK_E {fprintf(stderr, "%s\n", "Block");};
%%

void main(int argc, char **argv)
{
  yyparse();
}

void yyerror(const char *s)
{
  fprintf(stderr, "error: %s\n", s);
}