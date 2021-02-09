%{
    #include <stdio.h>
    #include <stdlib.h>    
%}
%token DIGIT NEWLINE
%left '+' '-'
%left '*' '/'

%%
start: expr NEWLINE {printf("\nComplete, Expression Value = %d\n",$1);
                     exit(1);
                    }
expr: expr '+' expr {$$ = $1+$3;}
    | expr '-' expr {$$ = $1-$3;}
    | expr '*' expr {$$ = $1*$3;}
    | expr '/' expr {$$ = $1/$3;}
    | '(' expr ')'  {$$ = $2;}
    | DIGIT         {$$ = $1;}
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

