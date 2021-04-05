int MAX_REG = 20;
int REG = -1;
int LABEL = 0;
extern struct Lsymbol *Lstart;
int getReg()
{
    if (REG == MAX_REG)
    {
        printf("Out of registers \n");
        exit(1);
    }
    return ++REG;
}
int getLabel()
{
    return ++LABEL;
}
int getAddress(struct tnode *t, FILE *output)
{
    // printf("Local entry %s \n",t->Lentry->name);
    if (t->nodetype == _ID && t->Gentry != NULL)
    {
        int r1 = getReg();
        fprintf(output, "MOV R%d, %d\n", r1, t->Gentry->binding);
        return r1;
    }
    else if (t->nodetype == _ID)
    {
        int r1 = getReg();
        fprintf(output, "MOV R%d,BP\n", r1);
        printf("Local entry %s \n", t->Lentry->name);
        fprintf(output, "ADD R%d, %d\n", r1, t->Lentry->binding);
        return r1;
    }
    else if (t->nodetype == _ARR)
    {
        int r1 = getReg();
        int r2 = codegen(t->left, output);
        fprintf(output, "MOV R%d, %d\n", r1, t->Gentry->binding);
        fprintf(output, "ADD R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    }
    else
    {
        printf("Invalid Nodetype for memory address\n");
        exit(1);
    }
    return -1;
}

void freeReg()
{
    if (REG >= 0)
        REG--;
}
void freeAllReg()
{
    REG = -1;
}
struct tnode *revArgs(struct tnode *t)
{
    struct tnode *prev = NULL;
    struct tnode *curr = t;
    struct tnode *next = NULL;
    while (curr != NULL)
    {
        next = curr->middle;
        curr->middle = prev;

        prev = curr;
        curr = next;
    }
    t = prev;
    return t;
}
struct tnode *pushArgs(struct tnode *t, FILE *output)
{
    int r;
    struct tnode *temp = revArgs(t);
    t = temp;
    while (temp != NULL)
    {
        r = codegen(temp, output);
        fprintf(output, "PUSH R%d\n", r);
        freeReg();
        temp = temp->middle;
    }
    return t;
}
void popArgs(struct tnode *t, FILE *output)
{
    int r = getReg();
    while (t != NULL)
    {
        fprintf(output, "POP R%d\n", r);
        t = t->middle;
    }
    freeReg();
}

int codegen(struct tnode *t, FILE *output)
{
    int r1, r2, address, current = 0;
    int label1, label2;
    static int prevLabel1, prevLabel2;
    static int isWhile = 0;
    int a1, a2;
    if (t == NULL)
    {
        return -1;
    }
    else if (t->nodetype == _CONNECTOR)
    {
        codegen(t->left, output);
        codegen(t->right, output);
        return -1;
    }

    switch (t->nodetype)
    {
    case _NUM:
        r1 = getReg();
        fprintf(output, "MOV R%d, %d\n", r1, t->val);
        return r1;
    case _STRING:
        r1 = getReg();
        fprintf(output, "MOV R%d,%s\n", r1, t->varname);
        return r1;
    case _ID:
        r1 = getAddress(t, output);
        fprintf(output, "MOV R%d, [R%d]\n", r1, r1);
        return r1;
    case _ARR:
        // if (t->Gentry != NULL)
        // {
        //     if (t->left->nodetype == _ID)
        //     {
        //         address = t->Gentry->binding + t->left->Gentry->value;
        //     }
        //     else
        //         address = t->Gentry->binding + t->left->val;
        //     if (address > t->Gentry->binding + t->Gentry->size)
        //     {
        //         printf("\n! Index out of range\n");
        //         exit(1);
        //     }
        // }
        r1 = getAddress(t, output);
        fprintf(output, "MOV R%d, [R%d]\n", r1, r1);
        return r1;
    case _PLUS:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "ADD R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    case _MINUS:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "SUB R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    case _MUL:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "MUL R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    case _DIV:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "DIV R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    case _MOD:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "MOD R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    case _LT:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "LT R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _GT:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "GT R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _EQ:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "EQ R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _GTE:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "GE R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _LTE:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "LE R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _NEQ:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "NE R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _AND:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "MUL R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _OR:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "ADD R%d,R%d\n", r1, r2);
        freeReg();
        return r1;
    case _NOT:
        // r1 = codegen(t->left, output);
        // fprintf(output, "NE R%d,R%d\n", r1, r2);
        // freeReg();
        // return r1;
    case _ASSIGN:
        if (t->left->nodetype == _ID && t->left->Gentry != NULL)
        {
            t->left->Gentry->value = t->right->val;
        }
        r1 = getAddress(t->left, output);
        r2 = codegen(t->right, output);

        fprintf(output, "MOV [R%d], R%d\n", r1, r2);
        freeReg();
        freeReg();
        return 0;
    case _WRITE:
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;

        fprintf(output, "MOV R0,\"Write\"\n");
        fprintf(output, "PUSH R0\n"); // function code  for "Write"
        fprintf(output, "MOV R0,-2\n");
        fprintf(output, "PUSH R0\n"); //Argument 1

        r1 = codegen(t->left, output);
        fprintf(output, "PUSH R%d\n", r1); //Argument 2
        freeReg();
        fprintf(output, "ADD SP,2\n");
        fprintf(output, "CALL 0\n");
        fprintf(output, "SUB SP,5\n");

        for (int i = current; i >= 0; i--)
            fprintf(output, "POP R%d\n", i);
        REG = current;
        break;
    case _READ:
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;

        fprintf(output, "MOV R0,\"Read\"\n");
        fprintf(output, "PUSH R0\n"); // function code for "Read"
        fprintf(output, "MOV R0,-1\n");
        fprintf(output, "PUSH R0\n"); //Argument 1

        r1 = getAddress(t->left, output);
        fprintf(output, "PUSH R%d\n", r1); //Argument 2
        freeReg();

        fprintf(output, "ADD SP,2\n");
        fprintf(output, "CALL 0\n");
        fprintf(output, "SUB SP,5\n");

        for (int i = current; i >= 0; i--)
            fprintf(output, "POP R%d\n", i);
        REG = current;
        break;
    case _WHILE:
        // printf("From while\n");
        isWhile = 1;
        label1 = getLabel();
        label2 = getLabel();
        // printf("Label1 from while is %d\nLabel2 from while is %d\n", label1, label2);
        prevLabel1 = label1;
        prevLabel2 = label2;
        fprintf(output, "L%d:\n", label1);
        r1 = codegen(t->middle, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label2);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "JMP L%d\n", label1);
        fprintf(output, "L%d:\n", label2);
        isWhile = 0;
        break;
    case _BREAK:
        if (isWhile)
        {
            fprintf(output, "JMP L%d\n", prevLabel2);
        }
        break;
    case _CONTINUE:
        if (isWhile)
        {
            fprintf(output, "JMP L%d\n", prevLabel1);
        }
        break;
    case _IF:
        label1 = getLabel();
        r1 = codegen(t->middle, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label1);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "L%d:\n", label1);
        break;
    case _IFELSE:
        label1 = getLabel();
        label2 = getLabel();
        r1 = codegen(t->middle, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label1);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "JMP L%d\n", label2);
        fprintf(output, "L%d:\n", label1);
        codegen(t->right, output);
        fprintf(output, "L%d:\n", label2);
        break;
    case _RETURN:
        r1 = getReg();
        r2 = codegen(t->left, output);
        fprintf(output, "MOV R%d,BP\n", r1);
        fprintf(output, "ADD R%d,%d\n", r1, -2);
        fprintf(output, "MOV [R%d], R%d\n", r1, r2);
        freeReg();
        freeReg();
        struct Lsymbol *temp = Lstart;
        while (temp != NULL)
        {
            // printf("The variable name is %s\n", temp->name);
            if (!temp->isArg)
                fprintf(output, "POP R0\n");
            temp = temp->next;
        }

        fprintf(output, "POP BP\n");
        fprintf(output, "RET\n");
        break;

    case _FUNCTION:
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;
        freeAllReg();
        //push the arguments
        // fprintf(output, "Pushing args\n");

        t->arglist = pushArgs(t->arglist, output);

        /*------push one empty value for ret---------*/
        fprintf(output, "PUSH R0\n");

        /*----------calling the function---------*/
        fprintf(output, "CALL F%d\n", t->Gentry->flabel);

        /*--------Saving return value ----------*/
        r1 = current + 1;
        fprintf(output, "POP R%d\n", r1); //return value

        if (current == -1)
        {
            r2 = getReg();
        }
        /*------------Pop the args---------*/
        popArgs(t->arglist, output);
        if (current == -1)
            freeReg();

        /*----------Pop the saved registers--------------*/
        // fprintf(output, "popping  registers\n");
        for (int i = current; i >= 0; i--)
            fprintf(output, "POP R%d\n", i);
        REG = current;
        r1 = getReg();
        return r1;
        break;
    }
}
void maingen(struct tnode *t, FILE *output)
{
    fprintf(output, "MAIN:\n");
    fprintf(output, "PUSH BP\n");
    fprintf(output, "MOV BP,SP\n");
    struct Lsymbol *temp = Lstart;
    while (temp != NULL)
    {
        // printf("The variable name is %s\n", temp->name);
        if (!temp->isArg)
            fprintf(output, "PUSH R0\n");
        temp = temp->next;
    }
    codegen(t, output);
}
void calleegen(struct tnode *t, FILE *output, struct Gsymbol *gentry)
{
    printf("Printing from calleegen\n");
    printLtable(Lstart);
    fprintf(output, "F%d:\n", gentry->flabel);
    fprintf(output, "PUSH BP\n");
    fprintf(output, "MOV BP,SP\n");
    struct Lsymbol *temp = Lstart;
    while (temp != NULL)
    {
        // printf("The variable name is %s\n", temp->name);
        if (!temp->isArg)
            fprintf(output, "PUSH R0\n");
        temp = temp->next;
    }
    codegen(t, output);
}
void init(FILE *output)
{
    fprintf(output, "0\n2056\n0\n0\n0\n0\n0\n0\n");
    fprintf(output, "MOV SP, %d\n", getSP()-1);
    fprintf(output, "PUSH R0\n");
    fprintf(output, "CALL MAIN\n");
    fprintf(output, "MOV R0, 10\nPUSH R0\nINT 10\n");
}
void print(int r, FILE *output)
{
    /*
    MOV SP,4096
    MOV R0,"Write"
    PUSH R0
    MOV R0,-2
    PUSH R0
    PUSH R1
    PUSH R1
    PUSH R1
    CALL 0
    POP R1
    POP R1
    POP R1
    POP R1
    POP R1
    */
    int r_ = r + 1;
    fprintf(output, "MOV SP,4096\n");
    fprintf(output, "MOV R%d,\"Write\"\n", r_);
    fprintf(output, "PUSH R%d\n", r_);
    fprintf(output, "MOV R%d,-2\n", r_);
    fprintf(output, "PUSH R%d\n", r_);
    fprintf(output, "PUSH R%d\n", r);
    fprintf(output, "PUSH R%d\n", r);
    fprintf(output, "PUSH R%d\n", r);
    fprintf(output, "CALL 0\n");
    fprintf(output, "POP R%d\n", r);
    fprintf(output, "POP R%d\n", r);
    fprintf(output, "POP R%d\n", r);
    fprintf(output, "POP R%d\n", r);
    fprintf(output, "POP R%d\n", r);
    fprintf(output, "INT 10\n");
    return;
}
