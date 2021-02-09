%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "y.tab.h"  
%}
%option noyywrap
character [a-zA-Z]
op      [*+-/]
brackets [()]
newline "\n"
%%
{character}  {
            yylval.c = *yytext;
            return CHARACTER;
            }
{op}      {yylval.c = *yytext;
            return *yytext;}
{brackets} {yylval.c = *yytext;
            return *yytext;}
{newline} {return NEWLINE;}
%%