// $Revision: #2 $$Date: 2003/02/06 $$Author: wsnyder $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

module v_hier_sub (/*AUTOARG*/
   // Outputs
   qvec, 
   // Inputs
   clk, avec
   );
   input clk;
   input [2:0] avec;
   output [2:0] qvec;

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

   // By pin position
   // Not supported!
   //v_hier_subsub subsub2 (qvec[2], avec[2]);

   // Primitives
   v_hier_subprim subsub3 (qvec[2], avec[2]);

endmodule
