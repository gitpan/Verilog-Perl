// $Revision: #2 $$Date: 2003/02/06 $$Author: wsnyder $
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

   missing missing ();

endmodule
