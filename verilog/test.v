// $Id: test.v,v 1.6 2002/03/20 14:18:01 wsnyder Exp $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

// ENCRYPT_ME

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

   wire result = a|b;

   wire z = result;

endmodule
