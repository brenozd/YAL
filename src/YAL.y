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
extern FILE* yyout;
int sym[26]; 

/* Prototypes */
void yyerror(const char* s);

nodeType *stmt(int oper, int nops, ...);
nodeType *id(int i);
nodeType *constant(int value);

void freeNode(nodeType *p);
int ex(nodeType *p);
%}

%union {
    char* str_val;
    int int_val;
    float float_val;

    int idIndex;
    struct nodeType *nPtr;            
};

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
%token <idIndex> T_ID
%right T_ASSGN
%token <int_val> T_INTEGER T_BOOLEAN
%token <float_val> T_FLOAT 
%token <str_val> T_CHAR T_STRING 

//IO
%left T_IN T_OUT T_OUTL

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

%type <nPtr> statements statement_list expressions commands block out_stm outl_stm while_stm if_stm else_stm type declare
%%

program: 
          T_INIT block { exit(0); }
          ;

block: 
            T_BLOCK_B statement_list T_BLOCK_E { execNode($2);}
          ;

statement_list: 
            statement_list statements  { $$ = stmt(T_EOS, 2, $1, $2); }
          | statements                 { $$ = $1; }
          ;

statements:  
            declare
          | expressions
          | commands
          | T_EOS                      { $$ = stmt(T_EOS, 2, NULL, NULL); }
          ;

commands:
            if_stm
          | while_stm
          | in_stm
          | out_stm
          | outl_stm
          ;

declare: 
            T_ID T_EOS                              { $$ = stmt(T_ASSGN, 1, id($1)); }
          | T_ID T_ASSGN expressions T_EOS          { $$ = stmt(T_ASSGN, 3, id($1), $3); }
          ;

expressions:
            expressions T_EQUAL expressions         { $$ = stmt(T_EQUAL, 2, $1,  $3);}
          | expressions T_DIF expressions           { $$ = stmt(T_DIF, 2, $1,  $3);}
          | expressions T_GREAT expressions         { $$ = stmt(T_GREAT, 2, $1,  $3);}
          | expressions T_LESS expressions          { $$ = stmt(T_LESS, 2, $1,  $3);}
          | expressions T_GE expressions            { $$ = stmt(T_GE, 2, $1,  $3);}
          | expressions T_LE expressions            { $$ = stmt(T_LE, 2, $1,  $3);}
          | expressions T_SUM expressions           { $$ = stmt(T_SUM, 2, $1,  $3);}
          | expressions T_SUB expressions           { $$ = stmt(T_SUB, 2, $1,  $3);}
          | expressions T_MULT expressions          { $$ = stmt(T_MULT, 2, $1,  $3);}
          | expressions T_DIV expressions           { $$ = stmt(T_DIV, 2, $1,  $3);}
          | expressions T_MOD expressions           { $$ = stmt(T_MOD, 2, $1,  $3);}
          | expressions T_AND expressions           { $$ = stmt(T_AND, 2, $1,  $3);}
          | expressions T_OR expressions            { $$ = stmt(T_OR, 2, $1,  $3);}
          | expressions T_NOT expressions           { $$ = stmt(T_NOT, 2, $1, $3);}
          | T_SUB expressions                       { $$ = stmt(T_NEGATIVE, 1, $2);}
          | T_RP expressions T_LP                   { $$ = $2;                     }
          | type                                                             
          ;

if_stm:
          T_IF T_RP expressions T_LP block else_stm { $$ = stmt(T_IF, 2, $3, $5); }
          ;

else_stm:
          T_ELSE block
          | /* empty */
          ;

while_stm:
          T_WHILE T_RP expressions T_LP block { $$ = stmt(T_WHILE, 2, $3, $5); }
          ;

in_stm:
          T_IN T_ID type T_EOS
          ;

out_stm:
            T_OUT expressions T_EOS { $$ = stmt(T_OUT, 1, $2); }                     
          ;

outl_stm:
            T_OUTL expressions T_EOS { $$ = stmt(T_OUTL, 1, $2); }                     
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

/* Interpreter Code */

#define sizeof_Node (((char *)&node->cnt - (char *)node))

nodeType* constant(int value)
{
  nodeType *node;
  size_t nodeSize;

  nodeSize = sizeof_Node + sizeof(constNode);
  if((node=malloc(nodeSize)) == NULL)
    yyerror("Out of memory");
  node->type = Constant;
  node->id.value = value;
  return node;
}

nodeType* id(int value)
{
  nodeType *node;
  size_t nodeSize;

  nodeSize = sizeof_Node + sizeof(idNode);
  if((node=malloc(nodeSize)) == NULL)
    yyerror("Out of memory");
  node->type = Id;
  node->id.value = value;
  return node;
}

nodeType* stmt(int opr, int num_operators, ...)
{
  va_list args;
  nodeType *node;
  size_t nodeSize;

  nodeSize = sizeof_Node + sizeof(stmtNode) + (num_operators-1)*(sizeof(nodeType*));
  if((node=malloc(nodeSize)) == NULL)
    yyerror("Out of memory");

  node->type = Statement;
  node->stmt.opr = opr;
  node->stmt.num_operators = num_operators;
  va_start(args, num_operators);
  for (size_t i = 0; i < num_operators; i++){
    node->stmt.op[i] = va_arg(args, nodeType*);
  }
  va_end(args);
  return node;
}

void freeNode(nodeType *node)
{
  if (!node)  
    return;

  if(node->type == Statement)
  {
    for (size_t i = 0; i < node->stmt.num_operators; i++)
    {
      freeNode(node->stmt.op[i]);
    }
  }
  free(node);
}

/* Main And YACC */
void main(int argc, char **argv)
{
  #ifdef YYDEBUG
  yydebug = DEBUG;
  #endif

  yyin = fopen(argv[1], "r");
	yyout = fopen(argv[2], "w+");

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
  fclose(yyout);
}

void yyerror(const char *s)
{
  fprintf(stderr, "ERROR: %s\n", s);
}