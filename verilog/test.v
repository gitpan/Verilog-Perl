// $Revision: #7 $$Date: 2002/07/16 $$Author: wsnyder $
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
