#!/usr/local/bin/perl -w
# $Revision: #3 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;

BEGIN { plan tests => 3 }
BEGIN { require "t/test_utils.pl"; }

use Verilog::Language;
ok(1);

array_ck (['ff[5]e',
	   'ff[3]e',
	   'ff[1]e',
	   'ff[4]e',
	   ],
	Verilog::Language::split_bus
	  ("ff[5:1:2,4]e"));

array_ck (['ff[3]  bar [10] end',
	   'ff[2]  bar [9] end',
	   'ff[1]  bar [8] end',
	   'ff[3]  bar [7] end',
	   'ff[2]  bar [6] end',
	   'ff[1]  bar [5] end',
	   'ff[3]  bar [4] end',
	   'ff[2]  bar [3] end',
	   ],
	Verilog::Language::split_bus
	  ("ff[3:1]  bar [4'ha:3] end"));

sub array_ck {
    my $checkref = shift;
    my $ok=1;

    if ($#{$checkref} != $#_) {
	$ok = 0;
    } else {
	for (my $i=0;$i<=$#_;$i++) {
	    $ok = 0 if $_[$i] ne $checkref->[$i];
	}
    }

    ok ($ok);
    if (!$ok) {
	print "Expec:\t",join("\n\t",@{$checkref}),"\n";
	print "  Got:\t",join("\n\t",@_),"\n";
    }
}
