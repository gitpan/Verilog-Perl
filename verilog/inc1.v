// DESCRIPTION: Verilog::Preproc: Example source code
text.

`define FOOBAR  foo /*but not */ bar   /* or this either */
`define FOOBAR2  foobar2 // but not

`define MULTILINE first part \
  		second part
		  
//===========================================================================

`define syn_negedge_reset_l or negedge reset_l

`define DEEP deep
`define DEEPER `DEEP `DEEP

/*******COMMENT*****/
`FOOBAR
`FOOBAR2
`DEEPER
`MULTILINE


  