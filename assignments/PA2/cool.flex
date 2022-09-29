/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <vector>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

static int comment_caller;

static std::vector<char> string_array;

static int string_caller;

/*
 *  Add Your own definitions here
 */

%}
%option noyywrap
/*
 * Define names for regular expressions here.
 */


DARROW          =>
CLASS           class
ELSE            else
FI              fi
IF              if
IN              in
INHERITS        inherits
LET             let
LOOP            loop
POOL            pool
THEN            then
WHILE           while
CASE            case
ESAC            esac
OF              of
NEW             new
ISVOID          isvoid
ASSIGN          <-
NOT             not
LE              <=

%x COMMENT
%x STRING
%x STRING_ESCAPE

%%

{DARROW} {return (DARROW);}
{CLASS} {return (CLASS);}
{ELSE} {return (ELSE);}
{FI} {return (FI);}
{IF} {return (IF);}
{IN} {return (IN);}
{INHERITS} {return (INHERITS);}
{LET} {return (LET);}
{LOOP} {return (LOOP);}
{POOL} {return (POOL);}
{THEN} {return (THEN);}
{WHILE} {return (WHILE);}
{CASE} {return (CASE);}
{ESAC} {return (ESAC);}
{OF} {return (OF);}
{NEW} {return (NEW);}
{ISVOID} {return (ISVOID);}
{ASSIGN} {return (ASSIGN);}
{NOT} {return (NOT);}
{LE} {return (LE);}

[\[\]\'>] {
  cool_yylval.error_msg = yytext;
  return (ERROR);
}

[ \t\f\r\v] {}

\n {curr_lineno++;}


--.*$ {}

"(*" {
  comment_caller = INITIAL;
  BEGIN(COMMENT);
}

<COMMENT>"*)" {
  BEGIN(comment_caller);
}

\*\) {
    cool_yylval.error_msg = "unmatched *)";
    return (ERROR);
}

<COMMENT>[^()]


<COMMENT>[^(\*\))] {
  if(yytext[0] == '\n'){
    curr_lineno++;
  }
}

<COMMENT><<EOF>> {
  BEGIN(comment_caller);
  cool_yylval.error_msg = "EOF IN COMMENT";
  return (ERROR);
}

[a-z_][A-Za-z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext,yyleng);
  return (OBJECTID);
}

[A-Z_][A-Za-z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext,yyleng);
  return (TYPEID);
}

t[Rr][Uu][Ee] {
  cool_yylval.boolean = true;
  return (BOOL_CONST);
}

F[Aa][Ll][Ss][Ee] {
  cool_yylval.boolean = false;
  return (BOOL_CONST);
}


[0-9][0-9]* {
  cool_yylval.symbol = idtable.add_string(yytext,yyleng);
  return (INT_CONST);
}

\" {
  string_caller = INITIAL;
  string_array.clear();
  BEGIN(STRING);
  }

<STRING>[^\"\\]*\" {
  string_array.insert(string_array.end(),yytext,yytext + yyleng - 1);
  cool_yylval.symbol = idtable.add_string(&string_array[0],string_array.size());
  BEGIN(string_caller);
  return (STR_CONST);
}

<STRING>[^\"\\]*\\ {
  string_array.insert(string_array.end(),yytext,yytext + yyleng - 1);
  BEGIN(STRING_ESCAPE);
}

<STRING_ESCAPE>n {
    // cout << "escape \\n !" << endl;
    string_array.push_back('\n');
    BEGIN(STRING);
}

<STRING_ESCAPE>b {
    string_array.push_back('\b');
    BEGIN(STRING);
}

<STRING_ESCAPE>t {
    string_array.push_back('\t');
    BEGIN(STRING);
}

<STRING_ESCAPE>f {
    string_array.push_back('\f');
    BEGIN(STRING);
}

<STRING_ESCAPE>. {
    string_array.push_back(yytext[0]);
    BEGIN(STRING);
}

<STRING_ESCAPE>\n {
    string_array.push_back('\n');
    ++curr_lineno;
    BEGIN(STRING);
}

<STRING_ESCAPE>0 {
    cool_yylval.error_msg = "String contains null character";
    BEGIN(STRING);
    return (ERROR);
}

<STRING>[^\"\\]*$ {
  string_array.insert(string_array.end(),yytext,yytext + yyleng - 1);
  cool_yylval.error_msg = "字符串无右引号(underminated string constant)";
  BEGIN(string_caller);
  curr_lineno++;
  return (ERROR);
}

<STRING_ESCAPE><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(STRING);
    return (ERROR);
}
<STRING><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(string_caller);
    return (ERROR);
}

. {
  return yytext[0];
}


%%
