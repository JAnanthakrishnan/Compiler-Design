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
void yyerror(char const* s);
typedef struct tnode {
    int val;	// value of a number for NUM nodes.
    int type;	//type of variable
    char* varname;	//name of a variable for ID nodes  
    int nodetype;  // information about non-leaf nodes - read/write/connector/+/* etc.  
    struct tnode* left, * right;	//left and right branches   
}tnode;

/*Create a node tnode*/
struct tnode* createTree(int val, int type, char* c, int nodetype, struct tnode* l, struct tnode* r);
void inorder(struct tnode* root);
int getReg();
void freeReg();
int codegen(struct tnode* t, FILE* output);
void print(int r, FILE* output);