// $Revision: #1 $$Date: 2003/02/06 $$Author: tlevergo $
// DESCRIPTION: Verilog-Perl: Example Verilog for testing package

// surefire lint_off UDPUNS

primitive v_hier_prim (/*AUTOARG*/
   // Outputs
   q, 
   // Inputs
   a
   );
   output q;
   input a;

   table
      0 : 1;
      1 : 0;
   endtable

endprimitive
