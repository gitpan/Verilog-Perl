// $Revision: #6 $$Date: 2003/03/24 $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

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
	      .clk			(clk),
	      .avec			(avec[3:0]));

   missing missing ();

endmodule

// Local Variables:
// eval:(verilog-read-defines)
// End:
