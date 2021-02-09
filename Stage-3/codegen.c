int MAX_REG = 20;
int REG = 0;

int getReg() {
    if (REG == MAX_REG) {
        printf("Out of registers \n");
        exit(1);
    }
    return REG++;
}

void freeReg() {
    if (REG > 0)
        REG--;
}

int codegen(struct tnode* t, FILE* output) {
    int r1, r2, address, current = 0;

    if (t == NULL) {
        return -1;
    }
    else if (t->nodetype == _CONNECTOR) {
        codegen(t->left, output);
        codegen(t->right, output);
    }

    switch (t->nodetype) {
    case _NUM:
        r1 = getReg();
        fprintf(output, "MOV R%d, %d\n", r1, t->val);
        return r1;
    case _ID:
        r1 = getReg();
        address = 4096 + t->varname[0] - 'a';
        fprintf(output, "MOV R%d, [%d]\n", r1, address);
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
    case _ASSIGN:
        address = 4096 + *(t->left->varname) - 'a';
        r2 = codegen(t->right, output);
        fprintf(output, "MOV [%d], R%d\n", address, r2);
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
        address = 4096 + *(t->left->varname) - 'a';
        for (int i = 0; i <= REG; i++)
            fprintf(output, "PUSH R%d\n", i);
        current = REG;

        fprintf(output, "MOV R0,\"Read\"\n");
        fprintf(output, "PUSH R0\n");           // Library  "Read"
        fprintf(output, "MOV R0,-1\n");
        fprintf(output, "PUSH R0\n");           //Argument 1
        fprintf(output, "MOV R0,%d\n", address);
        fprintf(output, "PUSH R0\n");           //Argument 2
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
