// $Revision: #5 $$Date: 2004/01/27 $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2004 by Wilson Snyder.

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   input a;
   output q;
   wire   q = a;
endmodule
