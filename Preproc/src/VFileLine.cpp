#ident "$Revision: #8 $$Date: 2002/08/07 $$Author: wsnyder $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Error handling implementation
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

#include "VFileLine.h"

int VFileLine::s_numErrors = 0;

//============================================================================

VFileLine* VFileLine::create(const string filename, int lineno) {
    VFileLine* filelp = new VFileLine(true);
    filelp->init(filename, lineno);
    return filelp;
}

VFileLine* VFileLine::create(int lineno) {
    return (this->create(this->filename(), lineno));
}

VFileLine* VFileLine::create_default() {
    VFileLine* filelp = new VFileLine(true);
    return filelp;
}

void VFileLine::init(const string filename, int lineno) {
    m_filename = filename;
    m_lineno = lineno;
}

const string VFileLine::filebasename () const {
    string name = filename();
    string::size_type slash;
    if ((slash = name.rfind("/")) != string::npos) {
	name.erase(0,slash+1);
    }
    return name;
}

void VFileLine::fatal(const string msg) {
    error(msg);
    error("Fatal Error detected");
    abort();
}
void VFileLine::error(const string msg) {
    VFileLine::s_numErrors++;
    cerr<<"%Error: "<<this<<msg;
    if (msg[msg.length()-1] != '\n') {
	cerr<<endl;	// Append newline, as user ommitted it.
    }
}

const char* VFileLine::itoa(int i) {
    static char buf[100];
    sprintf(buf,"%d",i);
    return buf;
}

//======================================================================
// Global scope

ostream& operator<<(ostream& os, VFileLine* flp) {
    if (flp->filename()!="") {
	os <<flp->cfilename()<<":"<<dec<<flp->lineno()<<": "<<hex;
    }
    return(os);
}
