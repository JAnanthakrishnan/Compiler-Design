
extern struct Gsymbol *Gstart;
extern struct Lsymbol *Lstart;
extern struct Typetable *TypeTable;
extern struct Fieldlist *FieldList;
extern struct Classtable *ClassTable;
int cflabel = 0;

struct tnode *createTree(int val, struct Typetable *type, char *c, int nodetype, struct tnode *l, struct tnode *r, struct tnode *middle, struct Gsymbol *Gentry, struct Lsymbol *Lentry, struct tnode *arglist)
{
    struct tnode *temp;
    temp = (struct tnode *)malloc(sizeof(struct tnode));
    temp->val = val;
    temp->type = type;
    temp->Ctype = NULL;
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

void GInstall(char *name, struct Typetable *type, struct Classtable *Ctype, int size, struct paramlist *plist)
{
    //type = 0 => int
    //type = 1 => str
    struct Gsymbol *newnode = (struct Gsymbol *)malloc(sizeof(struct Gsymbol));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->Ctype = Ctype;
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

void LInstall(char *name, struct Typetable *type, int isArg)
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
    LInstall("SELF",TLookup("NULL"),1);
}

struct paramlist *PInstall(struct paramlist *head, char *name, struct Typetable *type)
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
        if (arglist->type != plist->type)
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
    printf("Name\tType\tClass\tSize\tBinding\tFlabel\n");
    while (temp != NULL)
    {
        if(temp->type!=NULL)
            printf("%s\t%s\tNULL\t%d\t%d\t%d\n", temp->name, temp->type->name, temp->size, temp->binding, temp->flabel);
        else
            printf("%s\tNULL\t%s\t%d\t%d\t%d\n", temp->name, temp->Ctype->name, temp->size, temp->binding, temp->flabel);
        
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
    // printf("Type : %s Left :%d Right %d\n", head->varname, head->left->type, head->right->type);
    // int flag = 0;
    // if (head->nodetype == _AND || head->nodetype == _OR)
    // {
    //     if (head->left->type && head->right->type)
    //     {
    //         if (head->left->type != _BOOLEAN || head->right->type != _BOOLEAN)
    //         {
    //             flag = 1;
    //         }
    //     }
    //     else
    //     {
    //         flag = 1;
    //     }
    // }
    // if (head->nodetype == _NOT)
    // {
    //     if (head->left->type)
    //     {
    //         if (head->left->type != _BOOLEAN)
    //         {
    //             flag = 1;
    //         }
    //     }
    //     else
    //     {
    //         flag = 1;
    //     }
    // }
    // if (head->left->nodetype == _STRING || head->right->nodetype == _STRING)
    // {
    //     flag = 1;
    // }
    // if (flag == 0)
    //     return;
    // else
    // {
    //     printf("Type mismatch\n");
    //     exit(1);
    // }
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

void FInstall(char *name, struct Typetable *type)
{
    struct Fieldlist *newnode = (struct Fieldlist *)malloc(sizeof(struct Fieldlist));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->next = NULL;
    if (FieldList == NULL)
    {
        newnode->fieldIndex = 1;
        FieldList = newnode;
        return;
    }
    struct Fieldlist *last = FieldList;
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            if (last->type == type) //both name and type should be checked
            {
                printf("Redclaration of field %s \n", name);
                exit(1);
            }
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        if (last->type == type) //both name and type should be checked
        {
            printf("Redclaration of field %s \n", name);
            exit(1);
        }
    }
    newnode->fieldIndex = last->fieldIndex + 1;
    if (newnode->fieldIndex == 8)
    {
        printf("Maximum of 8 fields exceeded\n");
        exit(1);
    }
    last->next = newnode;
}

void TInstall(char *name, int size, struct Fieldlist *fields)
{
    struct Typetable *newnode = (struct Typetable *)malloc(sizeof(struct Typetable));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->size = size;
    newnode->fields = fields;
    newnode->next = NULL;
    if (TypeTable == NULL)
    {
        TypeTable = newnode;
        return;
    }
    struct Typetable *last = TypeTable;
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            printf("Redclaration of type %s\n", name);
            exit(1);
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        printf("Redclaration of type %s\n", name);
        exit(1);
    }
    last->next = newnode;
}

void TypeTableCreate()
{
    TInstall("INT", 1, NULL);
    TInstall("STR", 1, NULL);
    TInstall("BOOL", 0, NULL);
    TInstall("VOID", 0, NULL);
    TInstall("NULL", 0, NULL);
}

struct Typetable *TLookup(char *name)
{
    if (TypeTable == NULL)
    {
        return NULL;
    }
    struct Typetable *temp = TypeTable;
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

struct Fieldlist *FLookup(struct Typetable *type, char *name)
{
    struct Fieldlist *temp = type->fields;
    if (temp == NULL)
    {
        return NULL;
    }
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

struct Classtable *CInstall(char *name, char *parent_class_name)
{
    struct Classtable *newnode = (struct Classtable *)malloc(sizeof(struct Classtable));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->Parentptr = CLookup(parent_class_name);
    newnode->next = NULL;
    if (ClassTable == NULL)
    {
        newnode->Class_index = 0;
        newnode->Fieldcount = 0;
        newnode->Methodcount = 0;
        newnode->Memberfield = NULL;
        newnode->Vfuncptr = NULL;
        ClassTable = newnode;
        return newnode;
    }
    struct Classtable *last = ClassTable;
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            printf("Redclaration of class %s\n", name);
            exit(1);
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        printf("Redclaration of class %s\n", name);
        exit(1);
    }
    newnode->Class_index = last->Class_index + 1;
    newnode->Fieldcount = 0;
    newnode->Methodcount = 0;
    newnode->Memberfield = NULL;
    newnode->Vfuncptr = NULL;
    last->next = newnode;
    return newnode;
}

struct Classtable *CLookup(char *name)
{
    if(name==NULL){
        return NULL;
    }
    if (ClassTable == NULL)
    {
        return NULL;
    }
    struct Classtable *temp = ClassTable;
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

void Class_Finstall(struct Classtable* curr, struct Classtable *cptr, struct Typetable *type, char *name)
{
    struct Memberfieldlist *newnode = (struct Memberfieldlist *)malloc(sizeof(struct Memberfieldlist));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->Ctype = cptr;
    newnode->next = NULL;
    struct Memberfieldlist *last = curr->Memberfield;
    if (last == NULL)
    {
        curr->Memberfield = newnode;
        newnode->Fieldindex = 0;
        return;
    }
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            printf("Redclaration of member field %s\n", name);
            exit(1);
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        printf("Redclaration of member field %s\n", name);
        exit(1);
    }
    newnode->Fieldindex = last->Fieldindex + 1;
    last->next = newnode;
    curr->Fieldcount++;
}

struct Memberfieldlist *Class_Flookup(struct Classtable *Ctype, char *name)
{
    if (Ctype == NULL)
    {
        return NULL;
    }
    if (Ctype->Memberfield == NULL)
    {
        return NULL;
    }
    struct Memberfieldlist *temp = Ctype->Memberfield;
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

void Class_Minstall(struct Classtable *cptr, char *name, struct Typetable *type, struct paramlist *Paramlist)
{
    struct Memberfunclist *newnode = (struct Memberfunclist *)malloc(sizeof(struct Memberfunclist));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->paramlist = Paramlist;
    newnode->next = NULL;
    struct Memberfunclist *last = cptr->Vfuncptr;
    if (last == NULL)
    {
        newnode->Funcposition = 1;
        newnode->flabel = ++cflabel;
        cptr->Vfuncptr = newnode;
        return;
    }
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            printf("Redclaration of member function %s\n", name);
            exit(1);
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        printf("Redclaration of member function %s\n", name);
        exit(1);
    }
    newnode->Funcposition = last->Funcposition + 1;
    newnode->flabel = ++cflabel;
    last->next = newnode;
    cptr->Methodcount++;
}

struct Memberfunclist *Class_Mlookup(struct Classtable *Ctype, char *name)
{
    if (Ctype == NULL)
    {
        return NULL;
    }
    if (Ctype->Vfuncptr == NULL)
    {
        return NULL;
    }
    struct Memberfunclist *temp = Ctype->Vfuncptr;
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

int GetSize(struct Typetable *type)
{
    struct Fieldlist *temp = type->fields;
    int count = 0;
    while (temp != NULL)
    {
        count++;
        temp = temp->next;
    }
    return count;
}

void printTypeTable()
{
    struct Typetable *temp = TypeTable;
    printf("\nName\tSize\n");
    while (temp != NULL)
    {
        printf("%s\t%d\n", temp->name, temp->size);
        if (temp->fields != NULL)
        {
            printf("FieldList for %s is\n", temp->name);
            printFieldList(temp->fields);
        }
        temp = temp->next;
    }
}

void printFieldList(struct Fieldlist *Flist)
{
    struct Fieldlist *temp = Flist;
    printf("Name\tType\n");
    while (temp != NULL)
    {
        printf("%s\t%s\n", temp->name, temp->type->name);
        temp = temp->next;
    }
}