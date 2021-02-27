extern struct Gsymbol* Gstart;
struct tnode* createTree(int val, int type, char* c, int nodetype, struct tnode* l, struct tnode* r, struct tnode* cond, struct Gsymbol* Gentry) {
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
    temp->Gentry = Gentry;
    return temp;
}
struct Gsymbol* Lookup(char* name) {
    if (Gstart == NULL) {
        return NULL;
    }
    struct Gsymbol* temp = Gstart;
    while (temp != NULL) {
        if (!strcmp(temp->name, name)) {
            return temp;
        }
        temp = temp->next;
    }
    return NULL;
}
void Install(char* name, int type, int size) {
    //type = 0 => int
    //type = 1 => str
    struct Gsymbol* newnode = (struct Gsymbol*)malloc(sizeof(struct Gsymbol));
    newnode->name = (char*)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->size = size;
    newnode->next = NULL;
    if (Gstart == NULL) {
        Gstart = newnode;
        Gstart->binding = 4096;
        return;
    }
    struct Gsymbol* last = Gstart;
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name)) {
            printf("Redeclaration of variable ....Terminating\n");
            exit(1);
        }
        last = last->next;
    }
    newnode->binding = last->binding + last->size;
    last->next = newnode;
}
void printTable() {
    struct Gsymbol* temp = Gstart;
    printf("Name\tType\tSize\tBinding\n");
    while (temp != NULL) {
        printf("%s\t%d\t%d\t%d\n", temp->name, temp->type, temp->size, temp->binding);
        temp = temp->next;
    }
}
int getSP() {
    struct Gsymbol* temp = Gstart;
    while (temp->next != NULL) {
        temp = temp->next;
    }
    return temp->binding + temp->size;
}
void typecheck(struct tnode* head) {
    printf("Type : %s Left :%s Right %s\n", head->varname, head->left->varname, head->right->varname);
    int flag = 0;
    if (head->left->nodetype == _STRING || head->right->nodetype == _STRING) {
        flag = 1;
    }
    if (flag == 0) return;
    else
    {
        printf("Type mismatch\n");
        exit(1);
    }
    // printf("varname = %s\n", head->varname);
    // if (type == _INTEGER) {
    //     if ((head->left->type != _INTEGER) || (head->right->type != _INTEGER)) {
    //         printf("type mismatch...Stopping\n");
    //         printf("hasdf\n");
    //         exit(1);
    //     }
    //     else {
    //         head->type = _INTEGER;
    //     }
    // }
    // if (type == _BOOLEAN) {
    //     if (head->type != _BOOLEAN) {
    //         printf("Type mismatch...Stopping\n");
    //         exit(1);
    //     }
    // }
    return;
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
