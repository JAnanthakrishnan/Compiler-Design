%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "class.h" 
    #include "class.c"
    #include "codegen.c"
    extern FILE *yyin;
    int oexpl = 0;
    struct Gsymbol* Gstart=NULL;
    struct Lsymbol* Lstart = NULL;
    struct Typetable *TypeTable = NULL;
    struct Fieldlist *FieldList = NULL;
    struct paramlist *funparams = NULL;
    int bindingStart = 0;
 	FILE *output;
    struct Typetable *var_type = NULL;
    struct Typetable *ftype = NULL;
    struct Typetable *ltype = NULL;
    struct Typetable *ctype = NULL;
    struct Classtable *ClassTable = NULL;
    struct Classtable *cptr = NULL;
    struct Classtable *classentry = NULL;
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
    struct Classtable *classname;
}
%type <plist> Param ParamList FinalParamlist
%type <tree>  instructions stmt inputstmt outputstmt assignstmt expr ifstmt whilestmt
%type <types> TypeName ClassType
%token START END WRITE READ ASSIGN PLUS MINUS MUL DIV NUM ID IF THEN ELSE ENDIF WHILE DO ENDWHILE DECL ENDDECL INT STR STRING MAIN RETURN TYPE ENDTYPE NULLTYPE ALLOC INITIALIZE FREE CLASS ENDCLASS Extends SELF NEW DELETE
%left AND OR NOT
%nonassoc LT GT LTE GTE EQ NEQ CONTINUE BREAK
%left PLUS MINUS
%left MOD
%left MUL DIV 


%%

Program         : TypeDefBlock ClassDefBlock FDefBlock MainBlock    {}
                | TypeDefBlock ClassDefBlock                        {}
                | ClassDefBlock                                     {}
                | ClassDefBlock FDefBlock MainBlock                 {}
                | ClassDefBlock GdeclBlock MainBlock                {}
                | TypeDefBlock ClassDefBlock MainBlock              {}
                | TypeDefBlock ClassDefBlock GdeclBlock MainBlock   {}
                | TypeDefBlock GdeclBlock FDefBlock MainBlock       {}
                | TypeDefBlock GdeclBlock MainBlock                 {}
                | TypeDefBlock MainBlock                            {}
                | GdeclBlock FDefBlock MainBlock                    {}
                | GdeclBlock MainBlock                              {}
                | MainBlock                                         {}
                ;
ClassDefBlock   : CLASS ClassDefList ENDCLASS       {
                                                        char ch;
                                                        fclose(output);
                                                        output = fopen("preinitial.xsm","w");
                                                        init(output);
                                                        fclose(output);
                                                        oexpl = 1;
                                                    }
                ;
ClassDefList    : ClassDefList ClassDef             {}
                | ClassDef                          {}
                ;
ClassDef        : Cname {cptr=CLookup($<classname>1->name); } ClassBody {   
                                                                            cptr = NULL;
                                                                        }
                ;
ClassBody       : '{' DECL MFieldList MethodDecl ENDDECL MethodDefns '}'  {}
                | '{' DECL MethodDecl ENDDECL MethodDefns '}'             {}
Cname           : ID                                {$<classname>$ = CInstall($<tree>1->varname,NULL); }
                | ID  Extends ID                    {$<classname>$ = CInstall($<tree>1->varname,$<tree>3->varname);}
                ;
MFieldList      : MFieldList MFld                   {}
                | MFld                              {}
                ;
MFld            : ClassType ID ';'                  {Class_Finstall(cptr,classentry,$<types>1,$<tree>2->varname); }
                ;
MethodDecl      : MethodDecl MDecl                  {}
                | MDecl                             {}
                ;
MDecl           : ClassType ID '(' ParamList ')' ';'   {Class_Minstall(cptr,$<tree>2->varname,$<types>1,$<plist>4);}
                ;
ClassType       : INT                               {$<types>$ = TLookup("INT"); }
                | STR                               {$<types>$ = TLookup("STR");}
                | ID                                {
                                                        struct Typetable *entry = TLookup($<tree>1->varname);
                                                        struct Classtable *tmp = CLookup($<tree>1->varname);
                                                        if(entry == NULL&&tmp==NULL){
                                                            printf("Type or class %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        if(entry!=NULL)
                                                            $<types>$ = TLookup($<tree>1->varname);
                                                        else 
                                                            classentry = tmp;
                                                    }
                ;
MethodDefns     : MethodDefns Fdef                  {}
                | Fdef                              {}  
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
                                                                                                exit(1);
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
GdeclBlock      : DECL GdeclList ENDDECL            {
                                                        initialized = 1;
                                                        if(oexpl==0){
                                                            output = fopen("output.xsm","w");
                                                            initExpl(output);
                                                            fclose(output);
                                                            output = fopen("output.xsm","a");
                                                        }
                                                        else{
                                                        Organize("output.xsm","preinitial.xsm");
                                                        output = fopen("output.xsm","a");
                                                        initGlobal(output);
                                                        fclose(output);
                                                        Organize("output.xsm","initial.xsm");
                                                        output = fopen("output.xsm","a");
                                                        }
                                                        // printf("Found GdeclBlock\n");
                                                    }
                | DECL ENDDECL                      {   
                                                        initialized = 1;
                                                        Organize("output.xsm","preinitial.xsm");
                                                        output = fopen("output.xsm","a");
                                                        initGlobal(output);
                                                        fclose(output);
                                                        Organize("output.xsm","initial.xsm");
                                                        output = fopen("output.xsm","a");
                                                        // printf("Found GdeclBlock\n");
                                                    }
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
                                                    int size = 1;
                                                    if(classentry!=NULL)
                                                        size = 2;
                                                    GInstall(($<tree>1)->varname,var_type,classentry,size,NULL);
                                                    classentry = NULL;
                                                    }
                | ID '[' NUM ']'                    {
                                                    int size = 1;
                                                    if(classentry!=NULL)
                                                        size = 2;
                                                    GInstall(($<tree>1)->varname,var_type,classentry,((1)*(($<tree>3)->val)),NULL);
                                                    classentry = NULL;
                                                    }
                | ID '(' ParamList ')'              {
                                                    int size = 1;
                                                    if(classentry!=NULL)
                                                        size = 2;
                                                    GInstall(($<tree>1)->varname,var_type,classentry,0,$<plist>3);
                                                    classentry = NULL;
                                                    }
                ;
FDefBlock       : FDefBlock Fdef                    {}
                | Fdef                              {}
                ;

Fdef            : Type ID '(' FinalParamlist ')' '{' LdeclBlock Body '}'        {
                                                                                int flag = 0;
                                                                                struct Gsymbol* temp = Lookup(($<tree>2)->varname);
                                                                                struct Memberfunclist *temp2 = Class_Mlookup(cptr,$<tree>2->varname);
                                                                                if(temp == NULL&&temp2==NULL){
                                                                                    printf("Function %s is not declared\n",$<tree>2->varname);
                                                                                    exit(1);
                                                                                }
                                                                               
                                                                                if(temp!=NULL){
                                                                                    if(temp->defined == 1){
                                                                                    printf("Function %s is already defined\n",temp->name);
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
                                                                                }
                                                                                if(temp2!=NULL){
                                                                                    if(temp2->type!=var_type){
                                                                                        printf("Mismatch in return type of function definition of %s\n",temp2->name);
                                                                                        exit(1);

                                                                                    }
                                                                                    int res = nameEquivalence($<plist>4,temp2->paramlist);
                                                                                    if(res==0){
                                                                                        printf("Mismatch in argument types in definition of function %s\n",temp2->name);
                                                                                        exit(1);
                                                                                    }
                                                                                    if(var_type!=temp2->type){
                                                                                        printf("Mismatch in return type in definition of function %s\n",temp2->name);
                                                                                        exit(1);
                                                                                    }
                                                                                }
                                                                                if(temp!=NULL){
                                                                                    temp->defined = 1;
                                                                                }
                                                                                setLocalbinding();                        
                                                                                calleegen($<tree>8,output,temp,temp2);
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
                                                                                funparams = NULL;
                                                                            }
                | DECL ENDDECL                                              {   
                                                                                if(!installed){
                                                                                LPInstall(funparams);
                                                                                installed  = 1;
                                                                                }                                                                                   
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
                                                            }
                | ID                                        {
                                                                if(!installed){
                                                                    LPInstall(funparams);
                                                                    installed  = 1;
                                                                }
                                                                LInstall(($<tree>1)->varname,ltype,0);
                                                            }
                ;
Body            : START instructions RetStmt END            {
                                                                $<tree>$ = createTree(-1,TLookup("VOID"),"Stmnt",_CONNECTOR,$<tree>2,$<tree>3,NULL,NULL,NULL,NULL);
                                                            }  
                | START RetStmt END                         {
                                                                $<tree>$ = createTree(-1,TLookup("VOID"),"Stmnt",_CONNECTOR,NULL,$<tree>2,NULL,NULL,NULL,NULL);
                                                            }  
                                                            
                ;
MainBlock       : INT MAIN '(' ')' '{' LdeclBlock Body '}'  {
                                                                if(!initialized){
                                                                    initialized = 1;
                                                                    Organize("output.xsm","preinitial.xsm");
                                                                    output = fopen("output.xsm","a");
                                                                    initGlobal(output);
                                                                    fclose(output);
                                                                    Organize("output.xsm","initial.xsm");
                                                                    output = fopen("output.xsm","a");
                                                                    printf("Found GdeclBlock\n");
                                                                }
                                                                setLocalbinding();
                                                                maingen($<tree>7,output);
                                                                Lstart = NULL;
                                                                installed = 0;
                                                         
                                                            }
                ;
RetStmt     	: RETURN expr ';'	                        {   
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
                                                        struct Classtable *centry = CLookup($<tree>1->varname);
                                                        if(entry == NULL&&centry==NULL){
                                                            printf("Type or Class %s not declared \n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        var_type = TLookup($<tree>1->varname);
                                                        classentry = CLookup($<tree>1->varname);
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
                                                        // printf("%s is not a record type\n",$<tree>3->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                | FREE '(' Field ')' ';'        {
                                                    if($<tree>3->type->fields==NULL){
                                                        // printf("%s is not a record type\n",$<tree>3->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                | DELETE  '(' id ')' ';'        {
                                                    
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                | DELETE  '(' Field ')' ';'     {
                                                    
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FREE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
inputstmt       : READ '(' id ')' ';'           {
                                                    // printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Read",_READ,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                | READ '(' Field ')' ';'        {
                                                    // printf("Found Read\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Read",_READ,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
outputstmt      : WRITE '(' expr ')' ';'          {
                                                    // printf("Found Write\n");
                                                    $<tree>$ = createTree(-1,TLookup("VOID"),"Write",_WRITE,$<tree>3,NULL,NULL,NULL,NULL,NULL);
                                                }
                ;
assignstmt      : id ASSIGN expr ';'            {
                                                        // if($<tree>3->nodetype==_NULLTYPE){
                                                        //     if($<tree>1->type->fields==NULL){
                                                        //         printf("%s is not a record type\n",$<tree>1->varname);
                                                        //         exit(1);
                                                        //     }
                                                        // }
                                                        // printf("Type is %d\n",$<tree>3->nodetype);
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    
                                                }
                | Field ASSIGN expr ';'             {
                                                        // if($<tree>3->nodetype==_NULLTYPE){
                                                        //     if($<tree>1->type->fields==NULL){
                                                        //         printf("%s is not a record type\n",$<tree>1->varname);
                                                        //         exit(1);
                                                        //     }
                                                        // }
                                                        // printf("Type is %d\n",$<tree>3->nodetype);
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | id ASSIGN ALLOC '(' ')' ';'       {
                                                        // if($<tree>1->type->fields==NULL){
                                                        //     printf("%s is not a record type\n",$<tree>1->varname);
                                                        //     exit(1);
                                                        // }
                                                        
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | Field ASSIGN ALLOC '(' ')' ';'    {
                                                         
                                                        // if($<tree>1->type->fields==NULL){
                                                        //     printf("%s is not a record type\n",$<tree>1->varname);
                                                        //     exit(1);
                                                        // }
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | id ASSIGN INITIALIZE '(' ')' ';'  {
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
          
                | Field ASSIGN NEW '(' ID ')' ';'   {
                                                        printf("The field classname is %s\n",$<tree>1->Ctype);
                                                        struct Classtable *temp = CLookup($<tree>5->varname);
                                                        if(temp==NULL){
                                                            printf("Class %s is not defined \n",$<tree>5->varname);
                                                            exit(1);
                                                        }
                                                        checkInherited($<tree>1->Ctype,temp);
                                                        $<tree>5->Ctype = temp;
                                                        $<tree>3->left = $<tree>5;
                                                        $<tree>$ = createTree(-1,TLookup("VOID"),"=",_ASSIGN,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    }
                | id ASSIGN NEW '(' ID ')' ';'      {  
                                                        // printf("From here\n"); 
                                                        struct Classtable *t1 = $<tree>1->Ctype;
                                                        struct Classtable *temp = CLookup($<tree>5->varname);
                                                        if(temp==NULL){
                                                            printf("Class %s is not defined \n",$<tree>5->varname);
                                                            exit(1);
                                                        }
                                                        checkInherited(t1,temp);
                                                        $<tree>5->Ctype = temp;
                                                        $<tree>3->left = $<tree>5;
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
                                                    // if($<tree>3->nodetype==_NULLTYPE){
                                                    //     if($<tree>1->type->fields==NULL){
                                                    //         printf("%s is not a record type\n",$<tree>1->varname);
                                                    //         exit(1);
                                                    //     }
                                                    // }
                                                    $<tree>$ = createTree(-1,TLookup("BOOL"),"EQ",_EQ,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);
                                                    typecheck($<tree>$);
                                                }
                | expr NEQ expr                 {
                                                    // if($<tree>3->nodetype==_NULLTYPE){
                                                    //     if($<tree>1->type->fields==NULL){
                                                    //         printf("%s is not a record type\n",$<tree>1->varname);
                                                    //         exit(1);
                                                    //     }
                                                    // }
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
                                                    
                                                    // printArgs($<tree>3);
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
                | FieldFunction                 {  $<tree>$ = $<tree>1; }
                | NULLTYPE                      {  $<tree>$ = $<tree>1; }
                ;
Field           : SELF '.' ID                   {
                                                    if(cptr == NULL){
                                                        printf("Self can be used only inside a class\n");
                                                        exit(1);
                                                    }
                                                    $<tree>1->Ctype = cptr;
                                                    struct Memberfieldlist *mfld = Class_Flookup(cptr,$<tree>3->varname);
                                                    if(mfld == NULL){
                                                        printf("%s is not part of the class %s\n",$<tree>3->varname,cptr->name);
                                                        exit(1);
                                                    }
                                                    $<tree>1->Lentry = LocLookup("SELF");
                                                    $<tree>1->Ctype = cptr;
                                                    $<tree>3->Ctype = mfld->Ctype;
                                                    $<tree>3->type = mfld->type;
                                                    char *f0 = (char *)malloc(sizeof($<tree>1->varname));
                                                    strcpy(f0,$<tree>1->varname);
                                                    char *f1 = strcat(f0,".");
                                                    char *f2 = strcat(f1,$<tree>3->varname);
                                                    $<tree>$ = createTree(-1,mfld->type,f2,_FIELD,$<tree>1,$<tree>3,NULL,NULL,NULL,NULL);     
                                                    if(mfld!=NULL)  
                                                    $<tree>$->Ctype = mfld->Ctype;                                             
                                                }
                | Field '.' ID                  {
                                                    struct tnode *t = $<tree>1;
                                                    while(t->right->nodetype==_FIELD){
                                                        t = t->right;
                                                    }
                                                    struct Fieldlist *fld = FLookup(t->type,$<tree>3->varname);
                                                    struct Memberfieldlist *mfld = Class_Flookup(t->Ctype,$<tree>3->varname);
                                                    if(fld==NULL&&mfld==NULL){
                                                        printf("Field %s is not in record or class %s\n",$<tree>3->varname,t->varname);
                                                        exit(1);
                                                    }
                                                    t->right->Gentry = $<tree>1->left->Gentry;
                                                    t->right->Lentry = $<tree>1->left->Lentry;
                                                    if(fld!=NULL){
                                                        $<tree>3->type = fld->type;
                                                        struct tnode *newnode = createTree(-1,fld->type,"Field",_FIELD,t->right,$<tree>3,NULL,NULL,NULL,NULL); 
                                                        t->right = newnode;
                                                        $<tree>$ = $<tree>1;
                                                    }
                                                    else{
                                                        $<tree>3->Ctype = mfld->Ctype;
                                                        struct tnode *newnode = createTree(-1,mfld->type,"Field",_FIELD,t->right,$<tree>3,NULL,NULL,NULL,NULL); 
                                                        t->right = newnode;
                                                        $<tree>$ = $<tree>1;
                                                    }
                                                    if(mfld!=NULL)
                                                    $<tree>$->Ctype = mfld->Ctype;

                                                }
                | ID '.' ID                     {
                    
                                                    struct Typetable *currType = NULL;
                                                    struct Classtable *currClass = NULL;
                                                    struct Lsymbol* temp = LocLookup(($<tree>1)->varname);
                                                    if(temp ==NULL){
                                                        struct Gsymbol* temp = Lookup(($<tree>1)->varname);
                                                        if(temp ==NULL){
                                                            printf("Variable %s not declared\n", $<tree>1->varname);
                                                            exit(1);
                                                        }
                                                        $<tree>1->Gentry = temp;
                                                        $<tree>1->type = temp->type;
                                                        currType = temp->type;
                                                        currClass = temp->Ctype;
                                                    }
                                                    else{
                                                    $<tree>1->Lentry = temp;
                                                    $<tree>1->type = temp->type;
                                                    currType = temp->type;
                                                    }
                                                    if(currType->fields==NULL&&currClass==NULL){
                                                        printf("%s is not a record or class\n",$<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    struct Fieldlist *fld = FLookup(currType,$<tree>3->varname);
                                                    struct Memberfieldlist *mfld = Class_Flookup(currClass,$<tree>3->varname);
                                                    if(fld==NULL && mfld==NULL){
                                                        printf("Field %s is not in record or class %s\n",$<tree>3->varname,$<tree>1->varname);
                                                        exit(1);
                                                    } 
                                                    char *f0 = (char *)malloc(sizeof($<tree>1->varname));
                                                    strcpy(f0,$<tree>1->varname);
                                                    char *f1 = strcat(f0,".");
                                                    char *f2 = strcat(f1,$<tree>3->varname);
                                                    $<tree>3->Ctype = currClass;
                                                    if(fld!=NULL)
                                                    {
                                                        $<tree>3->type = fld->type;
                                                        $<tree>$ = createTree(-1,fld->type,f2,_FIELD,$<tree>1,$<tree>3,NULL,$<tree>1->Gentry,$<tree>1->Lentry,NULL);

                                                    }
                                                    else {
                                                        $<tree>3->type = mfld->type;
                                                        $<tree>$ = createTree(-1,mfld->type,f2,_FIELD,$<tree>1,$<tree>3,NULL,$<tree>1->Gentry,$<tree>1->Lentry,NULL);
                                                    }
                                                    if(mfld!=NULL)
                                                    $<tree>$->Ctype = mfld->Ctype;
                                                }
                ;
FieldFunction   : SELF '.' ID '(' ArgList ')'   {
                                                    // printf("Found SELF.%s\n",$<tree>3->varname);
                                                    // printArgs($<tree>5);
                                                    if(cptr==NULL){
                                                        printf("SELF can be used only inside a class\n");
                                                        exit(1);
                                                    }
                                                    struct Memberfunclist * temp = Class_Mlookup(cptr,$<tree>3->varname);
                                                    if(temp==NULL){
                                                        printf("The function %s is not declared in %s\n ",$<tree>3->varname,cptr->name);
                                                        exit(1);
                                                    }
                                                    // printf("Local symbol table \n");
                                                    $<tree>1->Lentry = LocLookup("SELF");
                                                    $<tree>1->Ctype = cptr;
                                                    $<tree>3->nodetype = _FUNCTION;
                                                    if(checkArgs($<tree>5,temp->paramlist)){
                                                       $<tree>$ = createTree(-1,TLookup("VOID"),$<tree>3->varname,_FIELDFUN,$<tree>1,$<tree>3,NULL,NULL,NULL,$<tree>5);
                                                    }
                                                    else{
                                                        printf("Invalid arguments in the function call with %s",temp->name);
                                                        exit(1);
                                                    }

                                                }
                | ID '.' ID '(' ArgList ')'     {
                                                    // printArgs($<tree>5);
                                                    struct Gsymbol * temp = Lookup($<tree>1->varname);
                                                    if(temp==NULL){
                                                        printf("The variable %s is not declared\n ",$<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    else{
                                                        if(temp->Ctype==NULL){
                                                            printf("%s is not a class\n",$<tree>1->varname);
                                                            exit(1);
                                                        }
                                                    }

                                                    struct Memberfunclist *memfun = Class_Mlookup(temp->Ctype,$<tree>3->varname);
                                                    if(memfun==NULL){
                                                        printf("The function %s is not declared in %s\n ",$<tree>3->varname,$<tree>1->varname);
                                                        exit(1);
                                                    }
                                                    
                                                    $<tree>1->Ctype = temp->Ctype;
                                                    $<tree>1->Gentry = Lookup($<tree>1->varname);

                                                    $<tree>3->nodetype = _FUNCTION;
                                                    if(checkArgs($<tree>5,memfun->paramlist)){
                                                       $<tree>$ = createTree(-1,memfun->type,$<tree>3->varname,_FIELDFUN,$<tree>1,$<tree>3,NULL,NULL,NULL,$<tree>5);
                                                       $<tree>$->Gentry = Lookup($<tree>1->varname);
                                                    }
                                                    else{
                                                        printf("Invalid arguments in the function call with %s",memfun->name);
                                                        exit(1);
                                                    }

                                                }
                | Field '.' ID '(' ArgList ')'  {
                                                    printf("The field is %s\n",$<tree>1->varname);
                                                    
                                                    struct tnode *temp = $<tree>1;
                                                    while(temp->right!=NULL){
                                                        temp = temp->right;
                                                    }
                                                    //    printf("The right is %s\n",temp->varname);
                                                    if(temp->Ctype==NULL){
                                                        printf("%s is not a class object\n",temp->varname);
                                                        exit(1);
                                                    }

                                                    printf("The class name is %s\n",temp->Ctype->name);
                                                    struct Memberfunclist *memfun = Class_Mlookup(temp->Ctype,$<tree>3->varname);
                                                    if(memfun==NULL){
                                                        printf("The function %s is not declared in %s\n ",$<tree>3->varname,temp->varname);
                                                        exit(1);
                                                    }
                                                    $<tree>3->nodetype = _FUNCTION;
                                                    if(checkArgs($<tree>5,memfun->paramlist)){
                                                       $<tree>$ = createTree(-1,memfun->type,$<tree>3->varname,_FIELDFUN,$<tree>1,$<tree>3,NULL,NULL,NULL,$<tree>5);
                                                    }
                                                    else{
                                                        printf("Invalid arguments in the function call with %s",memfun->name);
                                                        exit(1);
                                                    }

                                                }
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
                                                        $<tree>$ = createTree(-1,temp->type,$<tree>1->varname,_ID,NULL,NULL,NULL,temp,NULL,NULL);
                                                        $<tree>$->Ctype = temp->Ctype;
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
    fclose(output);
    output = fopen("initial.xsm","w");
	if(!output){
		printf("Unable to open output file\n");
		exit(1);
	}
    TypeTableCreate();
	yyparse();
    /* printf("-----The Global symbol table-----\n");
    printTable(); */
    /* inorder(root); */
    /* codegen(root,output); */
    green();
    printf("Success.......\n");
    yellow();
    printf("Code generated in output.xsm\n");
    reset();
    fclose(output);
	/* print(r,output); */
	return 0;
}