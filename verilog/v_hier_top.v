// $Id: v_hier_top.v 11992 2006-01-16 18:59:58Z wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2000-2006 by Wilson Snyder.

`define hsub v_hier_sub

module v_hier_top (/*AUTOARG*/
   // Inputs
   clk
   );
   input clk;
   `hsub sub (/*AUTOINST*/
	      // Outputs
	      .qvec			(qvec[3:0]),
	      // Inputs
	      .clk			(1'b0),
	      .avec			(avec[3:0]));

   missing missing ();

endmodule

// Local Variables:
// eval:(verilog-read-defines)
// End:
