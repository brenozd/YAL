%option noyywrap
%option caseless

%x COMMENT
%x STRING

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

# include "YAL.tab.h"

int n_line = 0;

extern FILE* yytokens;
extern void yyerror(const char *s);

%}

    /* Definitions */
alpha [a-zA-Z]
special [_$]
digit [0-9]
quote "\'"

%%
    /*Symbols*/
";"                                                     { fprintf(yytokens, "T_EOS ");
                                                          return T_EOS;  } 
")"                                                     { fprintf(yytokens, "T_LP ");
                                                          return T_LP;   }
"("                                                     { fprintf(yytokens, "T_RP ");
                                                          return T_RP;   }
"\n"([ \t])*                                            { fprintf(yytokens, "\n");   
                                                          n_line++;  }    
[ \t]                                                   { /* ignore whitespace */   }

    /*Blocks*/
"_init"                                                 { fprintf(yytokens, "T_INIT ");  
                                                          return T_INIT; } 
"{"|"begin"                                             { fprintf(yytokens, "T_BLOCK_B "); 
                                                          return T_BLOCK_B; }
"}"|"end"                                               { fprintf(yytokens, "T_BLOCK_E "); 
                                                          return T_BLOCK_E; }

"#"                                                     { BEGIN(COMMENT); }
<COMMENT>"#"                                            { BEGIN(INITIAL); }
<COMMENT>\n                                             { n_line++;       }
<COMMENT>.                                              { }
<COMMENT><<EOF>>                                        { yyerror("Unexpected end of comment"); }
    /*Types*/
"let"                                                   { fprintf(yytokens, "T_LET ");
                                                          return T_LET; }

{digit}+("."{digit}*)?                                  { fprintf(yytokens, "T_NUMBER "); 
                                                          yylval.num_val = atof(yytext);
                                                          return T_NUMBER;          }

{quote}                                                 { BEGIN(STRING);                   }
<STRING>{quote}                                         { fprintf(yytokens, "T_STRING ");
                                                          BEGIN(INITIAL); 
                                                          return T_STRING;                 }
<STRING>[^"\'"]*                                        { yylval.str_val = strdup(yytext); }                                        
<STRING><<EOF>>                                         { yyerror("Unexpected end of string"); }

    /*IO*/
"in"|"<<"                                               { fprintf(yytokens, "T_IN ");       return T_IN;    }
"out"|">>"                                              { fprintf(yytokens, "T_OUT ");      return T_OUT;   }
"outl"|"\\>>"                                           { fprintf(yytokens, "T_OUTL ");     return T_OUTL;  }

    /*Relational*/
"="                                                     { fprintf(yytokens, "T_ASSGN ");    return T_ASSGN; }
"=="                                                    { fprintf(yytokens, "T_EQUAL ");    return T_EQUAL; }
"!="|"<>"                                               { fprintf(yytokens, "T_DIF ");      return T_DIF;   }
">"                                                     { fprintf(yytokens, "T_GREAT ");    return T_GREAT; }
"<"                                                     { fprintf(yytokens, "T_LESS ");     return T_LESS;  }
">="                                                    { fprintf(yytokens, "T_GE ");       return T_GE;    }
"<="                                                    { fprintf(yytokens, "T_LE ");       return T_LE;    }

    /*Arithmetic*/
"+"                                                     { fprintf(yytokens, "T_SUM ");      return T_SUM;   }    
"-"                                                     { fprintf(yytokens, "T_SUB ");      return T_SUB;   }
"*"                                                     { fprintf(yytokens, "T_MULT ");     return T_MULT;  }
"/"                                                     { fprintf(yytokens, "T_DIV ");      return T_DIV;   }
"%"                                                     { fprintf(yytokens, "T_MOD ");      return T_MOD;   }

    /* Composite */
"+="                                                    { fprintf(yytokens, "T_SUME ");     return T_SUME;  }
"-="                                                    { fprintf(yytokens, "T_SUBE ");     return T_SUBE;  }
"*="                                                    { fprintf(yytokens, "T_MULTE ");    return T_MULTE; }
"/="                                                    { fprintf(yytokens, "T_DIVE ");     return T_DIVE;  }

    /*Logical*/
"and"|"&&"                                              { fprintf(yytokens, "T_AND ");      return T_AND;   }
"or"|"||"                                               { fprintf(yytokens, "T_OR ");       return T_OR;    }
"not"|"!"                                               { fprintf(yytokens, "T_NOT ");      return T_NOT;   }

    /*Structures*/
"while"                                                 { fprintf(yytokens, "T_WHILE ");    return T_WHILE; }
"if"                                                    { fprintf(yytokens, "T_IF ");       return T_IF;    }
"else"                                                  { fprintf(yytokens, "T_ELSE");      return T_ELSE;  }

    /*Declaration*/
({alpha}|{special}|{digit})({alpha}|{digit})*           { fprintf(yytokens, "T_ID "); 
                                                          yylval.id_name = strdup(yytext);
                                                          return T_ID;              }

    /*Anything*/
.                                                       { printf("Unkown expression %s in line %d\n", yytext, n_line); }
%%