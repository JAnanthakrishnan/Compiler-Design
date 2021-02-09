struct tnode* createTree(int val, int type, char* c, int nodetype, struct tnode* l, struct tnode* r) {
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
    return temp;
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