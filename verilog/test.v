// $Id: test.v,v 1.5 2001/02/13 15:11:16 wsnyder Exp $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

module example (/*AUTOARG*/
   // Outputs
   z, 
   // Inputs
   a, b
   );

   // See http://veripool.com
   // for what AUTOARG and friends can do for you!

   /*Comment // test*/
   //
   
   input a;
   input b;

   output z;

   wire z = a|b;

endmodule
