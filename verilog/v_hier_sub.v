// $Revision: #9 $$Date: 2004/01/27 $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2004 by Wilson Snyder.

module v_hier_sub (/*AUTOARG*/
   // Outputs
   qvec, 
   // Inputs
   clk, avec
   );
   input clk;
   input [3:0] avec;
   output [3:0] qvec;

   v_hier_subsub subsub0 (/*AUTOINST*/
			  // Outputs
			  .q		(qvec[0]),		 // Templated
			  // Inputs
			  .a		(1'b1));		 // Templated

   // By pin position
   v_hier_subsub subsub2 (qvec[2], 1'b0);

endmodule
