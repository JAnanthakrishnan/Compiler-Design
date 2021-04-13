%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "types.h" 
    #include "types.c"
    #include "codegen.c"
    extern FILE *yyin;
    struct Gsymbol* Gstart=NULL;
    struct Lsymbol* Lstart = NULL;
    struct Typetable *TypeTable = NULL;
    struct Fieldlist *FieldList = NULL;
    struct paramlist *funparams = NULL;
 	FILE *output;
    struct Typetable *var_type = NULL;
    struct Typetable *ftype = NULL;
    struct Typetable *ltype = NULL;
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
    struct Typetable *types;
    struct Filelist *fields;
}
%type <plist> Param ParamList FinalParamlist
%type <tree>  instructions stmt inputstmt outputstmt assignstmt expr ifstmt whilestmt
%type <types> TypeName
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID IF THEN ELSE ENDIF WHILE DO ENDWHILE DECL ENDDECL INT STR STRING MAIN RETURN TYPE ENDTYPE NULLTYPE ALLOC INITIALIZE FREE
%left AND OR NOT
%nonassoc LT GT LTE GTE EQ NEQ CONTINUE BREAK
%left PLUS MINUS
%left MOD
%left MUL DIV 


%%

Program         : TypeDefBlock GdeclBlock FDefBlock MainBlock    {}
                | TypeDefBlock GdeclBlock MainBlock              {}
                | TypeDefBlock MainBlock                        {}
                | GdeclBlock FDefBlock MainBlock    {}
                | GdeclBlock MainBlock              {}
                | MainBlock                         {}
                ;
TypeDefBlock    : TYPE TypeDefList ENDTYPE          {printTypeTable();}                               
                ;

TypeDefList     : TypeDefList TypeDef               {}
                | TypeDef                           {}
                ;

TypeDef         : ID {TInstall($<tree>1->varname,0,NULL);} '{' FieldDeclList '}'        {
                                                                                            struct Typetable *entry = TLookup($<tree>1->varname);
                                                                                            if(entry == NULL){
                                                                                                printf("The type %s is not declared in typedef\n",$<tree>1->varname);
                                                                                            }
                                                                                            entry->fields = FieldList;
                                                                                            entry->size = GetSize(entry);
                                                                                            FieldList = NULL;
                                                                                        }
                ;

FieldDeclList   : FieldDeclList FieldDecl           {}
                | FieldDecl                         {}
                ;

FieldDecl       : TypeName ID ';'                   {
                                                  
                                                        FInstall($<tree>2->varname,$<types>1);
                                                    }

TypeName        : INT                               {$<types>$ = TLookup("INT"); }
                | STR                               {$<types>$ = TLookup("STR");}
                | ID                                {
                                                        struct Typetable *entry = TLookup($<tree>1->varname);
                                                        if(entry == NULL){
                                                            printf("Type %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        $<types>$ = TLookup($<tree>1->varname);
                                                    }
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
                                                    GInstall(($<tree>1)->varname,var_type,((1)*(($<tree>3)->val)),NULL);}
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
                                                                $<tree>$ = createTree(-1,TLookup("VOID"),"Stmnt",_CONNECTOR,$<tree>2,$<tree>3,NULL,NULL,NULL,NULL);
                                                                //  printf("Printin inorder ...\n");inorder($<tree>$);printf("\n");
                                                            }  
                | START RetStmt END                         {
                                                                // {printf("Found Body\n");
                                                                $<tree>$ = createTree(-1,TLookup("VOID"),"Stmnt",_CONNECTOR,NULL,$<tree>2,NULL,NULL,NULL,NULL);
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
                                                                $<tree>$ = createTree(-1,TLookup("VOID"),"RetStmt",_RETURN,$<tree>2,NULL,NULL,NULL,NULL,NULL);
                                                            }	
	            ;
FType           : INT                               {ftype = TLookup("INT"); }
                | STR                               {ftype = TLookup("STR");}
                | ID                                {
                                                        struct Typetable *entry = TLookup($<tree>1->varname);
                                                        if(entry == NULL){
                                                            printf("Type %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        ftype = TLookup($<tree>1->varname);
                                                    }
                ;
Type            : INT                               {var_type = TLookup("INT"); }
                | STR                               {var_type = TLookup("STR");}
                | ID                                {
                                                        struct Typetable *entry = TLookup($<tree>1->varname);
                                                        if(entry == NULL){
                                                            printf("Type %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        var_type = TLookup($<tree>1->varname);
                                                    }
                ;
LType           : INT                               {ltype = TLookup("INT"); }
                | STR                               {ltype = TLookup("STR");}
                | ID                                {
                                                        struct Typetable *entry = TLookup($<tree>1->varname);
                                                        if(entry == NULL){
                                                            printf("Type %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        ltype = TLookup($<tree>1->varname);
                                                    }
                ;
ifstmt          : IF '(' expr ')' THEN instructions ELSE instructions ENDIF ';'  {  $<tree>$ = createTree(-1,TLookup("VOID"),"IFELSE",_IFELSE,$<tree>6,$<tree>8,$<tree>3,NULL,NULL,NULL);}
                | IF '(' expr ')' THEN instructions ENDIF ';'                    {$<tree>$ = createTree(-1,TLookup("VOID"),"IF",_IF,$<tree>6,NULL,$<tree>3,NULL,NULL,NULL);}                                                                     
                ;
whilestmt       : WHILE '(' expr ')' DO instructions ENDWHILE ';'                               { $<tree>$ = createTree(-1,TLookup("VOID"),"WHILE",_WHILE,$<tree>6,NULL,$<tree>3,NULL,NULL,NULL);}
                ;
instructions    : instructions stmt             {
                                                   
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Stmnt",_CONNECTOR,$<tree>1,$<tree>2,NULL,NULL,NULL,NULL);
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
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Break",_BREAK,NULL,NULL,NULL,NULL,NULL,NULL);
                                                }
                | CONTINUE ';'                     {
                                                    // printf("Found continue\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Continue",_CONTINUE,NULL,NULL,NULL,NULL,NULL,NULL);
                                                }
                | FREE  '(' id ')' ';'          {
                                                    if($<tree>3->type->fields==NULL){
                                                        printf("%s is not a record type\n",$<tree>3->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                | FREE '(' Field ')' ';'        {
                                                    if($<tree>3->type->fields==NULL){
                                                        printf("%s is not a record type\n",$<tree>3->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
inputstmt       : READ '(' id ')' ';'           {
                                                    printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Read",_READ,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    // printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Write",_WRITE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
assignstmt      : id ASSIGN expr ';'            {
                                                        if($<tree>3->nodetype==_NULLTYPE){
                                                            if($<tree>1->type->fields==NULL){
                                                                printf("%s is not a record type\n",$<tree>1->varname);
                                                                exit(1);
                                                            }
                                                        }
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    
                                                }
                | Field ASSIGN expr ';'             {
                                                        if($<tree>3->nodetype==_NULLTYPE){
                                                            if($<tree>1->type->fields==NULL){
                                                                printf("%s is not a record type\n",$<tree>1->varname);
                                                                exit(1);
                                                            }
                                                        }
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | id ASSIGN ALLOC '(' ')' ';'       {
                                                        if($<tree>1->type->fields==NULL){
                                                            printf("%s is not a record type\n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | Field ASSIGN ALLOC '(' ')' ';'    {
                                                         
                                                        if($<tree>1->type->fields==NULL){
                                                            printf("%s is not a record type\n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | id ASSIGN INITIALIZE '(' ')' ';'  {
                                                        
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                ;
expr            : expr PLUS expr                {
                                                    // printf("PLUS\n");
                                                    $<tree>$ = createTree($<tree>1->val+$<tree>3->val,TLookup("INT"),"+",_PLUS,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MINUS expr               {
                                                    // printf("MINUS\n");
                                                    $<tree>$ = createTree($<tree>1->val-$<tree>3->val,TLookup("INT"),"-",_MINUS,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MUL expr                 {
                                                    // printf("MUL\n");
                                                    $<tree>$ = createTree($<tree>1->val*$<tree>3->val,TLookup("INT"),"*",_MUL,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr DIV expr                 {
                                                    // printf("DIV\n");
                                                    $<tree>$ = createTree($<tree>1->val/$<tree>3->val,TLookup("INT"),"/",_DIV,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr MOD expr                 {
                                                    $<tree>$ = createTree($<tree>1->val%$<tree>3->val,TLookup("INT"),"%",_MOD,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LT expr                  {
                                                    // printf("LT\n");
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"LT",_LT,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr GT expr                  {
                                                    // printf("GT\n");
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"GT",_GT,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                   typecheck($<tree>$);
                                                }
                | expr GTE expr                 {
                                                    // printf("GTE\n");
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"GE",_GTE,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr LTE expr                 {
                                                    // printf("LTE\n");
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"LE",_LTE,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr EQ expr                  {
                                                    if($<tree>3->nodetype==_NULLTYPE){
                                                        if($<tree>1->type->fields==NULL){
                                                            printf("%s is not a record type\n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"EQ",_EQ,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr NEQ expr                 {
                                                    if($<tree>3->nodetype==_NULLTYPE){
                                                        if($<tree>1->type->fields==NULL){
                                                            printf("%s is not a record type\n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"NE",_NEQ,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr AND expr                 {
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"AND",_AND,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr OR expr                  {
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"AND",_AND,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | NOT expr                      {
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"AND",_AND,$<tree>1,NULL,NULL,NULL,NULL,NULL);
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
                | id                            {  $<tree>$ = $<tree>1; }
                | Field                         {  $<tree>$ = $<tree>1; }
                | NULLTYPE                      {  $<tree>$ = $<tree>1; }
                ;
Field           : Field '.' ID                 {
                                                    // char *f0 = (char *)malloc(sizeof($<tree>1->varname));
                                                    // strcpy(f0,$<tree>1->varname);
                                                    // char *f1 = strcat(f0,".");
                                                    // char *f2 = strcat(f1,$<tree>3->varname);
                                                    // printf("The Field in field.id is %s\n",$<tree>1->varname);
                                                    struct tnode *t = $<tree>1;
                                                    while(t->right->nodetype==_FIELD){
                                                        t = t->right;
                                                    }
                                                    struct Fieldlist *fld = FLookup(t->type,$<tree>3->varname);
                                                    if(fld==NULL){
                                                        printf("Field %s is not in record %s\n",$<tree>3->varname,t->varname);
                                                        exit(1);
                                                    }
                                                    // $<tree>1->Lentry = t->Lentry;
                                                    // $<tree>1->Gentry = t->Gentry;
                                                    // $<tree>$ = createTree(-1,fld->type,f2,_FIELD,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    $<tree>3->type = fld->type;
                                                    t->right->Gentry = $<tree>1->left->Gentry;
                                                    t->right->Lentry = $<tree>1->left->Lentry;
                                                    struct tnode *newnode = createTree(-1,fld->type,"Field",_FIELD,t->right,$<tree>3,NULL,NULL,NULL,NULL); 
                                                    t->right = newnode;
                                                    $<tree>$ = $<tree>1;

                                                }
                | ID '.' ID                    {
                    
                                                    struct Typetable *currType = NULL;
                                                    struct Lsymbol* temp = LocLookup(($<tree>1)->varname);
                                                     if(temp ==NULL){
                                                        struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                        if(temp ==NULL){
                                                            printf("Variable %s not declared\n", $<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        // printf("Variable %s in global\n",$<tree>1->varname);
                                                        $<tree>1->Gentry = temp;
                                                        $<tree>1->type = temp->type;
                                                        currType = temp->type;
                                                    }
                                                    else{
                                                    // printf("Variable %s in Local\n",$<tree>1->varname);
                                                    $<tree>1->Lentry = temp;
                                                    $<tree>1->type = temp->type;
                                                    currType = temp->type;
                                                    }
                                                    if(currType->fields==NULL){
                                                        printf("%s is not a record\n",$<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    struct Fieldlist *fld = FLookup(currType,$<tree>3->varname);
                                                    if(fld==NULL){
                                                        printf("Field %s is not in record %s\n",$<tree>3->varname,$<tree>1->varname);
                                                        exit(1);
                                                    } 
                                                    char *f0 = (char *)malloc(sizeof($<tree>1->varname));
                                                    strcpy(f0,$<tree>1->varname);
                                                    char *f1 = strcat(f0,".");
                                                    char *f2 = strcat(f1,$<tree>3->varname);
                                                    $<tree>3->type = fld->type;
                                                    $<tree>$ = createTree(-1,fld->type,f2,_FIELD,$<tree>1,$<tree>3,NULL,$<tree>1->Gentry,$<tree>1->Lentry,NULL);

                                                }
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
                                                        $<tree>$ = createTree(-1,temp->type,$<tree>1->varname,_ID,NULL,NULL,NULL,temp,NULL,NULL);
                                                    }
                                                    else{
                                                    // printf("Variable %s in Local\n",$<tree>1->varname);
                                                    $<tree>$ = createTree(-1,temp->type,$<tree>1->varname,_ID,NULL,NULL,NULL,NULL,temp,NULL);
                                                    }
                                                }
                | ID'['expr']'                   {
                                                    struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                    if(temp==NULL){
                                                        printf("Variable %s not declared\n", $<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,temp->type,$<tree>1->varname,_ARR,$<tree>3,NULL,NULL,temp,NULL,NULL);
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
    TypeTableCreate();
	yyparse();
    printTable();
    /* inorder(root); */
    /* codegen(root,output); */
   
    fclose(output);
	/* print(r,output); */
	return 0;
}