%{
    #include <stdio.h>
    #include <stdlib.h>    
%}
%token  CHARACTER NEWLINE
%left '+' '-'
%left '*' '/'
%union {
        char c;
       }
%type <c> expr
%%
start: expr NEWLINE     {printf("\nCompleted \n");
                        exit(1);}
     ;
expr : expr '+' expr    {printf("%c ",$<c>2);}
     | expr '-' expr    {printf("%c ",$<c>2);}
     | expr '*' expr    {printf("%c ",$<c>2);}  
     | expr '/' expr    {printf("%c ",$<c>2);}
     | '(' expr ')'     {}
     | CHARACTER        {
                            $<c>$ = $<c>1;
                            printf("%c ",$<c>1);
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