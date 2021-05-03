
#include "y.tab.h"
extern struct Gsymbol *Gstart;
extern struct Lsymbol *Lstart;
extern struct Typetable *TypeTable;
extern struct Fieldlist *FieldList;
extern int bindingStart;
extern int oexpl;
extern struct Classtable *ClassTable;
int cflabel = 0;

void red()
{
    printf("\033[1;31m");
}

void green()
{
    printf("\033[1;32m");
}

void yellow()
{
    printf("\033[1;33m");
}

void blue()
{
    printf("\033[1;34m");
}

void reset()
{
    printf("\033[0m");
}

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

void GInstall(char *name, struct Typetable *type, struct Classtable *Ctype, int size, struct paramlist *plist, int isfunc)
{
    struct Gsymbol *newnode = (struct Gsymbol *)malloc(sizeof(struct Gsymbol));
    newnode->name = (char *)malloc(sizeof(name));
    strcpy(newnode->name, name);
    newnode->type = type;
    newnode->Ctype = Ctype;
    newnode->size = size;
    newnode->plist = plist;
    newnode->next = NULL;
    if (isfunc == 0)
        newnode->defined = -1;
    else
        newnode->defined = 0;
    if (Gstart == NULL)
    {
        Gstart = newnode;
        if (oexpl == 0)
        {
            Gstart->binding = 4096;
        }
        else
        {
            Gstart->binding = bindingStart + 1;
        }
        Gstart->plist = plist;
        if (isfunc == 0)
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
    if (isfunc == 0)
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
    LInstall("Vptr", TLookup("NULL"), 1);
    LInstall("SELF", TLookup("NULL"), 1);
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
        if (temp->type != NULL)
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

void typecheck(struct tnode *head, int op)
{
    struct tnode *left = head->left;
    struct tnode *right = head->right;
    struct tnode *middle = head->middle;
    switch (op)
    {
    case PLUS:
    case MINUS:
    case MUL:
    case DIV:
    case MOD:
    case LT:
    case LTE:
    case GT:
    case GTE:
    case AND:
    case OR:
        if (left->type != right->type)
        {
            printf("Type mismatch \n");
            exit(1);
        }
        break;
    case EQ:
    case NEQ:
        if (right->nodetype == _NULLTYPE)
        {
            // printf("The left type is %s\n",left->type->name);
            if (left->type == TLookup("INT") || left->type == TLookup("STR"))
            {
                printf("Cannot assign null to INT or STR\n");
                exit(1);
            }
        }
        else
        {
            if (left->type != right->type)
            {
                printf("The types are different and cannot be compared\n");
                exit(1);
            }
        }
        break;
    case IF:
    case WHILE:
        if (middle->type != TLookup("BOOL"))
        {
            printf("Condition must be of boolean type\n");
            exit(1);
        }
        break;
    case NOT:
        if (left->type != TLookup("INT"))
        {
            printf("Type mismatch in NOT\n");
            exit(1);
        }
        break;

    default:
        break;
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
    if (type == NULL)
    {
        return NULL;
    }
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
    struct Classtable *parent = CLookup(parent_class_name);
    newnode->Parentptr = parent;
    newnode->next = NULL;
    if (parent_class_name != NULL && parent == NULL)
    {
        printf("Cannot inherit from undefined class\n");
        exit(1);
    }
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
    if (parent == NULL)
    {
        newnode->Fieldcount = 0;
        newnode->Methodcount = 0;
        newnode->Memberfield = NULL;
        newnode->Vfuncptr = NULL;
    }
    else
    {
        newnode->Fieldcount = parent->Fieldcount;
        newnode->Methodcount = parent->Methodcount;
        installMemberfields(newnode, parent);
        installVfuncptr(newnode, parent);
    }
    last->next = newnode;
    return newnode;
}

void installMemberfields(struct Classtable *newnode, struct Classtable *parent)
{
    struct Memberfieldlist *flist = parent->Memberfield;
    while (flist != NULL)
    {
        Class_Finstall(newnode, flist->Ctype, flist->type, flist->name);
        flist = flist->next;
    }
}

void installVfuncptr(struct Classtable *newnode, struct Classtable *parent)
{
    struct Memberfunclist *mlist = parent->Vfuncptr;
    while (mlist != NULL)
    {
        Class_Minstall(newnode, mlist->name, mlist->type, mlist->paramlist);
        mlist = mlist->next;
    }
}

struct Classtable *CLookup(char *name)
{
    if (name == NULL)
    {
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

void Class_Finstall(struct Classtable *curr, struct Classtable *cptr, struct Typetable *type, char *name)
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
        curr->Fieldcount = 1;
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
    ++curr->Fieldcount;
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
    if (Class_Mlookup(cptr->Parentptr, name) != NULL)
    {
        newnode->defined = 2;
    }
    else
        newnode->defined = 0;
    struct Memberfunclist *last = cptr->Vfuncptr;
    if (last == NULL)
    {
        newnode->Funcposition = 0;
        struct Memberfunclist *temp = Class_Mlookup(cptr->Parentptr, name);
        if (temp != NULL)
        {
            newnode->flabel = temp->flabel;
        }
        else
        {
            newnode->flabel = ++cflabel;
        }

        cptr->Methodcount = 1;
        cptr->Vfuncptr = newnode;
        return;
    }
    while (last->next != NULL)
    {
        if (!strcmp(last->name, name))
        {
            if (cptr->Parentptr != NULL)
            {
                // printf("Overriding the definition in parent class\n");
                last->flabel = ++cflabel;
                return;
            }
            printf("Redclaration of member function %s\n", name);
            exit(1);
        }
        last = last->next;
    }
    if (!strcmp(last->name, name))
    {
        if (cptr->Parentptr != NULL)
        {
            // printf("Overriding the definition in parent class\n");
            last->flabel = ++cflabel;
            return;
        }
        printf("Redclaration of member function %s\n", name);
        exit(1);
    }
    newnode->Funcposition = last->Funcposition + 1;
    struct Memberfunclist *temp = Class_Mlookup(cptr->Parentptr, name);
    if (temp != NULL)
    {
        newnode->flabel = temp->flabel;
    }
    else
    {
        newnode->flabel = ++cflabel;
    }
    last->next = newnode;
    ++cptr->Methodcount;
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

void checkInherited(struct Classtable *c1, struct Classtable *c2)
{
    if (c1 == NULL)
    {
        printf("it is null\n");
    }
    while (c2 != NULL)
    {
        if (c1 == c2)
        {
            return;
        }
        // printf("The classname is %s and %s\n", c1->name, c2->name);
        c2 = c2->Parentptr;
    }
    printf("Invalid reference to class\n");
    exit(1);
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
/*--initializing---*/
void init(FILE *output)
{
    // printf("here\n");
    fprintf(output, "0\n2056\n0\n0\n0\n0\n0\n0\n");
    fprintf(output, "MOV SP,%d\n", 4095);
    struct Classtable *temp = ClassTable;
    while (temp != NULL)
    {

        struct Memberfunclist *mlist = temp->Vfuncptr;
        while (mlist != NULL)
        {
            fprintf(output, "MOV R0,C%d\n", mlist->flabel);
            fprintf(output, "PUSH R0\n");
            mlist = mlist->next;
        }
        bindingStart = 4095 + (temp->Class_index + 1) * 8;
        if (temp->next != NULL)
            fprintf(output, "MOV SP,%d\n", bindingStart);
        temp = temp->next;
    }
}

void initExpl(FILE *output)
{
    fprintf(output, "0\n2056\n0\n0\n0\n0\n0\n0\n");
    fprintf(output, "MOV SP, %d\n", getSP() - 1);
    fprintf(output, "PUSH R0\n");
    fprintf(output, "CALL MAIN\n");
    // fprintf(output, "MOV R0, 10\nPUSH R0\nINT 10\n");
    fprintf(output, "POP R0\n");
    fprintf(output, "INT 10\n");
}

void initGlobal(FILE *output)
{

    fprintf(output, "MOV SP, %d\n", getSP() - 1);
    fprintf(output, "PUSH R0\n");
    fprintf(output, "CALL MAIN\n");
    // fprintf(output, "MOV R0, 10\nPUSH R0\nINT 10\n");
    fprintf(output, "POP R0\n");
    fprintf(output, "INT 10\n");
}

void checkAccess(struct Typetable *currType, struct Classtable *currClass, char *name)
{
    int isRecord = 1;
    int isClass = 1;
    if (currClass == NULL)
    {
        isClass = 0;
    }
    if (currType == NULL)
    {
        isRecord = 0;
    }
    else if (currType->fields == NULL)
    {
        isRecord = 0;
    }
    if (isRecord == 0 && isClass == 0)
    {
        printf("%s is not a class or record\n", name);
        exit(1);
    }
}

int checkDefined()
{
    int flag = 0;
    struct Classtable *temp = ClassTable;
    blue();
    while (temp != NULL)
    {

        struct Memberfunclist *flist = temp->Vfuncptr;
        while (flist != NULL)
        {
            if (flist->defined == 0)
            {
                printf("Warning => function %s is declared but not defined in %s\n", flist->name, temp->name);
                flag++;
            }
            flist = flist->next;
        }
        temp = temp->next;
    }
    struct Gsymbol *temp2 = Gstart;
    while (temp2 != NULL)
    {
        if (temp2->defined == 0)
        {
            printf("Warning => function %s is declared but not defined\n", temp2->name);
            flag++;
        }
        temp2 = temp2->next;
    }
    reset();
    if (flag == 0)
    {
        return 0;
    }
    else
        return 1;
}

void Organize(char *f1, char *f2)
{
    char ch;
    FILE *output = fopen(f1, "a");
    FILE *temp = fopen(f2, "r");
    while ((ch = fgetc(temp)) != EOF)
        fputc(ch, output);
    fclose(temp);
    fclose(output);
}