// $Id: v_hier_top.v,v 1.3 2002/02/27 18:13:22 wsnyder Exp $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

`define hsub v_hier_sub

module v_hier_top (/*AUTOARG*/
   // Inputs
   clk
   );
   input clk;
   `hsub sub (/*AUTOINST*/
		   // Outputs
		   .qvec		(qvec[1:0]),
		   // Inputs
		   .clk			(clk),
		   .avec		(avec[1:0]));
endmodule
