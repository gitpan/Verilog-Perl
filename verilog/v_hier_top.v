// $Revision: #4 $$Date: 2002/07/16 $$Author: wsnyder $
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
