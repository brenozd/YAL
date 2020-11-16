%option noyywrap
%option caseless

%{
#include <stdio.h>
#include <stdlib.h>

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
"#".*                                                   { /* ignore comments */     }

    /*Types*/
{digit}+                                            { yylval = atoi(yytext); 
                                                          return T_INTEGER;         }
{digit}*"."{digit}+                                 { yylval = atoi(yytext);
                                                          return T_FLOAT;           }
{quote}{alpha}{quote}                                   { return T_CHAR;            }
{quote}({alpha}|{special}){2,}{quote}                   { return T_STRING;          }
[("true")|("false")]                                    { return T_BOOLEAN;         }

    /*IO*/
"in"|"<<"                                               { return T_IN;              }
"out"|">>"                                              { return T_OUT;             }

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
"^"                                                     { return T_POW;             }
"%"                                                     { return T_MOD;             }

    /*Logical*/
"and"|"&&"                                              { return T_AND;             }
"or"|"||"                                               { return T_OR;              }
"not"|"!"                                               { return T_NOT;             }
"xor"                                                   { return T_XOR;             }

    /*Structures*/
"while"                                                 { return T_WHILE;           }
"if"                                                    { return T_IF;              }
"else"                                                  { return T_ELSE;            }

    /*Declaration*/
({alpha}|{special}|{digit})({alpha}|{digit})*           { return T_ID;              }

    /*Anything*/
.                                                       { return *yytext;           }
%%