void yyerror(char const*);
typedef struct tnode {
    int val; //value of the expression tree
    char* op; //indicates the opertor
    struct tnode* left, * right; //left and right branches
}tnode;

/*Make a leaf tnode and set the value of val field*/
struct tnode* makeLeafNode(int n);

/*Make a tnode with opertor, left and right branches set*/
struct tnode* makeOperatorNode(char c, struct tnode* l, struct tnode* r);

/*To evaluate an expression tree*/
int evaluate(struct tnode* t);
void preorder(struct tnode* t);
void postorder(struct tnode* t);
int getReg();
void freeReg();
int codegen(struct tnode* t, FILE* output);
void print(int r, FILE* output);