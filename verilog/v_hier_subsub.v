// $Id: v_hier_subsub.v,v 1.2 2001/11/01 21:53:34 wsnyder Exp $
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
