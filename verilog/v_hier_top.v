// $Id: v_hier_top.v,v 1.2 2001/11/01 21:53:34 wsnyder Exp $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

module v_hier_top (/*AUTOARG*/
   // Inputs
   clk
   );
   input clk;
   v_hier_sub sub (/*AUTOINST*/
		   // Outputs
		   .qvec		(qvec[1:0]),
		   // Inputs
		   .clk			(clk),
		   .avec		(avec[1:0]));
endmodule
