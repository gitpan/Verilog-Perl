// $Revision: #3 $$Date: 2002/07/16 $$Author: wsnyder $
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
