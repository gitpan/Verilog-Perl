// $Revision: #1 $$Date: 2002/12/16 $$Author: lab $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

module v_hier_subsub (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   input a;
   output q;
   wire   q = a;
endmodule
