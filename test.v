
module example (/*AUTOARG*/
   // Outputs
   z, 
   // Inputs
   a, b
   );

   // See http://www.ultranet.com/~wsnyder/verilog-perl
   // for what AUTOARG and friends can do for you!

   input a;
   input b;

   output z;

   wire z = a|b;

endmodule
