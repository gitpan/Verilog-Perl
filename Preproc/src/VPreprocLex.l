%option noyywrap align interactive
%option stack
%option noc++
%option prefix="VPreprocLex"
%{
/* $Revision: #8 $$Date: 2002/08/07 $$Author: wsnyder $
 ******************************************************************************
 * DESCRIPTION: Verilog Preprocessor Lexer
 * 
 * This file is part of Verilog-Perl.  
 * 
 * Author: Wilson Snyder <wsnyder@wsnyder.org>
 * 
 * Code available from: http://veripool.com/systemperl
 * 
 ******************************************************************************
 * 
 * This program is Copyright 2001 by Wilson Snyder.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either the GNU General Public License or the
 * Perl Artistic License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * If you do not have a copy of the GNU General Public License write to
 * the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
 * MA 02139, USA.
 *									     
 *****************************************************************************
 * Do not use Flex in C++ mode.  It has bugs with yyunput() which result in
 * lost characters.
 *****************************************************************************/

#include "VPreprocLex.h"
#include <stdio.h>
#include <iostream>

VPreprocLex* VPreprocLex::s_currentLexp = NULL;	// Current lexing point

#define linenoInc()  { VPreprocLex::s_currentLexp->linenoInc(); }
int  keepComments() { return VPreprocLex::s_currentLexp->m_keepComments; }
bool pedantic() { return VPreprocLex::s_currentLexp->m_pedantic; }
void yyerror(char* msg) { VPreprocLex::s_currentLexp->m_curFilelinep->error(msg); }

/**********************************************************************/
%}

%x CMTMODE
%x STRMODE
%x DEFMODE

WHITESPACE	[ \t\r\f]
NEWLINE		[\n]
QUOTE		[\"]
BACKSLASH	[\\]
SYMBOL		[a-zA-Z_][a-zA-Z0-9_$]*

	/**************************************************************/
%%

^{WHITESPACE}*"`line"{WHITESPACE}+.*{NEWLINE}	{ VPreprocLex::s_currentLexp->lineDirective(yytext); }

	/* Special directives we recognise */
"`include"	{ return(VP_INCLUDE); }
"`ifdef"	{ return(VP_IFDEF); }
"`ifndef"	{ return(VP_IFNDEF); }
"`else"		{ return(VP_ELSE); }
"`elsif"	{ return(VP_ELSIF); }
"`endif"	{ return(VP_ENDIF); }
"`undef"	{ return(VP_UNDEF); }
"`define"	{ return(VP_DEFINE); }

	/* Optional directives we recognise */
"`__FILE__"	{ if (!pedantic()) {
    		     yytext = (char*)VPreprocLex::s_currentLexp->m_curFilelinep->cfilename();
    		     yyleng = strlen(yytext); return (VP_TEXT);
                  } else return(VP_DEFREF); }
"`__LINE__"	{ if (!pedantic()) {
                     static char buf[10];
		     sprintf(buf, "%d",VPreprocLex::s_currentLexp->m_curFilelinep->lineno());
                     yytext = buf; yyleng = strlen(yytext); return (VP_TEXT);
                  } else return(VP_DEFREF); }
"`error"	{ if (!pedantic()) return (VP_ERROR); else return(VP_DEFREF); }

	/* One line comments. */
"//"[^\n]* 		{ if (keepComments()) return (VP_COMMENT); }

	/* C-style comments. */
"/*"			{ yy_push_state(CMTMODE); yymore(); }
<CMTMODE>"*/"		{ yy_pop_state(); if (keepComments()) return(VP_COMMENT); }
<CMTMODE>{NEWLINE}	{ linenoInc(); if (keepComments()) yymore(); else { yytext="\n"; yyleng=1; return(VP_WHITE); } }
<CMTMODE>.		{ yymore(); }
<CMTMODE><<EOF>>	{ yyerror("EOF in '/* ... */' block comment\n");
			  yyleng = 0; yyterminate(); }

	/* Pass-through strings */
{QUOTE}			{ yy_push_state(STRMODE); yymore(); }
<STRMODE>{NEWLINE}	{ linenoInc();
			  yyerror("Unterminated string");
			  BEGIN(INITIAL); }
<STRMODE>[^\"\\]	{ yymore(); }
<STRMODE>{BACKSLASH}.	{ yymore(); }
<STRMODE>{QUOTE} 	{ yy_pop_state(); return (VP_STRING); }

	/* Reading definition */
<DEFMODE>"/*"		{ yy_push_state(CMTMODE); yymore(); }
<DEFMODE>"//"[^\n]*	{ if (keepComments()) return (VP_COMMENT);}
<DEFMODE>{NEWLINE}	{ linenoInc();
			  yy_pop_state();
			  return (VP_DEFVALUE); }	/* Note contains a return */
<DEFMODE>[^\/\*\n\m\\]+	|
<DEFMODE>[\\][^\n]	|
<DEFMODE>.		{ VPreprocLex::s_currentLexp->appendDefValue(yytext,yyleng); }
<DEFMODE>[\\]\n		{ linenoInc(); VPreprocLex::s_currentLexp->appendDefValue(" ",1); }

	/* Define calls */
"`"{SYMBOL}		{ return (VP_DEFREF); }

	/* Generics */
{SYMBOL}      		{ return (VP_SYMBOL); }
     /* [\m]      		{ } */
[\n]	 		{ linenoInc(); return(VP_WHITE); }	/* Not {NEWLINE}, too long */
{WHITESPACE}+		{ return (VP_WHITE); }
.			{ return (VP_TEXT); }
%%

void VPreprocLex::setStateDefValue() {
    // Enter define value state
    yy_push_state(DEFMODE);
    m_defValue = "";
}

void VPreprocLex::appendDefValue(const char* textp, int len) {
    // Append given text to current definition value being formed
    m_defValue.append(textp,len);
}

void VPreprocLex::lineDirective(const char* textp) {
    while (*textp && isspace(*textp)) textp++;
    if (0==strncmp(textp,"`line",strlen("`line"))) textp+=strlen("`line");
    while (*textp && (isspace(*textp) || *textp=='"')) textp++;

    // Grab linenumber
    const char *ln = textp;
    while (*textp && !isspace(*textp)) textp++;
    if (isdigit(*ln)) {
	m_curFilelinep = m_curFilelinep->create(atoi(ln));
    }
    while (*textp && (isspace(*textp) || *textp=='"')) textp++;

    // Grab filename
    const char *fn = textp;
    while (*textp && !(isspace(*textp) || *textp=='"')) textp++;
    if (textp != fn) {
	string newfilename; newfilename.append(fn, (textp-fn));
	m_curFilelinep = m_curFilelinep->create(newfilename, m_curFilelinep->lineno());
    }
}

/*###################################################################
 * Local Variables:
 * mode: C
 * End:
 */
