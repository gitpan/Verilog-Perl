#ident "$Revision: #7 $$Date: 2002/12/14 $$Author: lab $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Error handling
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

#ifndef _VFILELINE_H_
#define _VFILELINE_H_ 1
#include <string>
#include <iostream>
using namespace std;

//============================================================================

class VFileLine {
    // Provide user information and error reporting functions
    // Users can override this class to implement their own error handling
private:
    int		m_lineno;
    string	m_filename;
    static int	s_numErrors;

protected:
    VFileLine(int called_only_for_default) {init("",0);}

public:
    // CONSTRUCTORS
    // Create a new fileline, for a new file and/or line number.
    // Member functions, so that if a user provides another class, a change in the
    // filename/linenumber will create a new element using the derrived class.
    virtual VFileLine* create(const string filename, int lineno);
    virtual VFileLine* create(int lineno);	// Same filename; just calls create(fn,ln)
    static VFileLine* create_default();
    virtual void init(const string filename, int lineno);
    virtual ~VFileLine() {}
    // ACCESSORS
    virtual int lineno () const { return m_lineno; }
    virtual const string filename () const { return m_filename; }
    virtual const string filebasename () const;	// Filename with any directory stripped
    virtual const char* cfilename () const { return m_filename.c_str(); }
    // METHODS
    virtual void fatal(const string msg);	// Report a fatal error at given location
    virtual void error(const string msg);	// Report a error at given location
    // STATIC METHODS
    static int numErrors() {return s_numErrors;}	// Total errors detected

    // Internal methods -- special use
    static const char* itoa(int i);	// Not reentrant! - for fatalSrc() only
};
ostream& operator<<(ostream& os, VFileLine* fileline);

// Use this instead of fatal() to mention the source code line.
#define fatalSrc(msg) fatal((string)"Internal Error: "+__FILE__+":"+VFileLine::itoa(__LINE__)+": "+(msg))

#endif // Guard
