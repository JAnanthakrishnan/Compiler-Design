int MAX_REG = 20;
int REG = 0;
int LABEL = 0;

int getReg() {
    if (REG == MAX_REG) {
        printf("Out of registers \n");
        exit(1);
    }
    return REG++;
}
int getLabel() {
    return LABEL++;
}
int getAddress(struct tnode* t, FILE* output) {
    if (t->nodetype == _ID) {
        int r1 = getReg();

        fprintf(output, "MOV R%d, %d\n", r1, t->Gentry->binding);
        return r1;
    }
    if (t->nodetype == _ARR) {
        int r1 = getReg();
        int r2 = codegen(t->left, output);
        fprintf(output, "MOV R%d, %d\n", r1, t->Gentry->binding);
        fprintf(output, "ADD R%d, R%d\n", r1, r2);
        freeReg();
        return r1;
    }
}

void freeReg() {
    if (REG > 0)
        REG--;
}

int codegen(struct tnode* t, FILE* output) {
    int r1, r2, address, current = 0;
    int label1, label2;
    static int prevLabel1, prevLabel2;
    static int isWhile = 0;
    int a1, a2;
    if (t == NULL) {
        return -1;
    }
    else if (t->nodetype == _CONNECTOR) {
        codegen(t->left, output);
        freeReg();
        codegen(t->right, output);
        freeReg();
    }

    switch (t->nodetype) {
    case _NUM:
        r1 = getReg();
        fprintf(output, "MOV R%d, %d\n", r1, t->val);
        return r1;
    case _STRING:
        r1 = getReg();
        fprintf(output, "MOV R%d,%s\n", r1, t->varname);
        return r1;
    case _ID:
        r1 = getReg();
        r2 = getAddress(t, output);
        fprintf(output, "MOV R%d, [R%d]\n", r1, r2);
        return r1;
    case _ARR:
        r1 = getReg();
        if (t->left->nodetype == _ID) {
            address = t->Gentry->binding + t->left->Gentry->value;
        }
        else
            address = t->Gentry->binding + t->left->val;
        if (address > t->Gentry->binding + t->Gentry->size) {
            printf("\n! Index out of range\n");
            exit(1);
        }
        r2 = getAddress(t, output);
        fprintf(output, "MOV R%d, [R%d]\n", r1, r2);
        freeReg();
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
        return r1;
    case _GT:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "GT R%d,R%d\n", r1, r2);
        return r1;
    case _EQ:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "EQ R%d,R%d\n", r1, r2);
        return r1;
    case _GTE:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "GE R%d,R%d\n", r1, r2);
        return r1;
    case _LTE:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "LE R%d,R%d\n", r1, r2);
        return r1;
    case _NEQ:
        r1 = codegen(t->left, output);
        r2 = codegen(t->right, output);
        fprintf(output, "NE R%d,R%d\n", r1, r2);
        return r1;
    case _ASSIGN:
        if (t->left->nodetype == _ID) {
            t->left->Gentry->value = t->right->val;
        }
        // else if (t->left->nodetype == _ARR)
        // {
        //     if (t->left->left->nodetype == _ID) {
        //         address = t->left->Gentry->binding + t->left->left->Gentry->value;
        //     }
        //     else
        //         address = t->left->Gentry->binding + t->left->left->val;
        // }

        r1 = codegen(t->right, output);
        r2 = getAddress(t->left, output);
        fprintf(output, "MOV [R%d], R%d\n", r2, r1);
        freeReg();
        freeReg();
        return 0;
    case _WRITE:
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;

        fprintf(output, "MOV R0,\"Write\"\n");
        fprintf(output, "PUSH R0\n");       // Library "Write"
        fprintf(output, "MOV R0,-2\n");
        fprintf(output, "PUSH R0\n");       //Argument 1

        r1 = codegen(t->left, output);
        fprintf(output, "PUSH R%d\n", r1);  //Argument 2
        freeReg();
        fprintf(output, "PUSH R0\n");
        fprintf(output, "PUSH R0\n");
        fprintf(output, "CALL 0\n");
        fprintf(output, "POP R0\n");
        fprintf(output, "POP R0\n");
        fprintf(output, "POP R0\n");
        fprintf(output, "POP R0\n");
        fprintf(output, "POP R0\n");

        for (int i = current; i >= 0; i--)
            fprintf(output, "POP R%d\n", i);
        REG = current;
        break;
    case _READ:
        r1 = getAddress(t->left, output);
        r2 = getReg();
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;

        fprintf(output, "MOV R%d,\"Read\"\n", r2);
        fprintf(output, "PUSH R%d\n", r2);           // Library  "Read"
        fprintf(output, "MOV R%d,-1\n", r2);
        fprintf(output, "PUSH R%d\n", r2);           //Argument 1
        fprintf(output, "MOV R%d,R%d\n", r2, r1);
        fprintf(output, "PUSH R%d\n", r2);           //Argument 2
        fprintf(output, "PUSH R%d\n", r2);
        fprintf(output, "PUSH R%d\n", r2);
        fprintf(output, "CALL 0\n");
        fprintf(output, "POP R%d\n", r2);
        fprintf(output, "POP R%d\n", r2);
        fprintf(output, "POP R%d\n", r2);
        fprintf(output, "POP R%d\n", r2);
        fprintf(output, "POP R%d\n", r2);

        for (int i = current; i >= 0; i--)
            fprintf(output, "POP R%d\n", i);
        REG = current;
        freeReg();
        break;
    case _WHILE:
        printf("From while\n");
        isWhile = 1;
        label1 = getLabel();
        label2 = getLabel();
        printf("Label1 from while is %d\nLabel2 from while is %d\n", label1, label2);
        prevLabel1 = label1;
        prevLabel2 = label2;
        fprintf(output, "L%d:\n", label1);
        // r1 = getReg();
        // r2 = getReg();
        // if (t->cond->left->varname != NULL)
        // {
        //     a1 = getAddress(t->cond->left, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r1, a1);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r1, t->cond->left->val);
        // }
        // if (t->cond->right->varname != NULL) {
        //     a2 = getAddress(t->cond->right, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r2, a2);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r2, t->cond->right->val);
        // }
        // fprintf(output, "%s R%d,R%d\n", t->cond->varname, r1, r2);
        // freeReg();
        r1 = codegen(t->cond, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label2);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "JMP L%d\n", label1);
        fprintf(output, "L%d:\n", label2);
        isWhile = 0;
        break;
    case _BREAK:
        if (isWhile) {
            fprintf(output, "JMP L%d\n", prevLabel2);
        }
        break;
    case _CONTINUE:
        if (isWhile) {
            fprintf(output, "JMP L%d\n", prevLabel1);
        }
        break;
    case _IF:
        label1 = getLabel();
        // r1 = getReg();
        // r2 = getReg();
        // if (t->cond->left->varname != NULL)
        // {
        //     a1 = getAddress(t->cond->left, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r1, a1);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r1, t->cond->left->val);
        // }
        // if (t->cond->right->varname != NULL) {
        //     a2 = getAddress(t->cond->right, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r2, a2);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r2, t->cond->right->val);
        // }

        // fprintf(output, "%s R%d,R%d\n", t->cond->varname, r1, r2);
        // freeReg();
        r1 = codegen(t->cond, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label1);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "L%d:\n", label1);
        break;
    case _IFELSE:
        label1 = getLabel();
        label2 = getLabel();
        // r1 = getReg();
        // r2 = getReg();
        // if (t->cond->left->varname != NULL)
        // {
        //     a1 = getAddress(t->cond->left, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r1, a1);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r1, t->cond->left->val);
        // }
        // if (t->cond->right->varname != NULL) {
        //     a2 = getAddress(t->cond->right, output);
        //     fprintf(output, "MOV R%d,[R%d]\n", r2, a2);
        // }
        // else {
        //     fprintf(output, "MOV R%d,%d\n", r2, t->cond->right->val);
        // }
        // fprintf(output, "%s R%d,R%d\n", t->cond->varname, r1, r2);
        // freeReg();
        r1 = codegen(t->cond, output);
        fprintf(output, "JZ R%d,L%d\n", r1, label1);
        freeReg();
        codegen(t->left, output);
        fprintf(output, "JMP L%d\n", label2);
        fprintf(output, "L%d:\n", label1);
        codegen(t->right, output);
        fprintf(output, "L%d:\n", label2);
        break;
    }

}
void print(int r, FILE* output) {
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
