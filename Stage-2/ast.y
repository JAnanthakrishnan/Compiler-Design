%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "ast.h" 
    #include "ast.c"
    #include "codegen.c"
    extern FILE *yyin;
 	FILE *output;
	struct tnode* root;
	int yylex(void);
%}
%union{
    struct tnode* tree;
}
%type <tree> program instructions stmt inputstmt outputstmt assignstmt expr
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID
%left PLUS MINUS
%left MUL DIV

%%

program         : START instructions END        {
                                                    printf("Completed\n");
                                                    $<tree>$ = $<tree>2;
                                                    root=$<tree>$;
                                                    inorder($<tree>$);
                                                    printf("\n");
                                                    return 1;
                                                }
                | START END                     {printf("Completed\n");exit(1);}
                ;
instructions    : instructions stmt             {
                                                    // printf("Found instruction statement\n");
                                                    $<tree>$ = createTree(-1,-1,"Stmnt",_CONNECTOR,$<tree>1,$<tree>2);
                                                }
                | stmt                          {
                                                    // printf("Found Statement\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                ;
stmt            : inputstmt                     {
                                                    // printf("Found inputstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | outputstmt                    {
                                                    // printf("Found outputstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | assignstmt                    {
                                                    // printf("Found assignstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                ;
inputstmt       : READ '(' ID ')' ';'           {
                                                    // printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,-1,"Read",_READ,$<tree>3,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    // printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,-1,"Write",_WRITE,$<tree>3,NULL);
                                                }
                ;
assignstmt      : ID ASSIGN expr ';'            {
                                                    // printf("Found Assign\n");
                                                    $<tree>$ = createTree(-1,-1,"=",_ASSIGN,$<tree>1,$<tree>3);
                                                }
                ;
expr            : expr PLUS expr                {
                                                    // printf("PLUS\n");
                                                    $<tree>$ = createTree(-1,-1,"+",_PLUS,$<tree>1,$<tree>3);
                                                }
                | expr MINUS expr               {
                                                    // printf("MINUS\n");
                                                    $<tree>$ = createTree(-1,-1,"-",_MINUS,$<tree>1,$<tree>3);
                                                }
                | expr MUL expr                 {
                                                    // printf("MUL\n");
                                                    $<tree>$ = createTree(-1,-1,"*",_MUL,$<tree>1,$<tree>3);
                                                }
                | expr DIV expr                 {
                                                    // printf("DIV\n");
                                                    $<tree>$ = createTree(-1,-1,"/",_DIV,$<tree>1,$<tree>3);
                                                }
                | '(' expr ')'                  {
                                                    $<tree>$=$<tree>2;
                                                }
                | NUM                           {
                                                    $<tree>$ = $<tree>1;
                                                }
                | ID                            {
                                                    $<tree>$=$<tree>$;
                                                }
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
    fprintf(output,"MOV SP,4121\n");
    codegen(root,output);
    fprintf(output,"INT 10");
    fclose(output);
	/* print(r,output); */
	return 0;
}