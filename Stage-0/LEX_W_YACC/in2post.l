%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "y.tab.h"
%}
%option noyywrap
%%
[0-9]+ {
        yylval = atoi(yytext);
        return DIGIT;
       }
"+"    return *yytext;
"-"    return *yytext;
"*"    return *yytext;
"/"    return *yytext;
[()]   return *yytext;
[\n]   return NEWLINE;
%%
