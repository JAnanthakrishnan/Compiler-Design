%{
    #include <stdio.h>
    #include <stdlib.h>    
    #include "y.tab.h"
    #include "types.h"
    int number;
%}
%option noyywrap
id [a-zA-Z_][0-9a-zA-Z_]*
str \"(\\.|[^\\\"])*\"
%%
begin       {return START;}
end         {return END;}
type        {return TYPE;}
endtype     {return ENDTYPE;}
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
"."         {return *yytext;}
null        {   
                yylval.tree = createTree(-1,TLookup("NULL"),"null",_NULLTYPE,NULL,NULL,NULL,NULL,NULL,NULL);
                return NULLTYPE;
            }
alloc       {  
                
                yylval.tree = createTree(-1,TLookup("NULL"),"alloc",_ALLOC,NULL,NULL,NULL,NULL,NULL,NULL);
                return ALLOC;
            }
initialize  {   
                yylval.tree = createTree(-1,TLookup("NULL"),"initialize",_INITIALIZE,NULL,NULL,NULL,NULL,NULL,NULL);
                return INITIALIZE;
            }
free        {   
                yylval.tree = createTree(-1,TLookup("NULL"),"free",_FREE,NULL,NULL,NULL,NULL,NULL,NULL);
                return FREE;
            }
[()]        {return *yytext;}
[ \t\n]     {}
[0-9]+      {number = atoi(yytext); yylval.tree = createTree(number,TLookup("INT"),NULL,_NUM,NULL,NULL,NULL,NULL,NULL,NULL);return NUM;}
{id}        {
                // printf("got id\n");
                char *c;
                c=(char*) malloc(sizeof(yytext));
                // printf("ID: %s\n",yytext);
                strcpy(c,yytext);
                yylval.tree = createTree(-1,TLookup("NULL"),c,_ID,NULL,NULL,NULL,NULL,NULL,NULL);
                return ID;
             }
{str}       {
                printf("Got string\n");
                char *c;
                c=(char*) malloc(sizeof(yytext));
                strcpy(c,yytext);
                int length = strlen(c);
                printf("%s\n",c);
                yylval.tree = createTree(-1,TLookup("STR"),c,_STRING,NULL,NULL,NULL,NULL,NULL,NULL);
                return STRING;
            }
%%