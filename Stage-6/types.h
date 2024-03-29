#define _PLUS 1
#define _MINUS 2
#define _MUL 3
#define _DIV 4
#define _ASSIGN 5
#define _READ 6
#define _WRITE 7
#define _CONNECTOR 8
#define _INTEGER 9
#define _BOOLEAN 10
#define _TYPELESS 11
#define _ID 12
#define _NUM 13
#define _LT 14
#define _GT 15
#define _EQ 16
#define _NEQ 17
#define _GTE 18
#define _LTE 19
#define _IFELSE 20
#define _IF 21
#define _WHILE 22
#define _WHILE_BREAK 23
#define _WHILE_CONTINUE 24
#define _BREAK 25
#define _CONTINUE 26
#define _STRING 27
#define _ARR 28
#define _MOD 29
#define _FUNCTION 30
#define _ARGLIST 31
#define _RETURN 32
#define _AND 33
#define _NOT 34
#define _OR 35
#define _FIELD 36
#define _NULLTYPE 37
#define _ALLOC 38
#define _INITIALIZE 39
#define _FREE 40

void yyerror(char const *s);

union Constant
{
    int intval;
    char *strval;
};

typedef struct tnode
{
    int val;                    // value of a number for NUM nodes.
    struct Typetable *type;     //type of variable
    char *varname;              //name of a variable for ID nodes
    union Constant value;       //stores the value of the constant if the node corresponds to a constant
    int nodetype;               // information about non-leaf nodes - read/write/connector/+/* etc.
    struct tnode *arglist;      // pointer to the expression list given as arguments to a function call
    struct tnode *left, *right; //left and right branches
    struct Gsymbol *Gentry;     //Pointer to entry in Global symbol table
    struct Lsymbol *Lentry;     //Pointer to entry in Local symbol table
    struct tnode *middle;
} tnode;

typedef struct Gsymbol
{
    char *name;             // name of the variable
    struct Typetable *type; // type of the variable
    int size;               // size of the type of the variable
    int binding;            // stores the static memory address allocated to the variable
    int value;
    struct paramlist *plist; //pointer to the head of the formal parameter list
                             //in the case of functions
    int flabel;              //a label for identifying the starting address of a function's code
    int defined;
    struct Gsymbol *next;
} Gsymbol;

typedef struct Lsymbol
{
    char *name;
    //name of the variable
    struct Typetable *type;
    //type of the variable:(Integer / String)
    int binding;
    //local binding of the variable
    int isArg;
    // to check whether the entry is an argument
    struct Lsymbol *next;
    //points to the next Local Symbol Table entry
} Lsymbol;

typedef struct paramlist
{
    char *name;
    struct Typetable *type;
    struct paramlist *next;
} paramlist;

typedef struct Typetable
{
    char *name;               //type name
    int size;                 //size of the type
    struct Fieldlist *fields; //pointer to the head of fields list
    struct Typetable *next;   // pointer to the next type table entry
} Typetable;

typedef struct Fieldlist
{
    char *name;             //name of the field
    int fieldIndex;         //the position of the field in the field list
    struct Typetable *type; //pointer to type table entry of the field's type
    struct Fieldlist *next; //pointer to the next field
} Fieldlist;

/*----------------Create a node tnode--------------------*/

struct tnode *createTree(int val, struct Typetable *type, char *c, int nodetype, struct tnode *l, struct tnode *r, struct tnode *middle, struct Gsymbol *Gentry, struct Lsymbol *Lentry, struct tnode *arglist);

//---------Global Symbol Table--------------------//
struct Gsymbol *Lookup(char *name); // Returns a pointer to the symbol table entry for the variable, returns NULL otherwise.

void GInstall(char *name, struct Typetable *type, int size, struct paramlist *plist); // Creates a symbol table entry.

//---------Local Symbol Table------------------------//
void LInstall(char *name, struct Typetable *type, int isArg);
void LPInstall(struct paramlist *plist);
struct Lsymbol *LocLookup(char *name);
void setLocalbinding();
void printLtable();
//---------Param List -----------------//
struct paramlist *PInstall(struct paramlist *head, char *name, struct Typetable *type);
struct paramlist *AddParam(struct paramlist *head, struct paramlist *oldlist);
int nameEquivalence(struct paramlist *p1, struct paramlist *p2);

//-----------Arglist-----------------//
struct tnode *appendArg(struct tnode *arglist, struct tnode *arg);
void printArgs(struct tnode *arglist);
int checkArgs(struct tnode *arglist, struct paramlist *plist);

void typecheck(struct tnode *head);

//--------Codegeneration--------------//
void init(FILE *output);
int codegen(struct tnode *t, FILE *output);
void calleegen(struct tnode *t, FILE *output, struct Gsymbol *gentry);
void maingen(struct tnode *t, FILE *output);
struct tnode *revArgs(struct tnode *t);
struct tnode *pushArgs(struct tnode *t, FILE *output);

//----------Type Table Methods-----------//
void TypeTableCreate();
struct Typetable *TLookup(char *name);
void TInstall(char *name, int size, struct Fieldlist *fields);
void FInstall(char *name, struct Typetable *type);
struct Fieldlist *FLookup(struct Typetable *type, char *name);
int GetSize(struct Typetable *type);
void printTypeTable();
void printFieldList();

void printTable();
int getSP();
void inorder(struct tnode *root);
int getReg();
void freeReg();

void print(int r, FILE *output);