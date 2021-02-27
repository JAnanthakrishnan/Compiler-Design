/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    START = 258,
    END = 259,
    WRITE = 260,
    READ = 261,
    ASSIGN = 262,
    PLUS = 263,
    MINUS = 264,
    MUL = 265,
    DIV = 266,
    NUM = 267,
    ID = 268,
    IF = 269,
    THEN = 270,
    ELSE = 271,
    ENDIF = 272,
    WHILE = 273,
    DO = 274,
    ENDWHILE = 275,
    DECL = 276,
    ENDDECL = 277,
    INT = 278,
    STR = 279,
    STRING = 280,
    LT = 281,
    GT = 282,
    LTE = 283,
    GTE = 284,
    EQ = 285,
    NEQ = 286,
    CONTINUE = 287,
    BREAK = 288,
    MOD = 289
  };
#endif
/* Tokens.  */
#define START 258
#define END 259
#define WRITE 260
#define READ 261
#define ASSIGN 262
#define PLUS 263
#define MINUS 264
#define MUL 265
#define DIV 266
#define NUM 267
#define ID 268
#define IF 269
#define THEN 270
#define ELSE 271
#define ENDIF 272
#define WHILE 273
#define DO 274
#define ENDWHILE 275
#define DECL 276
#define ENDDECL 277
#define INT 278
#define STR 279
#define STRING 280
#define LT 281
#define GT 282
#define LTE 283
#define GTE 284
#define EQ 285
#define NEQ 286
#define CONTINUE 287
#define BREAK 288
#define MOD 289

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 15 "ast.y"

    struct tnode* tree;

#line 129 "y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
