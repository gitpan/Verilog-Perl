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
   
   // Example of request/grant handshake
   reg	      clk;
   reg	      bus_req;		// Request a transaction, single cycle pulse
   reg	      bus_ack;		// Acknowledged transaction, single cycle pulse
   reg [31:0] bus_data;

   initial begin
      // Reset signals
      bus_req  = 1'b0;
      bus_ack  = 1'b0;
      bus_data = 1'b0;
      // Assert a request
      @ (posedge clk) ;
      bus_req  = 1'b1;
      bus_data = 32'hfeed;
      // Wait for ack
      @ (posedge clk) ;
      bus_req  = 1'b0;
      // Send ack
      @ (posedge clk) ;
      bus_ack  = 1'b1;
      // Next request could be here
      @ (posedge clk) ;
      bus_ack  = 1'b0;
   end
   always @ (posedge clk) begin
      $assert_req_ack (bus_req, bus_ack, bus_data);
   end

   // Overall control loop
   initial clk = 1'b0;
   initial forever begin
      #1;
      i = i + 1;
      clk = !clk;
      if (i==20) $warn  (0, "Don't know what to do next!\n");
      if (i==22) $error (0, "Guess I'll error out!\n");
   end

endmodule