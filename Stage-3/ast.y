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
%type <tree> program instructions stmt inputstmt outputstmt assignstmt expr ifstmt whilestmt
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID IF THEN ELSE ENDIF WHILE DO ENDWHILE 
%left PLUS MINUS
%left MUL DIV
%nonassoc LT GT LTE GTE EQ NEQ CONTINUE BREAK


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
ifstmt          : IF '(' expr ')' THEN instructions ELSE instructions ENDIF ';'  {printf("Found IF_ELSE\n"); typecheck(_BOOLEAN,$<tree>3); $<tree>$ = createTree(-1,_TYPELESS,"IFELSE",_IFELSE,$<tree>6,$<tree>8,$<tree>3);}
                | IF '(' expr ')' THEN instructions ENDIF ';'                    {printf("Found IF \n");typecheck(_BOOLEAN,$<tree>3); $<tree>$ = createTree(-1,_TYPELESS,"IF",_IF,$<tree>6,NULL,$<tree>3);}                                                                     
                ;
whilestmt       : WHILE '(' expr ')' DO instructions ENDWHILE ';'                               {typecheck(_BOOLEAN,$<tree>3); $<tree>$ = createTree(-1,_TYPELESS,"WHILE",_WHILE,$<tree>6,NULL,$<tree>3);}
                ;
instructions    : instructions stmt             {
                                                    printf("Found instruction statement\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Stmnt",_CONNECTOR,$<tree>1,$<tree>2,NULL);
                                                }
                | stmt                          {
                                                    printf("Found Statement\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                ;
stmt            : inputstmt                     {
                                                    printf("Found inputstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | outputstmt                    {
                                                    printf("Found outputstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | assignstmt                    {
                                                    printf("Found assignstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | ifstmt                        {
                                                    printf("Found ifstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | whilestmt                     {
                                                    printf("Found whlestmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | BREAK ';'                     {
                                                    printf("Found Breakstmt\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Break",_BREAK,NULL,NULL,NULL);
                                                }
                | CONTINUE ';'                     {
                                                    printf("Found continue\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Continue",_CONTINUE,NULL,NULL,NULL);
                                                }
                ;
inputstmt       : READ '(' ID ')' ';'           {
                                                    printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Read",_READ,$<tree>3,NULL,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Write",_WRITE,$<tree>3,NULL,NULL);
                                                }
                ;
assignstmt      : ID ASSIGN expr ';'            {
                                                    printf("Found Assign\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"=",_ASSIGN,$<tree>1,$<tree>3,NULL);
                                                    typecheck(_INTEGER,$<tree>$);
                                                }
                ;
expr            : expr PLUS expr                {
                                                    printf("PLUS\n");
                                                    $<tree>$ = createTree(-1,_INTEGER,"+",_PLUS,$<tree>1,$<tree>3,NULL);
                                                    typecheck(_INTEGER,$<tree>$);
                                                }
                | expr MINUS expr               {
                                                    printf("MINUS\n");
                                                    $<tree>$ = createTree(-1,_INTEGER,"-",_MINUS,$<tree>1,$<tree>3,NULL);
                                                    typecheck(_INTEGER,$<tree>$);
                                                }
                | expr MUL expr                 {
                                                    printf("MUL\n");
                                                    $<tree>$ = createTree(-1,_INTEGER,"*",_MUL,$<tree>1,$<tree>3,NULL);
                                                    typecheck(_INTEGER,$<tree>$);
                                                }
                | expr DIV expr                 {
                                                    // printf("DIV\n");
                                                    $<tree>$ = createTree(-1,_INTEGER,"/",_DIV,$<tree>1,$<tree>3,NULL);
                                                    typecheck(_INTEGER,$<tree>$);
                                                }
                | expr LT expr                  {
                                                    printf("LT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LT",_LT,$<tree>1,$<tree>3,NULL);
                                                }
                | expr GT expr                  {
                                                    printf("GT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GT",_GT,$<tree>1,$<tree>3,NULL);
                                                //    typecheck(_BOOLEAN);
                                                }
                | expr GTE expr                 {
                                                    printf("GTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GE",_GTE,$<tree>1,$<tree>3,NULL);
                                                    // typecheck(_BOOLEAN);
                                                }
                | expr LTE expr                 {
                                                    printf("LTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LE",_LTE,$<tree>1,$<tree>3,NULL);
                                                    // typecheck(_BOOLEAN);
                                                }
                | expr EQ expr                  {
                                                    printf("EQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"EQ",_EQ,$<tree>1,$<tree>3,NULL);
                                                    // typecheck(_BOOLEAN);
                                                }
                | expr NEQ expr                 {
                                                    printf("NEQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"NE",_NEQ,$<tree>1,$<tree>3,NULL);
                                                    // typecheck(_BOOLEAN);
                                                }
                | '(' expr ')'                  {
                                                    $<tree>$=$<tree>2;
                                                }
                | NUM                           {
                                                    $<tree>$ = $<tree>1;
                                                }
                | ID                            {
                                                    $<tree>$=$<tree>1;
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