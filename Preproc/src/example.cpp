#ident "$Id: example.cpp,v 1.2 2002/02/07 22:25:40 wsnyder Exp $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Example use of VPreproc.h
//
// Code available from: http://www.veripool.com/
//
// Authors: Wilson Snyder
//
//*************************************************************************
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License, with the exception that it cannot be placed
// on a CD-ROM or similar media for commercial distribution without the
// prior approval of the author.
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
#include <unistd.h>

#include "VPreproc.h"

int main() {
    // Create the class to be used for line tracking and error reporting.
    VFileLine* filelinep = VFileLine::create_default();

    // Declare a new preprocessor
    VPreproc* pp = new VPreproc (filelinep);

    // We don't have a directory search path in this trivial parser, so
    // we CD to the right place so everything is local.
    chdir("../../verilog");

    // Tokens will come from this file
    pp->open("inc1.v");
    // Pretend there's a include.  This file will go out BEFORE the one above.
    pp->open("inc2.v");

    //pp->debug(9);	// To know what's happening

    while (!pp->isEof()) {
	string str = pp->getline();
	printf ("%d: TOPLINE: %s",	// No \n, we know getline() will have one.
		pp->filelinep()->lineno(),
		str.c_str());
    }

    if (filelinep->numErrors()) {
	filelinep->fatal("Errors were detected above.  Exiting.\n");
    }
    cout<<"Parsed OK!\n";
}
