struct tnode* createTree(int val, int type, char* c, int nodetype, struct tnode* l, struct tnode* r, struct tnode* cond) {
    struct tnode* temp;
    temp = (struct tnode*)malloc(sizeof(struct tnode));
    temp->val = val;
    temp->type = type;
    if (c != NULL) {
        temp->varname = (char*)malloc(sizeof(c));
        strcpy(temp->varname, c);
    }
    temp->nodetype = nodetype;
    temp->left = l;
    temp->right = r;
    temp->cond = cond;
    return temp;
}
void typecheck(int type, struct tnode* head) {
    if (type == _INTEGER) {
        if ((head->left->type != _INTEGER) || (head->right->type != _INTEGER)) {
            printf("type mismatch...Stopping\n");
            exit(1);
        }
        else {
            head->type = _INTEGER;
        }
    }
    if (type == _BOOLEAN) {
        if (head->type != _BOOLEAN) {
            printf("Type mismatch...Stopping\n");
            exit(1);
        }
    }
}
void inorder(struct tnode* t) {
    if (t == NULL) {
        return;
    }
    inorder(t->left);
    if (t->varname == NULL) {
        printf("%d ", t->val);
    }
    else {
        printf("%s ", (t->varname));
    }
    inorder(t->right);
}
