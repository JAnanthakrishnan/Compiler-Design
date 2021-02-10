%{
    #include <stdio.h>
    #include <stdlib.h>    
    #include "y.tab.h"
    #include "ast.h"
    int number;
%}
%option noyywrap
%%
[0-9]+      {number = atoi(yytext); yylval.tree = createTree(number,_INTEGER,NULL,_NUM,NULL,NULL,NULL);return NUM;}
[a-z]       {
                char *c;
                c=(char*) malloc(sizeof(yytext));
                strcpy(c,yytext);
                yylval.tree = createTree(-1,_INTEGER,c,_ID,NULL,NULL,NULL);
                return ID;
            }
begin       {return START;}
end         {return END;}
read        {return READ;}
write       {return WRITE;}
if          {return IF;}
then        {return THEN;}
else        {return ELSE;}
endif       {return ENDIF;}
while       {return WHILE;}
do          {return DO;}
endwhile    {return ENDWHILE;}
"<"         {return LT;}
">"         {return GT;}
">="        {return GTE;}
"<="        {return LTE;}
"=="        {return EQ;}
"!="        {return NEQ;}
";"         {return *yytext;}
"="         {return ASSIGN;}
"+"         {return PLUS;}
"-"         {return MINUS;}
"*"         {return MUL;}
"/"         {return DIV;}
[()]        {return *yytext;}
[ \t\n] {}
%%