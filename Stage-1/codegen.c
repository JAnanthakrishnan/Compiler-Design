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
    if (t->op == NULL) {
        int reg = getReg();
        printf("MOV R%d,%d\n", reg, t->val);
        fprintf(output, "MOV R%d,%d\n", reg, t->val);
        return reg;
    }
    int reg1 = codegen(t->left, output);
    int reg2 = codegen(t->right, output);
    switch (*(t->op))
    {
    case '+':fprintf(output, "ADD R%d,R%d\n", reg1, reg2);
        printf("ADD R%d,R%d\n", reg1, reg2);
        freeReg();
        return reg1;
        break;
    case '-':fprintf(output, "SUB R%d,R%d\n", reg1, reg2);
        printf("SUB R%d,R%d\n", reg1, reg2);
        freeReg();
        return reg1;
        break;
    case '*':fprintf(output, "MUL R%d,R%d\n", reg1, reg2);
        printf("MUL R%d,R%d\n", reg1, reg2);
        freeReg();
        return reg1;
        break;
    case '/':fprintf(output, "DIV R%d,R%d\n", reg1, reg2);
        printf("DIV R%d,R%d\n", reg1, reg2);
        freeReg();
        return reg1;
        break;
    default:
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
