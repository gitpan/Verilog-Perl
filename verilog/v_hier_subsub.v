// $Revision: 1.7 $$Date: 2005-01-25 17:10:49 -0500 (Tue, 25 Jan 2005) $$Author: wsnyder $
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
   input  signed a;
   output q;
   wire   q = a;
endmodule
