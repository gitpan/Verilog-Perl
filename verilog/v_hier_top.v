// $Revision: #1 $$Date: 2002/12/16 $$Author: lab $
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
