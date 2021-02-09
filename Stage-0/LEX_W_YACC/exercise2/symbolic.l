%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "y.tab.h"  
%}
%option noyywrap
sequence [a-zA-Z]+
op      [*+-/]
brackets [()]
newline "\n"
%%
{sequence}  {
            char *s;
            s = (char *)malloc(sizeof(yytext));
            strcpy(s,yytext);
            // printf("String is %s\n",s);
            yylval.seq = s;
            return SEQUENCE;
            }
{op}      {yylval.c = *yytext;
            return *yytext;}
{brackets} {yylval.c = *yytext;
            return *yytext;}
{newline} {return NEWLINE;}
%%