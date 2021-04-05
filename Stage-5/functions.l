%{
    #include <stdio.h>
    #include <stdlib.h>    
    #include "y.tab.h"
    #include "functions.h"
    int number;
%}
%option noyywrap
id [a-zA-Z_][0-9a-zA-Z_]*
str \"(\\.|[^\\\"])*\"
%%
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
break       {return BREAK;}
continue    {return CONTINUE;}
decl        {return DECL;}
enddecl     {return ENDDECL;}
int         {return INT;}
str         {return STR;}
main        {return MAIN;}
return      {return RETURN;}
NOT         {return NOT;}
"!"         {return NOT;}
AND         {return AND;}
"&&"        {return AND;}
OR          {return OR;}
"||"        {return OR;}
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
"%"         {return MOD;}
","         {return *yytext;}
"{"         {return *yytext;}
"}"         {return *yytext;}
"["         {return *yytext;}
"]"         {return *yytext;}
[()]        {return *yytext;}
[ \t\n] {}
[0-9]+      {number = atoi(yytext); yylval.tree = createTree(number,_INTEGER,NULL,_NUM,NULL,NULL,NULL,NULL,NULL,NULL);return NUM;}
{id}        {
                // printf("got id\n");
                char *c;
                c=(char*) malloc(sizeof(yytext));
                // printf("ID: %s\n",yytext);
                strcpy(c,yytext);
                yylval.tree = createTree(-1,-1,c,_ID,NULL,NULL,NULL,NULL,NULL,NULL);
                return ID;
             }
{str}       {
                printf("Got string\n");
                char *c;
                c=(char*) malloc(sizeof(yytext));
                strcpy(c,yytext);
                int length = strlen(c);
                printf("%s\n",c);
                yylval.tree = createTree(-1,_STRING,c,_STRING,NULL,NULL,NULL,NULL,NULL,NULL);
                return STRING;
            }
%%