// $Id: v_hier_subsub.v 4305 2005-08-02 13:21:57Z wsnyder $
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
