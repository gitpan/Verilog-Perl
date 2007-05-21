// $Id: v_hier_subsub.v 38787 2007-05-16 18:54:10Z wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2007 by Wilson Snyder.

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   parameter IGNORED = 0;
   input  signed a;
   output q;
   wire   q = a;
endmodule
