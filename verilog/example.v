// DESCRIPTION: vpm: Example top verilog file for vpm program

`timescale 1ns/1ns

module example;

   pli pli ();	// Put on highest level of your design

   integer i;

   initial begin
      $info (0, "Welcome to a VPMed file\n");
      i=0;
      $assert (1==1, "Why doesn't 1==1??\n");
   end
   
   initial forever begin
      #1;
      i = i + 1;
      if (i==20) $warn  (0, "Don't know what to do next!\n");
      if (i==22) $error (0, "Guess I'll error out!\n");
   end

endmodule
