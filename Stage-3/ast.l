%{
    #include <stdio.h>
    #include <stdlib.h>    
    #include "y.tab.h"
    #include "ast.h"
    int number;
%}
%option noyywrap
%%
[0-9]+ {number = atoi(yytext); yylval.tree = createTree(number,_INT,NULL,_NUM,NULL,NULL);return NUM;}
[a-z]  {
        char *c;
        c=(char*) malloc(sizeof(yytext));
        strcpy(c,yytext);
        yylval.tree = createTree(-1,-1,c,_ID,NULL,NULL);
        return ID;}
begin  {return START;}
end    {return END;}
read   {return READ;}
write  {return WRITE;}
";"    {return *yytext;}
"="    {return ASSIGN;}
"+"    {return PLUS;}
"-"    {return MINUS;}
"*"    {return MUL;}
"/"    {return DIV;}
[()]   {return *yytext;}
[ \t\n] {}
%%