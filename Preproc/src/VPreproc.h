#ident "$Revision: #10 $$Date: 2002/08/07 $$Author: wsnyder $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Preprocess verilog code
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

#ifndef _VPREPROC_H_
#define _VPREPROC_H_ 1

#include <string>
#include <map>
#include "VFileLine.h"

class VPreprocOpaque {};
class VDefine;
class VPreproc {
    // This defines a preprocessor.  Functions are virtual so users can override them.
    // After creating, call open(), then getline() in a loop.  The class will to the rest...
public:
    VPreproc(VFileLine* filelinep);
    virtual ~VPreproc() {};

    // CONSTANTS
    static const unsigned DEFINE_RECURSION_LEVEL_MAX = 50;	// How many `def substitutions before an error
    static const unsigned INCLUDE_DEPTH_MAX = 200;	// How many `includes deep before an error

    // ACCESSORS
    // Insert given file into this point in input stream
    virtual void open(string filename, VFileLine* filelinep=NULL);
    virtual void debug(int level);	// Set debugging level
    virtual string getline();		// Return next line/lines. (Null if done.)
    virtual bool isEof();		// Return true on EOF.
    virtual void insertUnreadback(string text);

    virtual VFileLine* filelinep();	// File/Line number for last getline call

    // The default behavior is to pass all unknown `defines right through.
    // This lets the user determine how to report the errors.  It also nicely
    // allows `celldefine and such to remain in the output stream.

    // CONTROL METHODS
    // These options control how the parsing proceeds
    virtual int keepComments() { return 1; }		// Return comments, 0=no, 1=yes, 2=callback
    virtual bool lineDirectives() { return true; }	// Insert `line directives
    virtual bool pedantic() { return false; }		// Obey standard; Don't substitute `__FILE__ and `__LINE__

    // CALLBACK METHODS
    // This probably will want to be overridden for given child users of this class.
    virtual void comment(string cmt);		// Comment detected (if keepComments==2)
    virtual void include(string filename);	// Request a include file be processed
    virtual void define(string name, string value); // `define without any parameters
    virtual void undef(string name);		// Remove a definition
    virtual bool defExists(string name);	// Return true if define exists
    virtual string defValue(string name);	// Return value of given define (should exist)
    // We don't support parameterized macros (yet?)
    //virtual void defSet(string name, string value, int nargs, string args[]);
    //virtual string defValue(string name, int nargs, string args[]);	// Return value of a define

    // UTILITIES
    void error(string msg) { filelinep()->error(msg); }
    void fatal(string msg) { filelinep()->fatal(msg); }

private:
    VPreprocOpaque*	m_opaquep;	// Pointer to parser's implementation data.
};

#endif // Guard
