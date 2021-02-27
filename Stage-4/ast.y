%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "ast.h" 
    #include "ast.c"
    #include "codegen.c"
    extern FILE *yyin;
    struct Gsymbol* Gstart=NULL;
 	FILE *output;
    int var_type = -1;
	struct tnode* root;
	int yylex(void);
%}
%union{
    struct tnode* tree;
}
%type <tree> program instructions stmt inputstmt outputstmt assignstmt expr ifstmt whilestmt
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID IF THEN ELSE ENDIF WHILE DO ENDWHILE DECL ENDDECL INT STR STRING
%nonassoc LT GT LTE GTE EQ NEQ CONTINUE BREAK
%left PLUS MINUS
%left MOD
%left MUL DIV 


%%

program         : declarations START instructions END        {
                                                    printf("Completed\n");
                                                    $<tree>$ = $<tree>3;
                                                    root=$<tree>$;
                                                    inorder($<tree>$);
                                                    printf("\n");
                                                    return 1;
                                                }
                | declarations START END                     {printf("Completed\n");exit(1);}
                ;
declarations    : DECL decllist ENDDECL         {printf("End of Declaration\n");printTable();}
                | DECL ENDDECL                  {printf("End of empty Declaration\n");printTable();}
                ;
decllist        : decllist decl
                | decl
decl            : Type Varlist ';'
                ;
Type            : INT                           {printf("Found INT type \n"); var_type = 0;}
                | STR                           {printf("Found STR type \n"); var_type = 1;}
                ;
Varlist         : Varlist',' ID                 {Install(($<tree>3)->varname,var_type,1);}
                | ID                            {Install(($<tree>1)->varname,var_type,1);}
                | Varlist',' ID'['NUM']'        {Install(($<tree>3)->varname,var_type,($<tree>5)->val);}
                | ID '['NUM']'                  {Install(($<tree>1)->varname,var_type,($<tree>3)->val);}
                ;
ifstmt          : IF '(' expr ')' THEN instructions ELSE instructions ENDIF ';'  {printf("Found IF_ELSE\n");  $<tree>$ = createTree(-1,_TYPELESS,"IFELSE",_IFELSE,$<tree>6,$<tree>8,$<tree>3,NULL);}
                | IF '(' expr ')' THEN instructions ENDIF ';'                    {printf("Found IF \n"); $<tree>$ = createTree(-1,_TYPELESS,"IF",_IF,$<tree>6,NULL,$<tree>3,NULL);}                                                                     
                ;
whilestmt       : WHILE '(' expr ')' DO instructions ENDWHILE ';'                               { $<tree>$ = createTree(-1,_TYPELESS,"WHILE",_WHILE,$<tree>6,NULL,$<tree>3,NULL);}
                ;
instructions    : instructions stmt             {
                                                    printf("Found instruction statement\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Stmnt",_CONNECTOR,$<tree>1,$<tree>2,NULL,NULL);
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
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Break",_BREAK,NULL,NULL,NULL,NULL);
                                                }
                | CONTINUE ';'                     {
                                                    printf("Found continue\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Continue",_CONTINUE,NULL,NULL,NULL,NULL);
                                                }
                ;
inputstmt       : READ '(' id ')' ';'           {
                                                    printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Read",_READ,$<tree>3,NULL,NULL,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Write",_WRITE,$<tree>3,NULL,NULL,NULL);
                                                }
                ;
assignstmt      : id ASSIGN expr ';'            {
                                                    printf("Found Assign\n");
                                                    if(($<tree>3->type==_STRING&&$<tree>1->Gentry->type==0)){
                                                         printf("Semantic error type mismatch assign statement\n");
                                                        exit(1);
                                                    }
                                                    
                                                    else {
                                                        $<tree>$ = createTree(-1,_TYPELESS,"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL);

                                                    }
                                                    
                                                }
                ;
expr            : expr PLUS expr                {
                                                    printf("PLUS\n");
                                                    $<tree>$ = createTree($<tree>1->val+$<tree>3->val,_INTEGER,"+",_PLUS,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MINUS expr               {
                                                    printf("MINUS\n");
                                                    $<tree>$ = createTree($<tree>1->val-$<tree>3->val,_INTEGER,"-",_MINUS,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MUL expr                 {
                                                    printf("MUL\n");
                                                    $<tree>$ = createTree($<tree>1->val*$<tree>3->val,_INTEGER,"*",_MUL,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr DIV expr                 {
                                                    // printf("DIV\n");
                                                    $<tree>$ = createTree($<tree>1->val/$<tree>3->val,_INTEGER,"/",_DIV,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MOD expr                 {
                                                    $<tree>$ = createTree($<tree>1->val%$<tree>3->val,_INTEGER,"%",_MOD,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LT expr                  {
                                                    printf("LT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LT",_LT,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr GT expr                  {
                                                    printf("GT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GT",_GT,$<tree>1,$<tree>3,NULL,NULL);
                                                   typecheck($<tree>$);
                                                }
                | expr GTE expr                 {
                                                    printf("GTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GE",_GTE,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LTE expr                 {
                                                    printf("LTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LE",_LTE,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr EQ expr                  {
                                                    printf("EQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"EQ",_EQ,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr NEQ expr                 {
                                                    printf("NEQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"NE",_NEQ,$<tree>1,$<tree>3,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | '(' expr ')'                  {
                                                    $<tree>$=$<tree>2;
                                                }
                | NUM                           {
                                                    $<tree>$ = $<tree>1;
                                                }
                | STRING                        {
                                                    $<tree>$=$<tree>1;
                                                }
                | id                            {  $<tree>$ = $<tree>1;}
                ;
id              : ID                            {
                                                   
                                                    struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                    if(temp ==NULL){
                                                        printf("Variable not declared\n");
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,-1,$<tree>1->varname,_ID,NULL,NULL,NULL,temp);
                                                }
                | ID'['expr']'                   {
                                                    struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                    if(temp==NULL){
                                                        printf("Variable not declared\n");
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,-1,$<tree>1->varname,_ARR,$<tree>3,NULL,NULL,temp);
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
    fprintf(output,"MOV SP,%d\n",getSP()-1);
    inorder(root);
    codegen(root,output);
    fprintf(output,"INT 10");
    fclose(output);
	/* print(r,output); */
	return 0;
}