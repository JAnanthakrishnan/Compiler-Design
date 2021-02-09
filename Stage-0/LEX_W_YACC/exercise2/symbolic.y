%{
    #include <stdio.h>
    #include <stdlib.h>    
%}
%token  SEQUENCE NEWLINE
%left '+' '-'
%left '*' '/'
%union {
        char c;
        char *seq;
       }
%type <seq> expr
%%
start: expr NEWLINE     {printf("\nCompleted \n");
                        exit(1);}
     ;
expr : expr '+' expr    {printf("%c ",$<c>2);}
     | expr '-' expr    {printf("%c ",$<c>2);}
     | expr '*' expr    {printf("%c ",$<c>2);}  
     | expr '/' expr    {printf("%c ",$<c>2);}
     | '(' expr ')'     {}
     | SEQUENCE        {
                            $<seq>$ = $<seq>1;
                            printf("%s ",$<seq>1);
                        }
     ;
%%
void yyerror(char const *s){
    printf("yyerror %s\n",s);
    return;
}
int main(){
    yyparse();
    return 1;
}