`line 2 "inc3_a_filename_from_line_directive" 0
// DESCRIPTION: Verilog::Preproc: Example source code

`ifndef _EXAMPLE_INC2_V_
 `define _EXAMPLE_INC2_V_ 1
 `define _EMPTY
  // FOO
  At file `__FILE__  line `__LINE__
`else
  `error "INC2 File already included once"
`endif // guard

`ifdef not_defined
 `include "NotToBeInced.v"
`endif
