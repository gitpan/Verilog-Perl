// $Revision: 1.4 $$Date: 2005-01-24 10:18:02 -0500 (Mon, 24 Jan 2005) $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2005 by Wilson Snyder.

// surefire lint_off UDPUNS

primitive v_hier_prim (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   output q;
   input a;

   table
      0 : 1;
      1 : 0;
   endtable

endprimitive
