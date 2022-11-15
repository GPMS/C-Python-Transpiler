%{
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>


int yyerror(const char *s);
int yylex(void);
int errorc = 0;
extern FILE *yyin;

typedef struct {
    char *name;
    int token;
} Symbol;

enum NodeType {NFUNC, NFUNCCALL, NIF, NSTRUCT, NRETURN, NIDENT, NOPERB, NOPERBL,
    NCONST, NARGS, NNOARGS, NARG, NTYPENORMAL, NTYPECUSTOM, NFIELDS, NSTMTS,
    NINCLUDE, NPROG, NDEC, NATTRIB, NPAREN, NWHILE, NACCESS,
    NSTRING, NPARAM, NPARAMS};

typedef struct Node {
    int id;
    enum NodeType type;
    char *label;
    Symbol *symbol;
    int constvalue;
    int numChild;
    struct Node *child[1]; // ultimo campo
} Node;

int numSymbols = 0;
Symbol symbols[100];
Symbol *NewSymbol(char *name, int token);
Symbol *SymbolExist(char *name);
Node *NewNode(enum NodeType type, char *label, int child);
void Debug(Node *root);
%}

%locations
%define parse.error verbose

/* atributos dos tokens */
%union {
    char *name;
    int value;
    struct Node *no;
}

%token NUMBER IDENT TINT TFLOAT STRING RETURN
%token STRUCT IF ELSE WHILE
%token OR AND LESS GREATER LESS_OR_EQUAL GREATER_OR_EQUAL

%type <name> IDENT STRING
%type <value> NUMBER
%type <no> prog arit expr term factor stmts stmt type args arg
%type <no> fields field logica terml term2l term3l factorl exprl
%type <no> params param

%start prog

%%

prog : stmts {
    if (errorc > 0)
    {
        printf("%d error(s) found\n", errorc);
    }
    else
    {
        Node *root = NewNode(NPROG, "prog", 1);
        root->child[0] = $1;
        Debug(root);
    }
     }
     ;

stmts : stmts stmt {
            $$ = NewNode(NSTMTS, "stmts", 2);
            $$->child[0] = $1;
            $$->child[1] = $2;
        }

      | stmt { $$ = $1; }
      ;

stmt : type IDENT '=' arit ';' {
            Symbol *s = SymbolExist($2);
            if (!s)
                s = NewSymbol($2, IDENT);

            $$ = NewNode(NATTRIB, "=", 2);
            $$->child[0] = NewNode(NIDENT, $2, 0);
            $$->child[0]->symbol = s;
            $$->child[1] = $4;
       }
     | IDENT '=' arit ';' {
            Symbol *s = SymbolExist($1);
            if (!s)
                s = NewSymbol($1, IDENT);

            $$ = NewNode(NATTRIB, "=", 2);
            $$->child[0] = NewNode(NIDENT, $1, 0);
            $$->child[0]->symbol = s;
            $$->child[1] = $3;
     }
     | IDENT'.'IDENT '=' arit ';' {
            Symbol *s1 = SymbolExist($1);
            if (!s1)
                s1 = NewSymbol($1, IDENT);

            Symbol *s2 = SymbolExist($3);
            if (!s2)
                s2 = NewSymbol($3, IDENT);

            $$ = NewNode(NATTRIB, "=", 2);

            $$->child[0] = NewNode(NACCESS, ".", 2);
            $$->child[0]->child[0] = NewNode(NIDENT, $1, 0);
            $$->child[0]->child[0]->symbol = s1;
            $$->child[0]->child[1] = NewNode(NIDENT, $3, 0);
            $$->child[0]->child[1]->symbol = s2;

            $$->child[1] = $5;
     }

     | type IDENT ';' {
            $$ = NewNode(NDEC, "declare", 2);
            $$->child[0] = $1;
            $$->child[1] = NewNode(NIDENT, $2, 0);
       }

     | type IDENT '(' args ')' '{' stmts '}' {
            $$ = NewNode(NFUNC, $2, 2);
            $$->child[0] = $4;
            $$->child[1] = $7;
       }
     | IDENT '(' params ')' ';' {
            $$ = NewNode(NFUNCCALL, $1, 1);
            $$->child[0] = $3;
     }

    /* #include <stdio.h> */
     | '#' IDENT LESS IDENT '.' IDENT GREATER {
            $$ = NewNode(NINCLUDE, "include", 0);
       }

     | RETURN arit ';' {
            $$ = NewNode(NRETURN, "return", 1);
            $$->child[0] = $2;
       }

     /* struct { int a; } exemplo; */
     | STRUCT IDENT '{' fields '}' ';' {
            $$ = NewNode(NSTRUCT, "struct", 2);
            $$->child[0] = NewNode(NIDENT, $2, 0);
            $$->child[1] = $4;
       }

     | IF '(' logica ')' '{' stmts '}' {
            $$ = NewNode(NIF, "ifblock", 2);
            $$->child[0] = $3;
            $$->child[1] = $6;
       }
     | WHILE '(' logica ')' '{' stmts '}' {
            $$ = NewNode(NWHILE, "whileblock", 2);
            $$->child[0] = $3;
            $$->child[1] = $6;
       }
     ;

fields : field fields {
            $$ = NewNode(NFIELDS, "fields", 2);
            $$->child[0] = $1;
            $$->child[1] = $2;
         }

       | field	{ $$ = $1; }
       ;

field : type IDENT ';' {
            $$ = NewNode(NDEC, $2, 2);
            $$->child[0] = $1;
            $$->child[1] = NewNode(NIDENT, $2, 0);
         }
       ;

type : TINT		{ $$ = NewNode(NTYPENORMAL, "int", 0); }
     | TFLOAT	{ $$ = NewNode(NTYPENORMAL, "float", 0); }
     | STRUCT IDENT { $$ = NewNode(NTYPECUSTOM, $2, 0); }
     ;

args : arg ',' args {
            $$ = NewNode(NARGS, "args", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

     | arg { $$ = $1; }
     | %empty { $$ = NewNode(NNOARGS, "noargs", 0); }
     ;

arg : type IDENT {
        $$ = NewNode(NARG, "arg", 2);
        $$->child[0] = $1;
        $$->child[1] = NewNode(NIDENT, $2, 0);
      }
    ;

params : param ',' params {
            $$ = NewNode(NPARAMS, "params", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
         }

       | param { $$ = $1; }
       | %empty { $$ = NewNode(NNOARGS, "noparams", 0); }
       ;

param  : IDENT {
            $$ = NewNode(NPARAM, "param", 1);
            $$->child[0] = NewNode(NIDENT, $1, 0);
            $$->child[0]->symbol = NULL;
          }
       | STRING {
            $$ = NewNode(NPARAM, "param", 1);
            $$->child[0] = NewNode(NSTRING, $1, 0);
            $$->child[0]->symbol = NULL;
         }
       | NUMBER {
            $$ = NewNode(NPARAM, "param", 1);
            $$->child[0] = NewNode(NCONST, "const", 0);
            $$->child[0]->constvalue = $1;
            $$->child[0]->symbol = NULL;
         }
       ;

logica : exprl
       | exprl error
       ;

exprl : exprl OR terml  {
            $$ = NewNode(NOPERBL, "or", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }
     | terml	{ $$ = $1; }
     ;

terml : terml AND term2l {
            $$ = NewNode(NOPERBL, "and", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

       | term2l { $$ = $1; }
       ;

term2l : term2l LESS term3l {
            $$ = NewNode(NOPERBL, "<", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }
       | term2l LESS_OR_EQUAL term3l {
            $$ = NewNode(NOPERBL, "<=", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }
       | term3l { $$ = $1; }

term3l : term3l GREATER factorl {
            $$ = NewNode(NOPERBL, ">", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }
       | term3l GREATER_OR_EQUAL factorl {
            $$ = NewNode(NOPERBL, ">=", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }
       | factorl { $$ = $1; }

factorl : '(' exprl ')' {
            $$ = NewNode(NPAREN, "()", 1);
            $$->child[0] = $2;
         }
        | arit { $$ = $1; }
        ;

arit : expr	{ $$ = $1; }
     | expr error
     ;

expr : expr '+' term  {
            $$ = NewNode(NOPERB, "+", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

     | expr '-' term {
            $$ = NewNode(NOPERB, "-", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

     | term	{ $$ = $1; }
     ;

term : term '*' factor {
            $$ = NewNode(NOPERB, "*", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

     | term '/' factor {
            $$ = NewNode(NOPERB, "/", 2);
            $$->child[0] = $1;
            $$->child[1] = $3;
       }

     | factor			{ $$ = $1; }
     ;

factor : '(' expr ')' {
            $$ = NewNode(NPAREN, "()", 1);
            $$->child[0] = $2;
         }

       | NUMBER {
            $$ = NewNode(NCONST, "const", 0);
            $$->constvalue = $1;
         }
       | IDENT {
            Symbol *s = SymbolExist($1);
            if (!s)
                s = NewSymbol($1, IDENT);
            $$ = NewNode(NIDENT, "IDENT", 0);
            $$->symbol = s;
         }
       | IDENT'.'IDENT {
            Symbol *s1 = SymbolExist($1);
            if (!s1)
                s1 = NewSymbol($1, IDENT);

            Symbol *s2 = SymbolExist($3);
            if (!s2)
                s2 = NewSymbol($3, IDENT);

            $$ = NewNode(NACCESS, ".", 2);
            $$->child[0] = NewNode(NIDENT, $1, 0);
            $$->child[0]->symbol = s1;
            $$->child[1] = NewNode(NIDENT, $3, 0);
            $$->child[1]->symbol = s2;
       }
       ;

%%

int yywrap()
{
    return 1;
}

/*
int yyerror(const char *s)
{
    errorc++;
    printf("%d:erro %d: %s\n", errorc, s);
    return 1;
}
*/

Symbol *NewSymbol(char *name, int token)
{
    symbols[numSymbols].name = name;
    symbols[numSymbols].token = token;
    Symbol *result = &symbols[numSymbols];
    numSymbols++;
    return result;
}

Symbol *SymbolExist(char *name)
{
    // busca linear, nao eficiente
    for(int i = 0; i < numSymbols; i++)
    {
        if (strcmp(symbols[i].name, name) == 0)
            return &symbols[i];
    }
    return NULL;
}

Node *NewNode(enum NodeType type, char *label, int child)
{
    static int nid = 0;
    int s = sizeof(Node);
    if (child > 1)
        s += sizeof(Node*) * (child-1);
    Node *n = (Node*)calloc(1, s);
    n->id = nid++;
    n->type = type;
    n->label = label;
    n->numChild = child;
    return n;
}

void TranslateArithLogic(FILE* file, Node *n)
{
    switch(n->type)
    {
        case NPAREN:
            fputc('(', file);
            TranslateArithLogic(file, n->child[0]);
            putc(')', file);
            break;
        case NOPERB:
        case NOPERBL:
            TranslateArithLogic(file, n->child[0]);
            fprintf(file, " %s ", n->label);
            TranslateArithLogic(file, n->child[1]);
            break;
        case NIDENT:
            fprintf(file, "%s", n->symbol->name);
            break;
        case NCONST:
            fprintf(file, "%d", n->constvalue);
            break;
        case NACCESS:
            fprintf(file, "%s.%s", n->child[0]->symbol->name,
                                   n->child[1]->symbol->name);
    }
}

int PrintParam(FILE* file, Node* n, int index, int numParams)
{
    if (n->type == NPARAM)
    {
        numParams++;
        if (numParams != index)
        {
            return numParams;
        }
        switch (n->child[0]->type)
        {
            case NIDENT:
            case NSTRING:
                fprintf(file, "%s", n->child[0]->label);
                return 1;
                break;
            case NCONST:
                fprintf(file, "%d", n->child[0]->constvalue);
                return 1;
                break;
        }
    }
    if (n->type == NPARAMS)
    {
        numParams = PrintParam(file, n->child[0], index, numParams);
        PrintParam(file, n->child[1], index, numParams);
    }
}

int PrintParams(FILE* file, Node* n, int* numParams, int start, int end)
{
    if (n->type == NPARAM)
    {
        *numParams += 1;
        if (*numParams < start || (end > 0 && *numParams > end))
        {
            return 0;
        }
        switch (n->child[0]->type)
        {
            case NIDENT:
            case NSTRING:
                fprintf(file, "%s", n->child[0]->label);
                return 1;
                break;
            case NCONST:
                fprintf(file, "%d", n->child[0]->constvalue);
                return 1;
                break;
        }
    }
    if (n->type == NPARAMS)
    {
        int printed = PrintParams(file, n->child[0], numParams, start, end);

        if (printed) fputc(',', file);

        PrintParams(file, n->child[1], numParams, start, end);
    }
}

void TranslateArgs(FILE* file, Node* n)
{
    if (n->type == NARG)
    {
        fprintf(file, "%s", n->child[1]->label);
    }
    if (n->type == NARGS)
    {
        TranslateArgs(file, n->child[0]);
        fputc(',', file);
        TranslateArgs(file, n->child[1]);
    }
}

void PrintLevel(FILE* file, int level)
{
    for(int i = 0; i < level; i++)
    {
        fprintf(file, "\t");
    }
}

void Translate(FILE* file, int level, Node *n)
{
    switch (n->type)
    {
        case NATTRIB:
            PrintLevel(file, level);

            if (n->child[0]->type == NACCESS)
            {
                fprintf(file, "%s.%s = ", n->child[0]->child[0]->symbol->name,
                                          n->child[0]->child[1]->symbol->name);
            }
            else
            {
                fprintf(file, "%s = ", n->child[0]->symbol->name);
            }
            TranslateArithLogic(file, n->child[1]);
            fprintf(file, "\n");
            break;
        case NDEC:
            PrintLevel(file, level);
            if (n->child[0]->type == NTYPECUSTOM)
            {
                fprintf(file, "%s = %s()\n", n->child[1]->label,
                                             n->child[0]->label);
            }
            else
            {
                fprintf(file, "%s = None\n", n->child[1]->label);
            }
            break;
        case NIF:
            PrintLevel(file, level);

            fprintf(file, "if ");
            TranslateArithLogic(file, n->child[0]);
            fprintf(file, ":\n");

            Translate(file, level+1, n->child[1]);
            break;
        case NWHILE:
            PrintLevel(file, level);

            fprintf(file, "while ");
            TranslateArithLogic(file, n->child[0]);
            fprintf(file, ":\n");

            Translate(file, level+1, n->child[1]);
            break;
        case NFUNCCALL:
            PrintLevel(file, level);
            if (strcmp(n->label, "printf") == 0)
            {
                fprintf(file, "print(");
                if (n->child[0]->type != NNOARGS)
                {
                    PrintParam(file, n->child[0], 1, 0);
                    fprintf(file, " % (");
                    int numParams = 0;
                    PrintParams(file, n->child[0], &numParams, 2, 0);
                    fprintf(file, "), end = \"\"");
                }
            }
            else
            {
                fprintf(file, "%s(", n->label);
                if (n->child[0]->type != NNOARGS)
                {
                    int numParams = 0;
                    PrintParams(file, n->child[0], &numParams, 1, 0);
                }
            }
            fprintf(file, ")\n");
            break;
        case NFUNC:
            PrintLevel(file, level);

            fprintf(file, "def %s(", n->label);
            if (n->child[0]->type != NNOARGS)
            {
                TranslateArgs(file, n->child[0]);
            }
            fprintf(file, "):\n");

            Translate(file, level+1, n->child[1]);
            break;
        case NSTRUCT:
            PrintLevel(file, level);
            fprintf(file, "class %s:\n", n->child[0]->label);
            Translate(file, level+1, n->child[1]);
            break;
        case NFIELDS:
            Translate(file, level, n->child[0]);
            Translate(file, level, n->child[1]);
            break;
        case NRETURN:
            PrintLevel(file, level);

            fprintf(file, "return ");
            TranslateArithLogic(file, n->child[0]);
            fprintf(file, "\n");
        default:
            //printf("#%s\n", n->label);
            for(int i=0; i < n->numChild; i++)
                Translate(file, level, n->child[i]);
    }
}

void PrintTree(FILE* file, Node *n)
{
    if (n->symbol)
    {
        fprintf(file, "\tn%d [label=\"%s\"];\n", n->id, n->symbol->name);
    }
    else if (strcmp(n->label, "const") == 0)
    {
        fprintf(file, "\tn%d [label=\"%d\"];\n", n->id, n->constvalue);
    }
    else
    {
        if (n->type == NSTRING)
        {
            // skip ""
            fprintf(file, "\tn%d [label=\"", n->id);
            for (int i = 1, len=strlen(n->label)-1; i < len; i++)
                fputc(n->label[i], file);
            fprintf(file, "\"];\n");
        }
        else
        {
            fprintf(file, "\tn%d [label=\"%s\"];\n", n->id, n->label);
        }
    }

    for(int i=0; i < n->numChild; i++)
        PrintTree(file, n->child[i]);
    for(int i=0; i < n->numChild; i++)
        fprintf(file, "\tn%d -- n%d\n", n->id, n->child[i]->id);
}

void Debug(Node *no)
{
    FILE* table = fopen("output/table.txt", "w");
    fprintf(table, "Simbolos: \n");
    for(int i = 0; i < numSymbols; i++)
    {
        fprintf(table, "\t%s\n", symbols[i].name);
    }
    fclose(table);

    /* graph prog { ... } */
    FILE* graph = fopen("output/graph.dot", "w");
    fprintf(graph, "graph prog {\n");
    PrintTree(graph, no);
    fprintf(graph, "}\n");
    fclose(graph);

    FILE* output = fopen("output/output.py", "w");
    Translate(output, 0, no);
    fprintf(output, "main()");
    fclose(output);
}

static const char* OUTPUT_DIR = "output";

int main(int argc, char *argv[])
{
    DIR* dir = opendir(OUTPUT_DIR);
    if (dir) {
        closedir(dir);
    } else if (ENOENT == errno) {
        fprintf(stderr, "No output dir, creating...\n");
        mkdir(OUTPUT_DIR, 0777);
    } else {
        perror("opendir() failed");
        exit(1);
    }

    if (argc > 1)
    {
        yyin = fopen(argv[1], "r");
        if (!yyin)
        {
            perror("Could not load file! ");
        }
    }
    yyparse();
    if (yyin)
    {
        fclose(yyin);
    }
}
