// $Revision: #1 $$Date: 2002/12/16 $$Author: lab $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

module v_hier_sub (/*AUTOARG*/
   // Outputs
   qvec, 
   // Inputs
   clk, avec
   );
   input clk;
   input [1:0] avec;
   output [1:0] qvec;

   /* v_hier_subsub AUTO_TEMPLATE (
			   .q		(qvec[@]),
			   .a		(avec[@]));
    */
   
   v_hier_subsub subsub0 (/*AUTOINST*/
			  // Outputs
			  .q		(qvec[0]),		 // Templated
			  // Inputs
			  .a		(avec[0]));		 // Templated
   v_hier_subsub subsub1 (/*AUTOINST*/
			  // Outputs
			  .q		(qvec[1]),		 // Templated
			  // Inputs
			  .a		(avec[1]));		 // Templated
endmodule
