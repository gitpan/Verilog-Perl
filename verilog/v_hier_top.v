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
