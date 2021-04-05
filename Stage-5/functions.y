%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "functions.h" 
    #include "functions.c"
    #include "codegen.c"
    extern FILE *yyin;
    struct Gsymbol* Gstart=NULL;
    struct Lsymbol* Lstart = NULL;
    struct paramlist *funparams = NULL;
 	FILE *output;
    int var_type = -1;
    int ftype = -1;
    int ltype = -1;
    int initialized = 0;
    int installed = 0;      //to check whether params are installed on local symbol table, should be turned back when fdef is complete.
    char fname[100];
	struct tnode* root;
	int yylex(void);
    //binding 0-local
    //binding 1-global
%}
%union{
    struct tnode* tree;
    struct paramlist *plist;
}
%type <plist> Param ParamList FinalParamlist
%type <tree>  instructions stmt inputstmt outputstmt assignstmt expr ifstmt whilestmt
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID IF THEN ELSE ENDIF WHILE DO ENDWHILE DECL ENDDECL INT STR STRING MAIN RETURN 
%left AND OR NOT
%nonassoc LT GT LTE GTE EQ NEQ CONTINUE BREAK
%left PLUS MINUS
%left MOD
%left MUL DIV 


%%

Program         : GdeclBlock FDefBlock MainBlock    {}
                | GdeclBlock MainBlock              {}
                | MainBlock                         {}
                ;
GdeclBlock      : DECL GdeclList ENDDECL            {init(output);initialized = 1;}
                | DECL ENDDECL                      {init(output);initialized = 1;}
                ;

GdeclList       : GdeclList GDecl                   {}
                | GDecl                             {}
                ;
GDecl           : Type GidList ';'                  {}
                ;

GidList         : GidList ',' Gid                   {}
                | Gid                               {}
                ;

Gid             : ID                                {
                                                    GInstall(($<tree>1)->varname,var_type,1,NULL);
                                                    }
                | ID '[' NUM ']'                    {
                                                    GInstall(($<tree>1)->varname,var_type,($<tree>3)->val,NULL);}
                | ID '(' ParamList ')'              {
                                                    GInstall(($<tree>1)->varname,var_type,0,$<plist>3);
                                                    }
                ;
FDefBlock       : FDefBlock Fdef                    {
                                                    }
                | Fdef                              {}
                ;

Fdef            : Type ID '(' FinalParamlist ')' '{' LdeclBlock Body '}'        {
                                                                                struct Gsymbol* temp = Lookup(($<tree>2)->varname);
                                                                                if(temp == NULL){
                                                                                    printf("Function %s is not declared\n",$<tree>2->varname);
                                                                                    exit(1);
                                                                                }
                                                                                if(temp->type!=var_type){
                                                                                    printf("Mismatch in return type of function definition of %s\n",temp->name);
                                                                                    exit(1);

                                                                                }
                                                                                int res = nameEquivalence($<plist>4,temp->plist);
                                                                                if(res==0){
                                                                                    printf("Mismatch in argument types in definition of function %s\n",temp->name);
                                                                                    exit(1);
                                                                                }
                                                                                if(var_type!=temp->type){
                                                                                    printf("Mismatch in return type in definition of function %s\n",temp->name);
                                                                                    exit(1);
                                                                                }
                                                                                setLocalbinding();
                                                                                temp->defined = 1;
                                                                                calleegen($<tree>8,output,temp);
                                                                                Lstart = NULL;
                                                                                installed = 0;
                                                                            }
                ;
FinalParamlist  : ParamList                                                 {
                                                                                if(!installed){
                                                                                LPInstall(funparams);
                                                                                installed  = 1;
                                                                                } 
                                                                            }

ParamList       : ParamList ',' Param                                       {$<plist>$ = PInstall($<plist>1,$<plist>3->name,$<plist>3->type);funparams = $<plist>$;}
                | Param                                                     {$<plist>$ = $<plist>1; funparams = $<plist>$;}
                |                                                           {$<plist>$ = NULL;funparams = $<plist>$;}
                ;

Param           : FType ID                                                   {$<plist>$=PInstall(NULL,$<tree>2->varname,ftype);}
                ;
LdeclBlock      : DECL LDecList ENDDECL                                     {    
                                                                                if(!installed){
                                                                                LPInstall(funparams);
                                                                                installed  = 1;
                                                                                } 
                                                                                // printf("Local symbol table \n");
                                                                                // printLtable();
                                                                                funparams = NULL;
                                                                            }
                | DECL ENDDECL                                              {   
                                                                                if(!installed){
                                                                                LPInstall(funparams);
                                                                                installed  = 1;
                                                                                }  
                                                                                // printf("Local symbol table \n");
                                                                                // printLtable();
                                                                                funparams = NULL;
                                                                            }
                |                                                           {}
                ;

LDecList        : LDecList LDecl                                            {}
                | LDecl                                                     {}
                ;

LDecl           : LType IdList ';'                           {}
                ;

IdList          : IdList ',' ID                             {
                                                              
                                                                LInstall(($<tree>3)->varname,ltype,0);
                                                                // printf("Found LocalId list \n");
                                                            }
                | ID                                        {
                                                                if(!installed){
                                                                    LPInstall(funparams);
                                                                    installed  = 1;
                                                                }
                                                                LInstall(($<tree>1)->varname,ltype,0);
                                                                // printf("Found Local Id\n");
                                                            }
                ;
Body            : START instructions RetStmt END            {
                                                                // printf("Found Body\n");
                                                                $<tree>$ = createTree(-1,_TYPELESS,"Stmnt",_CONNECTOR,$<tree>2,$<tree>3,NULL,NULL,NULL,NULL);
                                                                //  printf("Printin inorder ...\n");inorder($<tree>$);printf("\n");
                                                            }  
                | START RetStmt END                         {
                                                                // {printf("Found Body\n");
                                                                $<tree>$ = createTree(-1,_TYPELESS,"Stmnt",_CONNECTOR,NULL,$<tree>2,NULL,NULL,NULL,NULL);
                                                                // printf("Printin inorder ...\n");inorder($<tree>$);printf("\n");
                                                            }  
                                                            
                ;
MainBlock       : INT MAIN '(' ')' '{' LdeclBlock Body '}'  {
                                                                if(!initialized){
                                                                    init(output);
                                                                }
                                                                // printf("Found MainBlock\n");
                                                                // printf("Printing local table of main\n");
                                                                setLocalbinding();
                                                                // printLtable();
                                                                maingen($<tree>7,output);
                                                                Lstart = NULL;
                                                                installed = 0;
                                                         
                                                            }
                ;
RetStmt     	: RETURN expr ';'	                        {   
                                                                // printf("Found ret stmt\n");
                                                                $<tree>$ = createTree(-1,_TYPELESS,"RetStmt",_RETURN,$<tree>2,NULL,NULL,NULL,NULL,NULL);
                                                            }	
	            ;
FType           : INT                           {ftype = 0;}
                | STR                           {ftype = 1;}
                ;
Type            : INT                           {var_type = 0;}
                | STR                           {var_type = 1;}
                ;
LType           : INT                           {ltype = 0;}
                | STR                           {ltype = 1;}
                ;
ifstmt          : IF '(' expr ')' THEN instructions ELSE instructions ENDIF ';'  {  $<tree>$ = createTree(-1,_TYPELESS,"IFELSE",_IFELSE,$<tree>6,$<tree>8,$<tree>3,NULL,NULL,NULL);}
                | IF '(' expr ')' THEN instructions ENDIF ';'                    {$<tree>$ = createTree(-1,_TYPELESS,"IF",_IF,$<tree>6,NULL,$<tree>3,NULL,NULL,NULL);}                                                                     
                ;
whilestmt       : WHILE '(' expr ')' DO instructions ENDWHILE ';'                               { $<tree>$ = createTree(-1,_TYPELESS,"WHILE",_WHILE,$<tree>6,NULL,$<tree>3,NULL,NULL,NULL);}
                ;
instructions    : instructions stmt             {
                                                   
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Stmnt",_CONNECTOR,$<tree>1,$<tree>2,NULL,NULL,NULL,NULL);
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
                | ifstmt                        {
                                                    // printf("Found ifstmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | whilestmt                     {
                                                    // printf("Found whlestmt\n");
                                                    $<tree>$ = $<tree>1;
                                                }
                | BREAK ';'                     {
                                                    // printf("Found Breakstmt\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Break",_BREAK,NULL,NULL,NULL,NULL,NULL,NULL);
                                                }
                | CONTINUE ';'                     {
                                                    // printf("Found continue\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Continue",_CONTINUE,NULL,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
inputstmt       : READ '(' id ')' ';'           {
                                                    printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Read",_READ,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    // printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,_TYPELESS,"Write",_WRITE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
assignstmt      : id ASSIGN expr ';'            {
                                                    // printf("Found Assign\n");
                                                    if(($<tree>3->type==_STRING&&$<tree>1->Gentry->type==0)){
                                                         printf("Semantic error type mismatch assign statement\n");
                                                        exit(1);
                                                    }
                                                    
                                                    else {
                                                        $<tree>$ = createTree(-1,_TYPELESS,"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);

                                                    }
                                                    
                                                }
                ;
expr            : expr PLUS expr                {
                                                    // printf("PLUS\n");
                                                    $<tree>$ = createTree($<tree>1->val+$<tree>3->val,_INTEGER,"+",_PLUS,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MINUS expr               {
                                                    // printf("MINUS\n");
                                                    $<tree>$ = createTree($<tree>1->val-$<tree>3->val,_INTEGER,"-",_MINUS,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MUL expr                 {
                                                    // printf("MUL\n");
                                                    $<tree>$ = createTree($<tree>1->val*$<tree>3->val,_INTEGER,"*",_MUL,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr DIV expr                 {
                                                    // printf("DIV\n");
                                                    $<tree>$ = createTree($<tree>1->val/$<tree>3->val,_INTEGER,"/",_DIV,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MOD expr                 {
                                                    $<tree>$ = createTree($<tree>1->val%$<tree>3->val,_INTEGER,"%",_MOD,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LT expr                  {
                                                    // printf("LT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LT",_LT,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr GT expr                  {
                                                    // printf("GT\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GT",_GT,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                   typecheck($<tree>$);
                                                }
                | expr GTE expr                 {
                                                    // printf("GTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"GE",_GTE,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LTE expr                 {
                                                    // printf("LTE\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"LE",_LTE,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr EQ expr                  {
                                                    // printf("EQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"EQ",_EQ,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr NEQ expr                 {
                                                    // printf("NEQ\n");
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"NE",_NEQ,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr AND expr                 {
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"AND",_AND,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr OR expr                  {
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"AND",_AND,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | NOT expr                      {
                                                    $<tree>$ = createTree(-1,_BOOLEAN,"AND",_AND,$<tree>1,NULL,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | '(' expr ')'                  {
                                                    $<tree>$=$<tree>2;
                                                }
                | ID '(' ArgList ')'            {
                                                    
                                                    printArgs($<tree>3);
                                                    struct Gsymbol * temp = Lookup($<tree>1->varname);
                                                    if(temp==NULL){
                                                        printf("The function %s is not declared\n ",$<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    // if(!temp->defined){
                                                    //     printf("The function %s is not defined \n",temp->name);
                                                    //     exit(1);
                                                    // }
                                                    if(checkArgs($<tree>3,temp->plist)){
                                                       $<tree>$ = createTree(-1,temp->type,$<tree>1->varname,_FUNCTION,NULL,NULL,NULL,temp,NULL,$<tree>3);
                                                    }
                                                    else{
                                                        printf("Invalid arguments in the function call with %s",temp->name);
                                                        exit(1);
                                                    }
                                                }
                | NUM                           {
                                                    $<tree>$ = $<tree>1;
                                                }
                | STRING                        {
                                                    $<tree>$=$<tree>1;
                                                }
                | id                            {  $<tree>$ = $<tree>1;}
                ;
ArgList         : ArgList ',' expr              {$<tree>$ = appendArg($<tree>1,$<tree>3);}
                | expr                          {$<tree>$ = appendArg(NULL,$<tree>1);}
                |                               {$<tree>$ = NULL;}
                ;
id              : ID                            {
                                                    struct Lsymbol* temp = LocLookup(($<tree>1)->varname);
                                                     if(temp ==NULL){
                                                        struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                        if(temp ==NULL){
                                                            printf("Variable %s not declared\n", $<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        // printf("Variable %s in global\n",$<tree>1->varname);
                                                        $<tree>$ = createTree(-1,-1,$<tree>1->varname,_ID,NULL,NULL,NULL,temp,NULL,NULL);
                                                    }
                                                    else{
                                                    // printf("Variable %s in Local\n",$<tree>1->varname);
                                                    $<tree>$ = createTree(-1,-1,$<tree>1->varname,_ID,NULL,NULL,NULL,NULL,temp,NULL);
                                                    }
                                                }
                | ID'['expr']'                   {
                                                    struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                    if(temp==NULL){
                                                        printf("Variable %s not declared\n", $<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,-1,$<tree>1->varname,_ARR,$<tree>3,NULL,NULL,temp,NULL,NULL);
                                                }
                ;

%%

void yyerror(char const *s)
{
    printf("yyerror %s\n",s);
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
    output = fopen("output.xsm","w");
	if(!output){
		printf("Unable to open output file\n");
		exit(1);
	}
	yyparse();
    printTable();
    /* inorder(root); */
    /* codegen(root,output); */
   
    fclose(output);
	/* print(r,output); */
	return 0;
}