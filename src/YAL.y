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
%token T_QUOTE T_LP T_RP
%token T_EOL T_EOS

//Blocks
%token T_INIT
%token T_BLOCK_B
%token T_BLOCK_E

//Types
%token T_ID
%right T_ASSGN
%token T_INTEGER T_FLOAT T_CHAR T_STRING T_BOOLEAN

//IO
%left T_IN T_OUT

//Relational
%left T_EQUAL T_DIF T_GREAT T_LESS T_GE T_LE

//Arithmetich
%left T_SUM T_SUB  
%left T_MULT T_DIV
%left T_POW T_MOD

//Logical
%left T_AND T_OR T_NOT T_XOR

//Structures
%nonassoc T_WHILE T_IF T_ELSE

%%

program: 
          T_INIT block
          ;

block: 
          T_BLOCK_B statement_list T_BLOCK_E
          ;

statement_list: 
            statement_list statements  
          | statement_list block
          | statements
          | /* empty */
          ;

statements:  
            declare
          | expressions
          | commands
          | T_EOL
          ;

commands:
            if_stm
          | while_stm
          | in_stm
          | out_stm
          ;

declare: 
          T_ID T_EOS
          | T_ID T_ASSGN expressions T_EOS
          ;

expressions:
            expressions T_EQUAL expressions
          | expressions T_DIF expressions
          | expressions T_GREAT expressions
          | expressions T_LESS expressions
          | expressions T_GE expressions
          | expressions T_LE expressions
          | expressions T_SUM expressions
          | expressions T_SUB expressions
          | expressions T_MULT expressions
          | expressions T_DIV expressions
          | expressions T_POW expressions
          | expressions T_MOD expressions
          | expressions T_AND expressions
          | expressions T_OR expressions
          | expressions T_NOT expressions
          | expressions T_XOR expressions
          | T_SUB expressions
          | T_RP expressions T_LP
          | type
          ;



if_stm:
          T_IF T_RP expressions T_LP block else_stm
          ;

else_stm:
          T_ELSE block
          | /* empty */
          ;

while_stm:
          T_WHILE T_RP expressions T_LP block
          ;

in_stm:
          T_IN T_ID type T_EOS
          ;

out_stm:
            T_OUT T_ID
          | T_OUT T_ID T_EOS
          | T_OUT type
          | T_OUT type T_EOS
          ;

type:
            T_ID
          | T_INTEGER
          | T_FLOAT
          | T_CHAR
          | T_STRING
          | T_BOOLEAN
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