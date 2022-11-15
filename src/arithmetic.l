
%{
#include "arithmetic.tab.h"
%}

%option yylineno

%%

[ \t\n\r]		            {}
"//".*			            {}
"."                         { return '.'; }
"+" 			            { return '+'; }
"-"				            { return '-'; }
"*" 			            { return '*'; }
"/"				            { return '/'; }
">"				            { return GREATER; }
">="				        { return GREATER_OR_EQUAL; }
"<"				            { return LESS; }
"<="				        { return LESS_OR_EQUAL; }
"(" 			            { return '('; }
")"				            { return ')'; }
"int"			            { return TINT; }
"float"			            { return TFLOAT; }
"return"		            { return RETURN; }
"struct"		            { return STRUCT; }
"if"                        { return IF; }
"else"                      { return ELSE; }
"while"                     { return WHILE; }
"||"                        { return OR; }
"&&"                        { return AND; }
[0-9]+                      {
                                yylval.value = atoi(yytext);
                                return NUMBER;
                            }
[a-zA-Z_][a-zA-Z0-9_]*      {
                                yylval.name = strdup(yytext);
                                return IDENT;
                            }
\"([^\\\"]|\\.)*\"          {
                                yylval.name = strdup(yytext);
                                return STRING;
                            }
.				            { return yytext[0]; }

%%

void yyerror(const char *str)
{
    fprintf(stderr,"Error | Line: %d\n%s\n",yylineno,str);
}
