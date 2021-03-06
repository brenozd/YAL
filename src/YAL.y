%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "../src/interpretador/nodes.h"
#include "../src/interpretador/interpreter.c"

#define DEBUG 0
#define YYERROR_VERBOSE 1

extern int yylex();
extern int yyparse();
extern int yylineno;

extern int precision;
extern int round_type;


extern FILE* yyin;
FILE* yytokens;
FILE* yycmd; 

int d_type = 0;

/* Prototypes */
void yyerror(const char* s);
%}

%union {
    char*   str_val;
    double  num_val;

    char* id_name;
    struct _node *nPtr;            
};

//Program Entry Point
%start program

//Def
%token T_DEF
%token D_PRECISION D_ROUND_TYPE

//Symbols
%token T_BLOCK_B T_BLOCK_E
%token T_QUOTE T_LP T_RP
%token T_EOL T_EOS

//Blocks
%token T_INIT

//Types
%token <id_name> T_ID
%token <num_val> T_NUMBER 
%token <num_val> T_PI
%token <str_val> T_STRING 
%left T_LET
%right T_ASSGN

//IO
%right T_IN T_OUT T_OUTL T_SPRT

//Relational
%left T_EQUAL T_DIF T_GREAT T_LESS T_GE T_LE

//Arithmetich
%left T_SIN T_COS T_TAN
%right T_POW T_SQRT
%left T_NEGATIVE
%left T_SUM T_SUB  
%left T_MULT T_DIV
%right T_MOD

%left T_SUME T_SUBE  
%left T_MULTE T_DIVE

//Logical
%left T_AND T_OR T_NOT

//Structures
%nonassoc T_WHILE T_IF T_ELSE

%type <nPtr> string number declare 
%type <nPtr> assign arithmetic relational logical
%type <nPtr> statements statement_list expressions commands block 
%type <nPtr> out_stm outl_stm in_stm while_stm if_stm else_stm 

%%

program: 
          definitions_list T_INIT entry_point  
          ;

definitions_list:
            definitions                                 
          | definitions_list definitions
          | /* NULL */
          ;

definitions:
            T_DEF D_PRECISION T_NUMBER T_EOS          { precision = trunc(fmod($3, 25));
                                                        fprintf(yycmd, "define precision for number as [%d]\n", precision); }
          | T_DEF D_ROUND_TYPE T_NUMBER T_EOS         { round_type = trunc(fmod($3, 3));
                                                        fprintf(yycmd, "define round type to [%d]\n", round_type); }
          ;

entry_point:
          entry_point statement_list                  { execNode($2); freeNode($2);             }
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
          | assign                                    { $$ = $1;                                }
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
            T_LET T_ID T_ASSGN expressions T_EOS      { id($2, d_type); $$ = stmt(T_ASSGN, 2, $2, $4);}
          | T_LET T_ID T_ASSGN string T_EOS           { id($2, d_type); $$ = stmt(T_ASSGN, 2, $2, $4);}
          | T_LET T_ID T_EOS                          { $$ = id($2, 0);                               }
          ;

assign:     
            T_ID T_ASSGN string T_EOS                 { $$ = stmt(T_ASSGN, 2, $1, $3);          }
          | T_ID T_ASSGN expressions T_EOS            { $$ = stmt(T_ASSGN, 2, $1, $3);          }
          | T_ID T_SUME expressions T_EOS             { $$ = stmt(T_SUME, 2, $1, $3);           }
          | T_ID T_SUBE expressions T_EOS             { $$ = stmt(T_SUBE, 2, $1, $3);           }
          | T_ID T_MULTE expressions T_EOS            { $$ = stmt(T_MULTE, 2, $1, $3);          }
          | T_ID T_DIVE expressions T_EOS             { $$ = stmt(T_DIVE, 2, $1, $3);           }
          ;

expressions:
            number                                    { $$ = $1;                                }
          | T_ID                                      { node *n = getSymbol($1);                
                                                        if(n == NULL || n->id.type == d_STRING) 
                                                          yyerror("String values cannot be used in expressions");
                                                        $$ = n;                                 }
          | string                                    { yyerror("String values cannot be used in expressions"); }  
          | arithmetic                                         
          | relational                               
          | logical
          | T_PI                                      { dataValue _data;
                                                        d_type = 0;
                                                        _data.num = M_PI; 
                                                        $$ = constant(_data, d_type);           }            
          ;

arithmetic:
            expressions T_SUM expressions             { $$ = stmt(T_SUM, 2, $1,  $3);           }
          | expressions T_SUB expressions             { $$ = stmt(T_SUB, 2, $1,  $3);           }
          | expressions T_MULT expressions            { $$ = stmt(T_MULT, 2, $1,  $3);          }
          | expressions T_DIV expressions             { $$ = stmt(T_DIV, 2, $1,  $3);           }
          | expressions T_MOD expressions             { $$ = stmt(T_MOD, 2, $1,  $3);           }
          | expressions T_POW expressions             { $$ = stmt(T_POW, 2, $1,  $3);           }
          | T_SQRT  T_RP expressions T_LP             { $$ = stmt(T_SQRT, 1, $3);               }
          | T_SIN   T_RP expressions T_LP             { $$ = stmt(T_SIN, 1, $3);                }
          | T_COS   T_RP expressions T_LP             { $$ = stmt(T_COS, 1, $3);                }
          | T_TAN   T_RP expressions T_LP             { $$ = stmt(T_TAN, 1, $3);                }
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
          | T_NOT expressions                         { $$ = stmt(T_NOT, 1, $2);                }
          ;

if_stm:
            T_IF T_RP expressions T_LP block else_stm  { $$ = stmt(T_IF, 3, $3, $5, $6);        }
          ;

else_stm:
            T_ELSE  block                             { $$ = $2;                                }
          | /* empty */                               { $$ = stmt(T_EOS, 2, NULL, NULL);        }         
          ;

while_stm:
            T_WHILE T_RP relational T_LP  block       { $$ = stmt(T_WHILE, 2, $3, $5);          }
          ;

in_stm:
            T_IN T_ID T_EOS                           { $$ = stmt(T_IN, 1, $2);                 }
          ;

out_stm:
            T_OUT T_ID T_EOS                          { $$ = stmt(T_OUT, 1, getSymbol($2));     }
          | T_OUT string T_EOS                        { $$ = stmt(T_OUT, 1, $2);                } 
          | T_OUT expressions T_EOS                   { $$ = stmt(T_OUT, 1, $2);                }   
          ;

outl_stm:
            T_OUTL T_ID T_EOS                         { $$ = stmt(T_OUTL, 1, getSymbol($2));    }
          | T_OUTL string T_EOS                       { $$ = stmt(T_OUTL, 1, $2);               } 
          | T_OUTL expressions T_EOS                  { $$ = stmt(T_OUTL, 1, $2);               }
          ;

string:   T_STRING                                    { dataValue _data;
                                                        d_type = 1;
                                                        _data.str = strdup($1);
                                                        $$ = constant(_data, d_type);           }
          ;

number:
          T_NUMBER                                    { dataValue _data;
                                                        d_type = 0;
                                                        _data.num = round($1); 
                                                        $$ = constant(_data, d_type);           }
          ;
%%

/* Main And YACC */
void main(int argc, char **argv)
{
  #ifdef YYDEBUG
  yydebug = DEBUG;
  #endif

  if(argc == 1)
  {
    printf("Theres no file to be executed\n");
    exit(0);
  }

  yyin = fopen(argv[1], "r");
  if(yyin == NULL)
  {
    printf("File [%s] not found\n", argv[1]);
    exit(0);
  }
  
  char* token_file = argc <= 2 ? "tokens.txt" : strdup(argv[2]);
  char* command_file = argc <= 3 ? "commands.txt" : strdup(argv[3]);

	yytokens = fopen(token_file, "w+");
  yycmd = fopen(command_file, "w+");
  
  
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
  fprintf(stderr, "In line %d: ", yylineno);
  fprintf(stderr, "%s\n", s);
  exit(1);
}