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
void yyerror(char const* s);
typedef struct tnode {
    int val;	// value of a number for NUM nodes.
    int type;	//type of variable
    char* varname;	//name of a variable for ID nodes  
    int nodetype;  // information about non-leaf nodes - read/write/connector/+/* etc.  
    struct tnode* left, * right;	//left and right branches  
    struct Gsymbol* Gentry;
    struct tnode* cond;
}tnode;
typedef struct Gsymbol {
    char* name;         // name of the variable
    int type;           // type of the variable
    int size;           // size of the type of the variable
    int binding;        // stores the static memory address allocated to the variable
    int value;
    struct Gsymbol* next;
}Gsymbol;

/*Create a node tnode*/
struct tnode* createTree(int val, int type, char* c, int nodetype, struct tnode* l, struct tnode* r, struct tnode* cond, struct Gsymbol* Gentry);
struct Gsymbol* Lookup(char* name); // Returns a pointer to the symbol table entry for the variable, returns NULL otherwise.

void Install(char* name, int type, int size); // Creates a symbol table entry.
void typecheck(struct tnode* head);
void printTable();
int getSP();
void inorder(struct tnode* root);
int getReg();
void freeReg();
int codegen(struct tnode* t, FILE* output);
void print(int r, FILE* output);