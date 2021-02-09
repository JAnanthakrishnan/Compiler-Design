%{
	#include <stdlib.h>
	#include <stdio.h>
	#include "exptree.h"
	#include "exptree.c"
	int yylex(void);

%}

%union{
	struct tnode *no;
	
}
%type <no> expr  program 
%token NUM PLUS MINUS MUL DIV END
%left PLUS MINUS
%left MUL DIV

%%

program : expr END	{
				$<no>$ = $<no>2;
				printf("Answer : %d\n",evaluate($<no>1));
				exit(1);
			}
		;

expr : expr PLUS expr		{$<no>$ = makeOperatorNode('+',$<no>1,$<no>3);}
	 | expr MINUS expr  	{$<no>$ = makeOperatorNode('-',$<no>1,$<no>3);}
	 | expr MUL expr	{$<no>$ = makeOperatorNode('*',$<no>1,$<no>3);}
	 | expr DIV expr	{$<no>$ = makeOperatorNode('/',$<no>1,$<no>3);}
	 | '(' expr ')'		{$<no>$ = $<no>2;}
	 | NUM			{$<no>$ = $<no>1;}
	 ;

%%

void yyerror(char const *s)
{
    printf("yyerror %s",s);
}


int main(void) {
	yyparse();
	
	return 0;
}