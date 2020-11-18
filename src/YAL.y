%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "../src/nodes.h"
#include "../src/interpreter.c"

#define DEBUG 0

extern int yylex();
extern int yyparse();
extern FILE* yyin;
FILE* yytokens;
FILE* yycmd;
int sym[26]; 
extern struct idNode *id_table;

/* Prototypes */
void yyerror(const char* s);
%}

%union {
    char* str_val;
    int   int_val;
    float float_val;

    char* id_name;
    struct nodeType *nPtr;            
};

//Program Entry Point
%start program

//Symbols
%token T_QUOTE T_LP T_RP
%token T_EOL T_EOS

//Blocks
%token T_INIT

//Types
%token <id_name> T_ID
%left T_LET
%right T_ASSGN
%token <int_val> T_INTEGER T_BOOLEAN
%token <float_val> T_FLOAT 
%token <str_val> T_CHAR T_STRING 

//IO
%right T_IN T_OUT T_OUTL

//Relational
%left T_EQUAL T_DIF T_GREAT T_LESS T_GE T_LE

//Arithmetich
%right T_INCREMENT
%left T_NEGATIVE
%left T_SUM T_SUB  
%left T_MULT T_DIV
%right T_MOD

//Logical
%left T_AND T_OR T_NOT

//Structures
%nonassoc T_WHILE T_IF T_ELSE

%type <nPtr> statements statement_list expressions commands block 
%type <nPtr> out_stm outl_stm in_stm while_stm if_stm else_stm 
%type <nPtr> type declare arithmetic relational logical
%%

program: 
          T_INIT  block  
          ;

block: 
            block statement_list { execNode($2); freeNode($2); }
          | /* NULL */
          ;

statement_list:
            statement_list statements  { $$ = stmt(T_EOS, 2, $1, $2); }
          | statements                 { $$ = $1; }
          
          ;

statements:  
            declare                   { $$ = $1; }
          | expressions               { $$ = $1; }
          | commands                  { $$ = $1; }
          ;

commands:
            if_stm              
          | while_stm
          | in_stm                    { $$ = $1;}
          | out_stm                   { $$ = $1;}
          | outl_stm                  { $$ = $1;}
          ;

declare: 
            T_LET T_ID T_ASSGN expressions T_EOS    { fprintf(yycmd, "CREATE %s AND ASSIGN VALUE %d\n", $2, $4); 
                                                      $$ = stmt(T_ASSGN, 2, $2, $4); }
          | T_ID T_ASSGN expressions T_EOS          { fprintf(yycmd, "ASSIGN TO %s VALUE %d\n", $1, $3); 
                                                      $$ = stmt(T_ASSGN, 2, $1, $3);}
          ;

expressions:
            type                                                
          | arithmetic                                          
          | relational                                          
          | logical                                             
          | expressions type                                    
          | expressions arithmetic                              
          | expressions relational                              
          | expressions logical                                
          ;

arithmetic:
            expressions T_SUM expressions           { fprintf(yycmd, "SUMMING %d AND %d\n", $1, $3);
                                                      $$ = stmt(T_SUM, 2, $1,  $3);}
          | expressions T_SUB expressions           { fprintf(yycmd, "SUBTRACTING %d AND %d\n", $1, $3);
                                                      $$ = stmt(T_SUB, 2, $1,  $3);}
          | expressions T_MULT expressions          { fprintf(yycmd, "MULTIPLYING %d AND %d\n", $1, $3);
                                                      $$ = stmt(T_MULT, 2, $1,  $3);}
          | expressions T_DIV expressions           { fprintf(yycmd, "DIVIDING %d AND %d\n", $1, $3);
                                                      $$ = stmt(T_DIV, 2, $1,  $3);}
          | expressions T_MOD expressions           { fprintf(yycmd, "MOD %d FROM %d\n", $1, $3);
                                                      $$ = stmt(T_MOD, 2, $1,  $3);}
          | T_SUB expressions                       { fprintf(yycmd, "NEGATIVE NUMBER %d\n", $2);
                                                      $$ = stmt(T_NEGATIVE, 1, $2);}
          | T_RP expressions T_LP                   { $$ = $2;                     }                                                            
          ;

relational:
            expressions T_EQUAL expressions         { fprintf(yycmd, "COMPARING %d == %d\n", $1, $3);
                                                      $$ = stmt(T_EQUAL, 2, $1,  $3);}
          | expressions T_DIF expressions           { fprintf(yycmd, "COMPARING %d != %d\n", $1, $3);
                                                      $$ = stmt(T_DIF, 2, $1,  $3);}
          | expressions T_GREAT expressions         { fprintf(yycmd, "COMPARING %d > %d\n", $1, $3);
                                                      $$ = stmt(T_GREAT, 2, $1,  $3);}
          | expressions T_LESS expressions          { fprintf(yycmd, "COMPARING %d < %d\n", $1, $3);
                                                      $$ = stmt(T_LESS, 2, $1,  $3);}
          | expressions T_GE expressions            { fprintf(yycmd, "COMPARING %d >= %d\n", $1, $3);
                                                      $$ = stmt(T_GE, 2, $1,  $3);}
          | expressions T_LE expressions            { fprintf(yycmd, "COMPARING %d <= %d\n", $1, $3);
                                                      $$ = stmt(T_LE, 2, $1,  $3);}
          ;

logical:
            expressions T_AND expressions           { fprintf(yycmd, "LOGICAL AND BETWEEN %d, %d\n", $1, $3);
                                                      $$ = stmt(T_AND, 2, $1,  $3);}
          | expressions T_OR expressions            { fprintf(yycmd, "LOGICAL OR BETWEEN %d, %d\n", $1, $3);
                                                      $$ = stmt(T_OR, 2, $1,  $3);}
          | expressions T_NOT expressions           { fprintf(yycmd, "LOGICAL NOT %d\n", $1, $3);
                                                      $$ = stmt(T_NOT, 2, $1, $3);}

if_stm:
          T_IF T_RP relational T_LP  block else_stm { fprintf(yycmd, "IF STATEMENT\n");
                                                      $$ = stmt(T_IF, 2, $3, $5); }
          ;

else_stm:
          T_ELSE  block                              { fprintf(yycmd, "ELSE STATEMENT\n"); }
          | /* NULL */
          ;

while_stm:
          T_WHILE T_RP relational T_LP  block     { fprintf(yycmd, "WHILE STATEMENT \n");
                                                  $$ = stmt(T_WHILE, 2, $3, $5); }
          ;

in_stm:
          T_IN T_ID type T_EOS  { fprintf(yycmd, "ASSIGNED VALUE %d TO VARIABLE %s WITH OPERATOR IN\n", $3, $2);
                                  $$ = stmt(T_IN, 2, $2, $3);}
          ;

out_stm:
            T_OUT expressions T_EOS { fprintf(yycmd, "PRINTED VALUE %d\n", $2);
                                      $$ = stmt(T_OUT, 1, $2); }                     
          ;

outl_stm:
            T_OUTL expressions T_EOS { fprintf(yycmd, "PRINTED VALUE WITH NEW LINE %d\n ", $2);
                                       $$ = stmt(T_OUTL, 1, $2); }                     
          ;

type:
            T_ID      { $$ = id($1); }
          | T_INTEGER { $$ = constant($1); }
          | T_FLOAT   { $$ = constant($1); }
          | T_CHAR    { $$ = constant($1); }
          | T_STRING  { $$ = constant($1); }
          | T_BOOLEAN { $$ = constant($1); }
          ;
%%

/* Main And YACC */
void main(int argc, char **argv)
{
  #ifdef YYDEBUG
  yydebug = DEBUG;
  #endif

  yyin = fopen(argv[1], "r");
	yytokens = fopen(argv[2], "w+");
  yycmd = fopen(argv[3], "w+");

  if(!yyparse())
  {
		printf("\nParsing complete\n");
  }
	else
	{
		printf("\nParsing failed\n");
		exit(0);
	}
	fclose(yyin);
  fclose(yytokens);
  fclose(yycmd);
  
}

void yyerror(const char *s)
{
  fprintf(stderr, "ERROR: %s\n", s);
  exit(-1);
}