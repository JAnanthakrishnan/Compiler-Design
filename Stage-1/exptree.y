%{
	#include <stdlib.h>
	#include <stdio.h>
	#include "exptree.h"
	#include "exptree.c"
	#include "codegen.c"
	extern FILE *yyin;
 	FILE *output;
	struct tnode* root;
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
				$<no>$ = $<no>1;
				root = $<no>1;
                printf("Prefix : ");
                preorder($<no>1);
                printf("\n");
                printf("Postfix : ");
                postorder($<no>1);
                printf("\n");
				printf("Answer : %d\n",evaluate($<no>1));
				return 1;
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


int main(int argc, char* argv[]) {
	if(argc<2){
		printf("Input file is required\n");
		exit(1);
	}
	else {
		yyin = fopen(argv[1],"r");
		if(!yyin)
			{
				printf("Input file is invalid\n");
				exit(1);
			}
	}
	FILE *output = fopen("output.xsm","w");
	if(!output){
		printf("Unable to open output file\n");
		exit(1);
	}
	fprintf(output, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", 0, 2056, 0, 0, 0, 0, 0, 0);
	yyparse();
	int r = codegen(root,output);
	print(r,output);
	return 0;
}