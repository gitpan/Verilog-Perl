// $Revision: 1.7 $$Date: 2005-01-24 10:18:02 -0500 (Mon, 24 Jan 2005) $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2005 by Wilson Snyder.

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   parameter IGNORED;
   input a;
   output q;
   wire   q = a;
endmodule
