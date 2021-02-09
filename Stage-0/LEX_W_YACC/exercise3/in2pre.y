%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    char* join(char ,char *,char *);    
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
start: expr NEWLINE     {
                        printf("%s\n",$<seq>1);
                        exit(1);}
     ;
expr : expr '+' expr    {$<seq>$ = join($<c>2,$<seq>1,$<seq>3);}
     | expr '-' expr    {$<seq>$ = join($<c>2,$<seq>1,$<seq>3);}
     | expr '*' expr    {$<seq>$ = join($<c>2,$<seq>1,$<seq>3);}  
     | expr '/' expr    {$<seq>$ = join($<c>2,$<seq>1,$<seq>3);}
     | '(' expr ')'     {$<seq>$ = $<seq>2;}
     | SEQUENCE        {
                            $<seq>$ = $<seq>1;
                            // printf("%s ",$<seq>1);
                        }
     ;
%%
void yyerror(char const *s){
    printf("yyerror %s\n",s);
    return;
}
char *join(char op,char *exp1,char *exp2){
    int l1 = strlen(exp1);
    int l2 = strlen(exp2);
    char *final = (char *)malloc((l1+l2+3)*sizeof(char));
    int count = 0;
    final[count++] = op;
    final[count++] = ' ';
    for(int i=0;i<l1;i++){
        final[count++] = exp1[i];
    }   
    final[count++] = ' ';
    for(int i=0;i<l2;i++){
        final[count++] = exp2[i];
    }
    return final;

}
int main(){
    yyparse();
    return 1;
}
