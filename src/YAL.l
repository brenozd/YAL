%option noyywrap
%option caseless
%x C_COMMENT

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

# include "YAL.tab.h"
%}

    /* Definitions */
alpha [a-zA-Z]
special [_$]
digit [0-9]
quote "'"

%%
    /*Symbols*/
"'"                                                     { return T_QUOTE;           }
";"                                                     { return T_EOS;             } 
")"                                                     { return T_LP;              }
"("                                                     { return T_RP;              }
\n                                                      { /* ignore newline */      }    
[ \t]                                                   { /* ignore whitespace */   }

    /*Blocks*/
"_init"                                                 { return T_INIT;            } 
"{"|"begin"                                             { return T_BLOCK_B;         }
"}"|"end"                                               { return T_BLOCK_E;         }

"<!"            { BEGIN(C_COMMENT); }
<C_COMMENT>"!>" { BEGIN(INITIAL); }
<C_COMMENT>\n   { }
<C_COMMENT>.    { }

    /*Types*/
{digit}+                                                { yylval.int_val = atoi(yytext); 
                                                          return T_INTEGER;         }
{digit}*"."{digit}+                                     { yylval.float_val = atoi(yytext);
                                                          return T_FLOAT;           }
{quote}({alpha}|{digit}|{special}){quote}               { yylval.str_val = strdup(yytext); 
                                                          return T_CHAR;            }
{quote}({alpha}|{digit}|{special}){2,}{quote}           { yylval.str_val = strdup(yytext);
                                                          return T_STRING;          }
[("true")|("false")]                                    { yylval.int_val = atoi(yytext);
                                                          return T_BOOLEAN;         }

    /*IO*/
"in"|"<<"                                               { return T_IN;              }
"out"|">>"                                              { return T_OUT;             }
"outl"|"\\>>"                                            { return T_OUTL;             }

    /*Relational*/
"="                                                     { return T_ASSGN;           }
"=="                                                    { return T_EQUAL;           }
"!="|"<>"                                               { return T_DIF;             }
">"                                                     { return T_GREAT;           }
"<"                                                     { return T_LESS;            }
">="                                                    { return T_GE;              }
"<="                                                    { return T_LE;              }

    /*Arithmetic*/
"+"                                                     { return T_SUM;             }    
"-"                                                     { return T_SUB;             }
"*"                                                     { return T_MULT;            }
"/"                                                     { return T_DIV;             }
"%"                                                     { return T_MOD;             }

    /*Logical*/
"and"|"&&"                                              { return T_AND;             }
"or"|"||"                                               { return T_OR;              }
"not"|"!"                                               { return T_NOT;             }

    /*Structures*/
"while"                                                 { return T_WHILE;           }
"if"                                                    { return T_IF;              }
"else"                                                  { return T_ELSE;            }

    /*Declaration*/
({alpha}|{special}|{digit})({alpha}|{digit})*           { yylval.idIndex = *yytext - 'a';
                                                          return T_ID;              }

    /*Anything*/
.                                                       { return *yytext;           }
%%