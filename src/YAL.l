%option noyywrap
%option caseless

%{
#include <stdio.h>

#define YY_DECL int yylex()

# include "YAL.tab.h"
%}

%%
    /*Blocks*/
"_init"             { return INIT;     } 
"{"|"begin"         { return BLOCK_B;  }
"}"|"end"           { return BLOCK_E;  }

    /*Types*/
[+-]?[0-9]+         { return INTEGER;  }
[+-]?[0-9]*.?[0-9]+ { return FLOAT;    }
[a-zA-Z]            { return CHAR;     }
[a-zA-Z]+           { return STRING;   }

    /*IO*/
"in"|"<<"           { return IN;       }
"out"|">>"          { return OUT;      }

    /*Relational*/
"=="                { return EQUAL;    }
"!="|"<>"           { return DIF;      }
">"                 { return GREAT;    }
"<"                 { return LESS;     }
">="                { return GE;       }
"<="                { return LE;       }

    /*Arithmetic*/
"+"                 { return SUM;      }
"-"                 { return SUB;      }
"*"                 { return MULT;     }
"/"                 { return DIV;      }
"^"                 { return POW;      }
"%"                 { return MOD;      }

    /*Logical*/
"and"|"&&"          { return AND;      }
"or"|"||"           { return OR;       }
"not"|"!"           { return NOT;      }
"xor"               { return XOR;      }

    /*Structures*/
"for"               { return FOR;      }
"while"             { return WHILE;    }
"if"                { return IF;       }
"else"              { return ELSE;     }

%%