%{
  #include <stdio.h>
  #include <stdlib.h>
  int yyerror();
%}

%token DIGIT NEWLINE

%%

start : pair NEWLINE		{printf("\nComplete\n"); exit(1);}
	  ;

pair: num ',' num       { printf("Pair (%d, %d)\n",$1,$3);}
     ;
num : DIGIT             {printf("NUM = %d\n",$1); $$ = $1;}

%%

int yyerror()
{
	printf("Error");
}

int main()
{
	yyparse();
	return 1;
}