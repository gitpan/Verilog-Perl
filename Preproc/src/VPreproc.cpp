#ident "$Revision: #1 $$Date: 2002/12/16 $$Author: lab $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Internal implementation of default preprocessor
//
// Code available from: http://www.veripool.com/verilog-perl
//
// Authors: Wilson Snyder
//
//*************************************************************************
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License.
//
// Verilator is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Verilator; see the file COPYING.  If not, write to
// the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111-1307, USA.
//
//*************************************************************************

#include <stdio.h>
#include <fstream>
#include <stack>
#include <map>

#include "VPreproc.h"
#include "VPreprocLex.h"

//#undef yyFlexLexer
//#define yyFlexLexer xxFlexLexer
//#include <FlexLexer.h>

//*************************************************************************
// Data for a preprocessor instantiation.

struct VPreprocImp : public VPreprocOpaque {
    VPreproc*	m_preprocp;	// Object we're holding data for
    VFileLine*	m_filelinep;	// Last token's starting point
    int		m_debug;	// Debugging level
    VPreprocLex* m_lexp;	// Current lexer state (NULL = closed)
    stack<VPreprocLex*> m_includeStack;	// Stack of includers above current m_lexp

    enum ProcState { ps_TOP, ps_DEFNAME, ps_DEFVALUE, ps_INCNAME, ps_ERRORNAME };
    ProcState	m_state;	// Current state of parser
    int		m_stateFor;	// Token state is parsing for
    int		m_off;		// If non-zero, ifdef level is turned off, don't dump text
    string	m_lastSym;	// Last symbol name found.

    // For getRawToken/ `line insertion
    string	m_lineCmt;	// Line comment(s) to be returned
    int		m_lineAdd;	// Empty lines to return to maintain line count

    // For defines
    string	m_defLastRtn;	// Define value storage, to avoid mem leak
    stack<bool> m_ifdefStack;	// Stack of true/false emmiting evaluations

    // For getline()
    string	m_lineChars;	// Characters left for next line

    VPreprocImp(VFileLine* filelinep) {
	m_filelinep = filelinep;
	m_debug = 0;
	m_lexp = NULL;	 // Closed.
	m_state = ps_TOP;
	m_defLastRtn = "";
	m_off = 0;
	m_lineChars = "";
	m_lastSym = "";
	m_lineAdd = 0;
    }
    const char* tokenName(int tok);
    int getRawToken();
    int getToken();
    void parseTop();
    void parseUndef();
    string getline();
    bool isEof() const { return (m_lexp==NULL); }
    void open(string filename, VFileLine* filelinep);
    void insertUnreadback(string text) { m_lineCmt += text; }
private:
    void error(string msg) { m_filelinep->error(msg); }
    void fatal(string msg) { m_filelinep->fatal(msg); }
    int debug() const { return m_debug; }
    void eof();
    string defineSubst(string str);
    void addLineComment(int enter_exit_level);

    void parsingOn() { m_off--; assert(m_off>=0); if (!m_off) addLineComment(0); }
    void parsingOff() { m_off++; }
};

//*************************************************************************
// Creation

VPreproc::VPreproc(VFileLine* filelinep) {
    VPreprocImp* idatap = new VPreprocImp(filelinep);
    m_opaquep = idatap;
    idatap->m_preprocp = this;
}

//*************************************************************************
// VPreproc Methods.  Just call the implementation functions.

void VPreproc::comment(string cmt) { }
void VPreproc::open(string filename, VFileLine* filelinep) {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    idatap->open (filename,filelinep);
}
string VPreproc::getline() {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    return idatap->getline();
}
void VPreproc::debug(int level) {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    idatap->m_debug = level;
}
bool VPreproc::isEof() {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    return idatap->isEof();
}
VFileLine* VPreproc::filelinep() {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    return idatap->m_filelinep;
}
void VPreproc::insertUnreadback(string text) {
    VPreprocImp* idatap = static_cast<VPreprocImp*>(m_opaquep);
    return idatap->insertUnreadback(text);
}

//*************************************************************************

// CALLBACK METHODS
// This probably will want to be overridden for given child users of this class.

void VPreproc::include(string filename) {
    open(filename, filelinep());
}
void VPreproc::undef(string define) {
    cout<<"UNDEF "<<define<<endl;
}
bool VPreproc::defExists(string define) {
    return false;
}
void VPreproc::define(string define, string value) {
    error("Defines not implemented: "+define+"\n");
}
string VPreproc::defValue(string define) {
    error("Define not defined: "+define+"\n");
}

//**********************************************************************
// Parser Utilities

const char* VPreprocImp::tokenName(int tok) {
    switch (tok) {
    case VP_INCLUDE	: return("INCLUDE");
    case VP_IFDEF	: return("IFDEF");
    case VP_IFNDEF	: return("IFNDEF");
    case VP_ENDIF	: return("ENDIF");
    case VP_UNDEF	: return("UNDEF");
    case VP_DEFINE	: return("DEFINE");
    case VP_SYMBOL	: return("SYMBOL");
    case VP_STRING	: return("STRING");
    case VP_DEFVALUE	: return("DEFVALUE");
    case VP_COMMENT	: return("COMMENT");
    case VP_TEXT	: return("TEXT");	
    case VP_WHITE	: return("WHITE");	
    case VP_ELSE	: return("ELSE");	
    case VP_ELSIF	: return("ELSIF");	
    case VP_DEFREF	: return("DEFREF");
    case VP_ERROR	: return("ERROR");
    case VP_EOF		: return("EOF");
    default: return("?");
    } 
}

string VPreprocImp::defineSubst(string in) {
    // Substitute out defines in the string.
    // We could push the define text back into the lexer, but that's slow
    // and would make recursive definitions and parameter handling nasty.
    if (debug()) cout<<"defineSubstIn  "<<in<<endl;
    string out;

    unsigned level = 0;	// Recursion level.
    while (1) {
	string::size_type tick = in.find("`");
	if (tick == std::string::npos) {
	    // Done.
	    out.append(in);
	    break;
	} else {
	    // Output text before the define.
	    out.append(in,0,tick);
	    in.erase(0,tick);
	    // Define name now starts at location 0 in in.
	    int endtick = 1;	// Skip the `
	    while (in[endtick] && (isalnum(in[endtick]) || in[endtick]=='_' || in[endtick]=='$')) endtick++;
	    string name(in,1,endtick-1);
	    in.erase(0,endtick);
	    // Substitute the define
	    if (!m_preprocp->defExists(name)) {
		// Define doesn't exist.  Just emit the token, and let downstream tools
		// report the error, or handle it as a compiler directive.
		out += "`"+name;
	    } else {
		// Put it into "in", as we need to allow defines with other defines inside them.
		// Pack spaces around the define value, as there must be token boundaries around it.
		// It also makes it more obvious where defines got substituted.
		in = " " + m_preprocp->defValue(name) + " " + in;
		level++;
		if (level > VPreproc::DEFINE_RECURSION_LEVEL_MAX) {
		    error("Recursive `define substitution: "+name);
		    return "";
		}
	    }
	}
    }
    if (debug()) cout<<"defineSubstOut "<<out<<endl;
    return out;
}

//**********************************************************************
// Parser routines

void VPreprocImp::open(string filename, VFileLine* filelinep) {
    // Open a new file, possibly overriding the current one which is active.
    if (filelinep) {
	m_filelinep = filelinep;
    }

    FILE* fp = fopen (filename.c_str(), "r");
    if (!fp) {
	error("File not found: "+filename+"\n");
	return;
    }

    if (m_lexp) {
	// We allow the same include file twice, because occasionally it pops
	// up, with guards preventing a real recursion.
	if (m_includeStack.size()>VPreproc::INCLUDE_DEPTH_MAX) {
	    error("Recursive inclusion of file: "+filename);
	    return;
	}
	// There's already a file active.  Push it to work on the new one.
	m_includeStack.push(m_lexp);
	addLineComment(0);
    }

    m_lexp = new VPreprocLex;
    m_lexp->m_fp = fp;
    m_lexp->m_yyState = yy_create_buffer (fp, YY_BUF_SIZE);
    m_lexp->m_keepComments = m_preprocp->keepComments();
    m_lexp->m_pedantic = m_preprocp->pedantic();
    m_lexp->m_curFilelinep = m_preprocp->filelinep()->create(filename, 1);
    m_filelinep = m_lexp->m_curFilelinep;  // Remember token start location
    addLineComment(1); // Enter

    yy_switch_to_buffer(m_lexp->m_yyState);
}

void VPreprocImp::addLineComment(int enter_exit_level) {
    if (m_preprocp->lineDirectives()) {
	char numbuf[20]; sprintf(numbuf, "%d", m_lexp->m_curFilelinep->lineno());
	char levelbuf[20]; sprintf(levelbuf, "%d", enter_exit_level);
	string cmt = ((string)"\n`line "+numbuf
		      +" \""+m_lexp->m_curFilelinep->filename()+"\" "
		      +levelbuf+"\n");
	insertUnreadback(cmt);
    }
}

void VPreprocImp::eof() {
    // Remove current lexer
    if (debug()) cout<<m_filelinep<<"EOF!\n";
    addLineComment(2);	// Exit
    delete m_lexp;  m_lexp=NULL;
    // Perhaps there's a parent file including us?
    if (!m_includeStack.empty()) {
	// Back to parent.
	m_lexp = m_includeStack.top(); m_includeStack.pop();
	addLineComment(0);
	yy_switch_to_buffer(m_lexp->m_yyState);
    }
}

int VPreprocImp::getRawToken() {
    // Get a token from the file, whatever it may be.
    while (1) {
      next_tok:
	if (m_lineAdd) {
	    m_lineAdd--;
	    yytext="\n"; yyleng=1;
	    return (VP_TEXT);
	}
	if (m_lineCmt!="") {
	    // We have some `line directive to return to the user.  Do it.
	    static string rtncmt;  // Keep the c string till next call
	    rtncmt = m_lineCmt;
	    yytext=(char*)rtncmt.c_str(); yyleng=rtncmt.length();
	    m_lineCmt = "";
	    if (m_state!=ps_DEFVALUE) return (VP_TEXT);
	    else {
		VPreprocLex::s_currentLexp->appendDefValue(yytext,yyleng); 
		goto next_tok;
	    }
	}
	if (isEof()) return (VP_EOF);
	// Snarf next token from the file
	m_filelinep = m_lexp->m_curFilelinep;  // Remember token start location
	VPreprocLex::s_currentLexp = m_lexp;   // Tell parser where to get/put data
	int tok = yylex();

	if (debug()) {
	    char buf[10000]; strncpy(buf, yytext, yyleng);  buf[yyleng] = '\0';
	    for (char* cp=buf; *cp; cp++) if (*cp=='\n') *cp='$';
	    printf ("%d: RAW %d %d:  %-10s: %s\n",
		    m_filelinep->lineno(), m_off, m_state, tokenName(tok), buf);
	}
    
	// On EOF, try to pop to upper level includes, as needed.
	if (tok==VP_EOF) {
	    eof();
	    goto next_tok;  // Parse parent, or find the EOF.
	}

	return tok;
    }
}

// Sorry, we're not using bison/yacc. It doesn't handle returning white space
// in the middle of parsing other tokens.

int VPreprocImp::getToken() {
    // Return the next user-visible token in the input stream.
    // Includes and such are handled here, and are never seen by the caller.
    while (1) {
      next_tok:
	if (isEof()) return VP_EOF;
	int tok = getRawToken();
	// Always emit white space and comments between tokens.
	if (tok==VP_WHITE) return (tok);
	if (tok==VP_COMMENT) {
	    if (!m_off) {
		if (m_lexp->m_keepComments == KEEPCMT_SUB) {
		    string rtn; rtn.assign(yytext,yyleng);
		    m_preprocp->comment(rtn);
		} else {
		    return (tok);
		}
	    }
	    // We're off or processed the comment specially.  If there are newlines
	    // in it, we also return the newlines as TEXT so that the linenumber
	    // count is maintained for downstream tools
	    for (int len=0; len<yyleng; len++) { if (yytext[len]=='\n') m_lineAdd++; }
	    goto next_tok;
	}
	// Deal with some special parser states
	switch (m_state) {
	case ps_TOP: {
	    break;
	}
	case ps_DEFNAME: {
	    if (tok==VP_SYMBOL) {
		m_state = ps_TOP;
		m_lastSym.assign(yytext,yyleng);
		if (m_stateFor==VP_IFDEF
		    || m_stateFor==VP_IFNDEF) {
		    bool enable = m_preprocp->defExists(m_lastSym);
		    if (debug()) cout<<"Ifdef "<<m_lastSym<<(enable?" ON":" OFF")<<endl;
		    if (m_stateFor==VP_IFNDEF) enable = !enable;
		    m_ifdefStack.push(enable);
		    if (!enable) parsingOff();
		}
		else if (m_stateFor==VP_ELSIF) {
		    if (m_ifdefStack.empty()) {
			error("`elsif with no matching `if\n");
		    } else {
			// Handle `else portion
			bool lastEnable = m_ifdefStack.top(); m_ifdefStack.pop();
			if (!lastEnable) parsingOn();
			// Handle `if portion
			bool enable = !lastEnable && m_preprocp->defExists(m_lastSym);
			if (debug()) cout<<"Elsif "<<m_lastSym<<(enable?" ON":" OFF")<<endl;
			m_ifdefStack.push(enable);
			if (!enable) parsingOff();
		    }
		}
		else if (m_stateFor==VP_UNDEF) {
		    if (!m_off) {
			if (debug()) cout<<"Undef "<<m_lastSym<<endl;
			m_preprocp->undef(m_lastSym);
		    }
		}
		else if (m_stateFor==VP_DEFINE) {
		    // m_lastSym already set.
		    m_state = ps_DEFVALUE;
		    m_lexp->setStateDefValue();
		}
		else fatalSrc("Bad case\n");
		goto next_tok;
	    }
	    else {
		error((string)"Expecting define name. Found: "+tokenName(tok)+"\n");
		goto next_tok;
	    }
	}
	case ps_DEFVALUE: {
	    if (tok == VP_DEFVALUE) {
		if (!m_off) {
		    // Remove leading whitespace
		    unsigned leadspace = 0;
		    while (m_lexp->m_defValue.length() > leadspace
			   && isspace(m_lexp->m_defValue[leadspace])) leadspace++;
		    if (leadspace) m_lexp->m_defValue.erase(0,leadspace);
		    // Remove trailing whitespace
		    unsigned trailspace = 0;
		    while (m_lexp->m_defValue.length() > trailspace
			   && isspace(m_lexp->m_defValue[m_lexp->m_defValue.length()-1-trailspace])) trailspace++;
		    if (trailspace) m_lexp->m_defValue.erase(m_lexp->m_defValue.length()-trailspace,trailspace);
		    // Define it
		    if (debug()) cout<<"Define "<<m_lastSym<<" = "<<m_lexp->m_defValue<<endl;
		    m_preprocp->define(m_lastSym, m_lexp->m_defValue);
		}
	    } else {
		fatalSrc("Bad define text\n");
	    }
	    m_state = ps_TOP;
	    // DEFVALUE is terminated by a return, but lex can't return both tokens.
	    // Thus, we emit a return here.
	    yytext="\n"; yyleng=1; return(VP_WHITE); 
	}
	case ps_INCNAME: {
	    if (tok==VP_STRING) {
		m_state = ps_TOP;
		if (!m_off) {
		    m_lastSym.assign(yytext,yyleng);
		    if (debug()) cout<<"Include "<<m_lastSym<<endl;
		    // Drop leading and trailing quotes.
		    m_lastSym.erase(0,1);
		    m_lastSym.erase(m_lastSym.length()-1,1);
		    m_preprocp->include(m_lastSym);
		}
		goto next_tok;
	    }
	    else {
		m_state = ps_TOP;
		error((string)"Expecting include filename. Found: "+tokenName(tok)+"\n");
		goto next_tok;
	    }
	}
	case ps_ERRORNAME: {
	    if (tok==VP_STRING) {
		m_state = ps_TOP;
		if (!m_off) {
		    m_lastSym.assign(yytext,yyleng);
		    error(m_lastSym);
		}
		goto next_tok;
	    }
	    else {
		m_state = ps_TOP;
		error((string)"Expecting `error string. Found: "+tokenName(tok)+"\n");
		goto next_tok;
	    }
	}
	default: fatalSrc("Bad case\n");
	}
	// Default is to do top level expansion of some tokens
	switch (tok) {
	case VP_INCLUDE:
	    m_state = ps_INCNAME;  m_stateFor = tok;
	    goto next_tok;
	case VP_UNDEF:
	case VP_DEFINE:
	case VP_IFDEF:
	case VP_IFNDEF:
	case VP_ELSIF:
	    m_state = ps_DEFNAME;  m_stateFor = tok;
	    goto next_tok;
	case VP_ELSE:
	    if (m_ifdefStack.empty()) {
		error("`else with no matching `if\n");
	    } else {
		bool lastEnable = m_ifdefStack.top(); m_ifdefStack.pop();
		bool enable = !lastEnable;
		if (debug()) cout<<"Else "<<(enable?" ON":" OFF")<<endl;
		m_ifdefStack.push(enable);
		if (!lastEnable) parsingOn();
		if (!enable) parsingOff();
	    }
	    goto next_tok;
	case VP_ENDIF:
	    if (m_ifdefStack.empty()) {
		error("`endif with no matching `if\n");
	    } else {
		bool lastEnable = m_ifdefStack.top(); m_ifdefStack.pop();
		if (debug()) cout<<"Endif "<<endl;
		if (!lastEnable) parsingOn();
	    }
	    goto next_tok;

	case VP_DEFREF: {
	    if (!m_off) {
		string name; name.append(yytext,yyleng);
		if (debug()) cout<<"DefRef "<<name<<endl;
		m_defLastRtn = defineSubst(name); // Need to keep string around until user consumes it.
		yytext = (char*)m_defLastRtn.c_str();
		yyleng = m_defLastRtn.length();
		return (VP_TEXT);
	    }
	    else goto next_tok;
	}
	case VP_ERROR: {
	    m_state = ps_ERRORNAME;  m_stateFor = tok;
	    goto next_tok;
	}
	case VP_EOF:
	    if (!m_ifdefStack.empty()) {
		error("`ifdef not terminated at EOF\n");
	    }
	    return tok;
	    return tok;
	case VP_SYMBOL:
	case VP_STRING:
	case VP_TEXT:
	    if (!m_off) return tok;
	    else goto next_tok;
	case VP_WHITE:		// Handled at top of loop
	case VP_COMMENT:	// Handled at top of loop
	case VP_DEFVALUE:	// Handled by m_state=ps_DEFVALUE;
	default:
	    fatalSrc("Internal error: Unexpected token.\n");
	    break;
	}
	return tok;
    }
}

string VPreprocImp::getline() {
    // Get a single line from the parse stream.  Buffer unreturned text until the newline.
    if (isEof()) return "";
    char* rtnp;
    while (NULL==(rtnp=strchr(m_lineChars.c_str(),'\n'))) {
	int tok = getToken();
	if (tok==VP_EOF) {
	    // Add a final newline, in case the user forgot the final \n.
	    m_lineChars.append("\n");
	}
	else {
	    if (debug()) {
		char buf[100000];
		strncpy(buf, yytext, yyleng);
		buf[yyleng] = '\0';
		for (char* cp=buf; *cp; cp++) if (*cp=='\n') *cp='$';
		printf ("%d: GETFETC:  %-10s: %s\n",
			m_filelinep->lineno(), tokenName(tok), buf);
	    }
	    m_lineChars.append(yytext,0,yyleng);
	}
    }

    // Make new string with data up to the newline.
    int len = rtnp-m_lineChars.c_str()+1;
    string theLine(m_lineChars, 0, len);
    m_lineChars = m_lineChars.erase(0,len);	// Remove returned characters
    if (debug()) printf ("%d: GETLINE:  %s\n", m_filelinep->lineno(), theLine.c_str());
    return theLine;
}
