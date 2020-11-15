%{

#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;

void yyerror(const char* s);
%}

//Program Entry Point
%start program

//Symbols
%token T_QUOTE
%token T_EOL T_EOS

//Blocks
%token T_INIT
%token T_BLOCK_B
%token T_BLOCK_E

//Types
%token T_ID
%right T_ASSGN
%left T_INTEGER T_FLOAT T_CHAR T_STRING

//IO
%left T_IN T_OUT

//Relational
%left T_EQUAL T_DIF T_GREAT T_LESS T_GE T_LE

//Arithmetich
%left T_SUM T_SUB T_MULT T_DIV T_POW T_MOD

//Logical
%left T_AND T_OR T_NOT T_XOR

//Structures
%token T_FOR T_WHILE T_IF T_ELSE

%%
program: 
            T_INIT T_BLOCK_B statement_list T_BLOCK_E
            ;

statement_list: 
            statement_list statements  
          | statements
          ;

statements:  
                declare
                | T_EOL
                ;

declare: 
          T_ID T_EOS
          | T_ID T_ASSGN type T_EOS
          ;

type:
          T_INTEGER
          | T_FLOAT
          | T_CHAR
          | T_STRING
          ;
%%

void main(int argc, char **argv)
{
  #ifdef YYDEBUG
  yydebug = 1;
  #endif

  yyin = fopen(argv[1], "r");
	
   if(!yyparse())
		printf("\nParsing complete\n");
	else
	{
		printf("\nParsing failed\n");
		exit(0);
	}
	fclose(yyin);
}

void yyerror(const char *s)
{
  fprintf(stderr, "ERROR: %s\n", s);
}