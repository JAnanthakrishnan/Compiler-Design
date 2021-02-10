%{
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    int linecount = 0;
    int numcount = 0;
    int pass = 0;
    FILE *output;
    struct node {
        char *label;
        int address;
        struct node* next;
    };
    struct node* label_table = NULL;
    void insert(struct node** label_table,char* label,int address);
    void display(struct node* label_table);
    int search(struct node* label_table,char *s);

%}
letter [a-zA-Z]+
digit  [0-9]
identifier {letter}({digit}|{letter})+

%%
"CALL 0"                            {
                                        if(pass){
                                            fprintf(output,"%s",yytext);
                                        }
                                    }
"JMP "{identifier}                  {
                                        if(pass){
                                            int address = search(label_table,yytext+4);
                                            fprintf(output,"JMP %d",address);

                                        }
                                    }
"JZ R"{digit}","{identifier}        {
                                        if(pass){
                                            int address = search(label_table,yytext+6);
                                            char *label = yytext+6;
                                            yytext[strlen(yytext)-strlen(label)] ='\0';
                                            fprintf(output,"%s",yytext);
                                            fprintf(output,"%d",address);

                                        }
                                    }
"JNZ R"{digit}","{identifier}       {
                                        if(pass){
                                            int address = search(label_table,yytext+6);
                                            char *label = yytext+6;
                                            yytext[strlen(yytext)-strlen(label)] ='\0';
                                            fprintf(output,"%s",yytext);
                                            fprintf(output,"%d",address);

                                        }
                                    }
{identifier}":""\n"      {if(!pass){ yytext[strlen(yytext)-2]='\0';insert(&label_table,yytext,linecount);}}
"\n"                                {
                                        if(!pass)
                                        {
                                            linecount++;
                                            fprintf(output,"%s",yytext);
                                        }
                                        else{
                                            fprintf(output,"%s",yytext);
                                        }
                                    }
.*                                  {fprintf(output,"%s",yytext);}

%%
int yywrap(){
    if(pass==0){
        display(label_table);
        yyin = fopen("output.xsm","r");
        output = fopen("final.xsm","w");
        pass = 1;
        return 0;
    }
    return 1;

}
void insert(struct node** label_table,char* label,int address){
    struct node* newnode = (struct node*) malloc(sizeof(struct node));
    newnode->label = (char*) malloc(sizeof(label));
    strcpy(newnode->label,label);
    newnode->address = 2056 + 2*(address-8);
    newnode->next = *label_table;
    *label_table = newnode;
}
void display (struct node* label_table){
    struct node* temp = label_table;
    while(temp!=NULL){
        printf("%s ",temp->label);
        printf("%d ",temp->address);
        temp = temp->next;
    }
}
int search (struct node* label_table, char *s){
    struct node* temp = label_table;
    printf("Search = %s\n",s);
    while(temp!=NULL){
        if(!strcmp(temp->label,s)){
            return temp->address;
        }
        temp= temp->next;
    }
}
int main(int argc, char* argv[]) {
	if(argc<2){
		printf("Input file is required\n");
		exit(1);
	}
	else {
		yyin = fopen(argv[1],"r");
		if(!yyin)
			{
				printf("Input file is invalid\n");
				exit(1);
			}
	}
	output = fopen("translated.xsm","w");
	if(!output){
		printf("Unable to open output file\n");
		exit(1);
	}
	yylex();
    
	return 0;
}