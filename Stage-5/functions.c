extern struct Gsymbol *Gstart;
extern struct Lsymbol *Lstart;
struct tnode *createTree(int val, int type, char *c, int nodetype, struct tnode *l, struct tnode *r, struct tnode *middle, struct Gsymbol *Gentry, struct Lsymbol *Lentry, struct tnode *arglist)
{
    struct tnode *temp;
    temp = (struct tnode *)malloc(sizeof(struct tnode));
    temp->val = val;
    temp->type = type;
    if (c != NULL)
    {
        temp->varname = (char *)malloc(sizeof(c));
        strcpy(temp->varname, c);
    }
    temp->nodetype = nodetype;
    temp->left = l;
    temp->right = r;
    temp->middle = middle;
    temp->Gentry = Gentry;
    temp->Lentry = Lentry;
    temp->arglist = arglist;
    return temp;
}
struct Gsymbol *Lookup(char *name)
{
    if (Gstart == NULL)
    {
        return NULL;
    }
    struct Gsymbol *temp = Gstart;
    while (temp != NULL)
    {
        if (!strcmp(temp->name, name))
        {
            return temp;
        }
        temp = temp->next;
    }
    return NULL;
}
struct Lsymbol *LocLookup(char *name)
{
    if (Lstart == NULL)
    {
        return NULL;
    }
    struct Lsymbol *temp = Lstart;
    while (temp != NULL)
    {
        if (!strcmp(temp->name, name))
        {
            return temp;
        }
        temp = temp->next;
    }
    return NULL;
}
void GInstall(char *name, int type, int size, struct paramlist *plist)
{
    //type = 0 => int
    //type = 1 => str
    struct Gsymbol *newnode = (struct Gsymbol *)malloc(sizeof(struct Gsymbol));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->size = size;
    newnode->plist = plist;
    newnode->next = NULL;
    newnode->defined = 0;
    if (Gstart == NULL)
    {
        Gstart = newnode;
        Gstart->binding = 4096;
        Gstart->plist = plist;
        if (plist == NULL)
        {
            Gstart->flabel = -1;
        }
        else
        {
            Gstart->flabel = 0;
        }
        return;
    }
    struct Gsymbol *last = Gstart;
    while (last->next != NULL)
    {

        if (!strcmp(last->name, name))
        {
            printf("Redeclaration of variable ....Terminating\n");
            exit(1);
        }
        last = last->next;
    }
    //Earlier we were not checking for the last entry in symbol table
    if (!strcmp(last->name, name))
    {
        printf("Redeclaration of variable ....Terminating\n");
        exit(1);
    }
    if (plist == NULL)
    {
        newnode->flabel = last->flabel;
        newnode->binding = last->binding + last->size;
    }
    else
    {
        newnode->binding = last->binding + last->size;
        newnode->flabel = last->flabel + 1;
    }

    last->next = newnode;
}
void LInstall(char *name, int type, int isArg)
{
    //type = 0 => int
    //type = 1 => str
    struct Lsymbol *newnode = (struct Lsymbol *)malloc(sizeof(struct Lsymbol));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->next = NULL;
    newnode->isArg = isArg;
    newnode->binding = -1;
    if (Lstart == NULL)
    {
        Lstart = newnode;
        return;
    }
    struct Lsymbol *last = Lstart;
    while (last->next != NULL)
    {

        if (!strcmp(last->name, name))
        {
            printf("Redeclaration of variable ....Terminating\n");
            exit(1);
        }
        last = last->next;
    }
    //Earlier we were not checking for the last entry in symbol table
    if (!strcmp(last->name, name))
    {
        printf("Redeclaration of variable ....Terminating\n");
        exit(1);
    }
    last->next = newnode;
}
void setLocalbinding()
{
    struct Lsymbol *temp = Lstart;
    struct Lsymbol *prev = NULL;
    int count = 1;
    while (temp != NULL)
    {
        if (temp->isArg)
        {
            if (temp == Lstart)
                temp->binding = -3;
            else
            {
                temp->binding = prev->binding - 1;
            }
        }
        else
        {
            temp->binding = count++;
        }
        prev = temp;
        temp = temp->next;
    }
}
void LPInstall(struct paramlist *plist)
{
    while (plist != NULL)
    {
        LInstall(plist->name, plist->type, 1);
        plist = plist->next;
    }
}
struct paramlist *PInstall(struct paramlist *head, char *name, int type)
{
    struct paramlist *newnode = (struct paramlist *)malloc(sizeof(struct paramlist));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->next = NULL;
    if (head == NULL)
    {
        return newnode;
    }
    else
    {
        struct paramlist *temp = head;
        while (temp->next != NULL)
        {
            if (!strcmp(temp->name, name))
            {
                printf("Redeclaration of parameter in the declaration ....Terminating\n");
                exit(1);
            }
            temp = temp->next;
        }
        if (!strcmp(temp->name, name))
        {
            printf("Redeclaration of parameter in the declaration ....Terminating\n");
            exit(1);
        }
        temp->next = newnode;
        return head;
    }
}
struct tnode *appendArg(struct tnode *arglist, struct tnode *arg)
{
    struct tnode *temp = arglist;
    if (arglist == NULL)
    {
        return arg;
    }
    while (temp->middle != NULL)
    {
        temp = temp->middle;
    }
    temp->middle = arg;
    return arglist;
}
void printArgs(struct tnode *arglist)
{
    struct tnode *temp = arglist;
    while (temp != NULL)
    {
        printf("(");
        inorder(temp);
        printf(") ==> ");
        temp = temp->middle;
    }
    printf("%s", temp);
    printf("\n");
}
int checkArgs(struct tnode *arglist, struct paramlist *plist)
{
    while (arglist != NULL && plist != NULL)
    {
        if (((arglist->type == _INTEGER) && (plist->type == 1)) || ((arglist->type == _STRING) && (plist->type == 0)))
        {
            return 0;
        }
        arglist = arglist->middle;
        plist = plist->next;
    }
    if (arglist != NULL || plist != NULL)
    {
        return 0;
    }
    return 1;
}
int nameEquivalence(struct paramlist *p1, struct paramlist *p2)
{
    while (p1 != NULL && p2 != NULL)
    {

        if (p1->type != p2->type)
        {
            return 0;
        }
        p1 = p1->next;
        p2 = p2->next;
    }
    if (p1 != NULL || p2 != NULL)
    {
        return 0;
    }
    return 1;
}
void printTable()
{
    struct Gsymbol *temp = Gstart;
    printf("Name\tType\tSize\tBinding\tFlabel\n");
    while (temp != NULL)
    {
        printf("%s\t%d\t%d\t%d\t%d\n", temp->name, temp->type, temp->size, temp->binding, temp->flabel);
        if (temp->plist != NULL)
        {
            printf("Funcion %s\n", temp->name);
            struct paramlist *ptemp = temp->plist;
            while (ptemp != NULL)
            {
                printf("%s\t%d\n", ptemp->name, ptemp->type);
                ptemp = ptemp->next;
            }
        }
        temp = temp->next;
    }
}
void printLtable()
{
    struct Lsymbol *temp = Lstart;
    printf("Name\tType\tBinding\n");
    while (temp != NULL)
    {
        printf("%s\t%d\t%d\n", temp->name, temp->type, temp->binding);
        temp = temp->next;
    }
}
int getSP()
{
    struct Gsymbol *temp = Gstart;
    if (temp == NULL)
    {
        return 4096;
    }
    while (temp->next != NULL)
    {
        temp = temp->next;
    }
    return temp->binding + temp->size;
}
void typecheck(struct tnode *head)
{
    printf("Type : %s Left :%d Right %d\n", head->varname, head->left->type, head->right->type);
    int flag = 0;
    if (head->nodetype == _AND || head->nodetype == _OR)
    {
        if (head->left->type && head->right->type)
        {
            if (head->left->type != _BOOLEAN || head->right->type != _BOOLEAN)
            {
                flag = 1;
            }
        }
        else
        {
            flag = 1;
        }
    }
    if (head->nodetype == _NOT)
    {
        if (head->left->type)
        {
            if (head->left->type != _BOOLEAN)
            {
                flag = 1;
            }
        }
        else
        {
            flag = 1;
        }
    }
    if (head->left->nodetype == _STRING || head->right->nodetype == _STRING)
    {
        flag = 1;
    }
    if (flag == 0)
        return;
    else
    {
        printf("Type mismatch\n");
        exit(1);
    }
    return;
}
void inorder(struct tnode *t)
{
    if (t == NULL)
    {
        return;
    }
    inorder(t->left);
    if (t->varname == NULL)
    {
        printf("%d ", t->val);
    }
    else
    {
        printf("%s ", (t->varname));
    }
    inorder(t->right);
}
