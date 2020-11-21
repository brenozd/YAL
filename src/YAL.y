%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "../src/interpretador/nodes.h"
#include "../src/interpretador/interpreter.c"

#define DEBUG 0

extern int yylex();
extern int yyparse();

extern FILE* yyin;
FILE* yytokens;
FILE* yycmd; 

/* Prototypes */
void yyerror(const char* s);
%}

%union {
    char* str_val;
    int   int_val;
    float float_val;

    char* id_name;
    struct _node *nPtr;            
};

//Program Entry Point
%start program

//Symbols
%token T_BLOCK_B T_BLOCK_E
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
          T_INIT  entry_point  
          ;

entry_point:
          entry_point statement_list                        { execNode($2); }//freeNode($2);          }
          | /* NULL */
          ;

block: 
          T_BLOCK_B statement_list T_BLOCK_E          { $$ = $2;                                }
          ;

statement_list:
            statements                                { $$ = $1;                                }
          | statement_list statements                 { $$ = stmt(T_EOS, 2, $1, $2);            }
          ;

statements:
            block                                     { $$ = $1;                                }
          | declare                                   { $$ = $1;                                }
          | commands                                  { $$ = $1;                                }
          ;

commands:
            if_stm              
          | while_stm
          | in_stm                    
          | out_stm                   
          | outl_stm                  
          ;

declare: 
            T_LET T_ID T_ASSGN expressions T_EOS      { id($2); $$ = stmt(T_ASSGN, 2, $2, $4);  }
          | T_ID T_ASSGN expressions T_EOS            { $$ = stmt(T_ASSGN, 2, $1, $3);          }
          ;

expressions:
            type                                                                                 
          | arithmetic                                         
          | relational                               
          | logical                                                                           
          ;

arithmetic:
            expressions T_SUM expressions             { $$ = stmt(T_SUM, 2, $1,  $3);           }
          | expressions T_SUB expressions             { $$ = stmt(T_SUB, 2, $1,  $3);           }
          | expressions T_MULT expressions            { $$ = stmt(T_MULT, 2, $1,  $3);          }
          | expressions T_DIV expressions             { $$ = stmt(T_DIV, 2, $1,  $3);           }
          | expressions T_MOD expressions             { $$ = stmt(T_MOD, 2, $1,  $3);           }
          | T_SUB expressions                         { $$ = stmt(T_NEGATIVE, 1, $2);           }
          | T_RP expressions T_LP                     { $$ = $2;                                }                        
          ;

relational:
            expressions T_EQUAL expressions           { $$ = stmt(T_EQUAL, 2, $1,  $3);         }
          | expressions T_DIF expressions             { $$ = stmt(T_DIF, 2, $1,  $3);           }
          | expressions T_GREAT expressions           { $$ = stmt(T_GREAT, 2, $1,  $3);         }
          | expressions T_LESS expressions            { $$ = stmt(T_LESS, 2, $1,  $3);          }
          | expressions T_GE expressions              { $$ = stmt(T_GE, 2, $1,  $3);            }
          | expressions T_LE expressions              { $$ = stmt(T_LE, 2, $1,  $3);            }
          ;

logical:
            expressions T_AND expressions             { $$ = stmt(T_AND, 2, $1,  $3);           }
          | expressions T_OR expressions              { $$ = stmt(T_OR, 2, $1,  $3);            }
          | expressions T_NOT expressions             { $$ = stmt(T_NOT, 2, $1, $3);            }
          ;

if_stm:
          T_IF T_RP relational T_LP block else_stm   { id($3); $$ = stmt(T_IF, 2, $3, $5);      }
          ;

else_stm:
          T_ELSE  block                              
          ;

while_stm:
          T_WHILE T_RP relational T_LP  block         { $$ = stmt(T_WHILE, 2, $3, $5);          }
          ;

in_stm:
          T_IN T_ID T_EOS                             { $$ = stmt(T_IN, 1, $2);                 }
          ;

out_stm:
            T_OUT expressions T_EOS                   { $$ = stmt(T_OUT, 1, $2);                }                     
          ;

outl_stm:
            T_OUTL expressions T_EOS                  { $$ = stmt(T_OUTL, 1, $2);               }                     
          ;

type:
            T_ID                                      { $$ = getSymbol($1);                     }
          | T_INTEGER                                 { $$ = constant($1);                      }
          | T_FLOAT                                   { $$ = constant($1);                      }
          | T_CHAR                                    { $$ = constant($1);                      }
          | T_STRING                                  { $$ = constant($1);                      }
          | T_BOOLEAN                                 { $$ = constant($1);                      }
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

  
  if(yyparse())
  {
		printf("\nParsing failed\n");
	}

	fclose(yyin);
  fclose(yytokens);
  fclose(yycmd);
  exit(0);
}

void yyerror(const char *s)
{
  fprintf(stderr, "ERROR: %s\n", s);
  exit(-1);
}