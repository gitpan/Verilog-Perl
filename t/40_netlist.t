#!/usr/local/bin/perl -w
# $Revision: #6 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;

BEGIN { plan tests => 3 }
BEGIN { require "t/test_utils.pl"; }

#$Verilog::Netlist::Debug = 1;
use Verilog::Netlist;
ok(1);

use Verilog::Getopt;
my $opt = new Verilog::Getopt;
$opt->parameter( "+incdir+verilog",
		 "-y","verilog",
		 );
ok(1);

{
    print "Checking example in Netlist.pm\n";
    # Prepare netlist
    my $nl = new Verilog::Netlist (options => $opt,);
    foreach my $file ('verilog/v_hier_top.v', 'verilog/v_hier_top2.v') {
	$nl->read_file (filename=>$file);
    }
    # Read in any sub-modules
    $nl->link();
    $nl->lint();
    $nl->exit_if_error();

    foreach my $mod ($nl->modules_sorted) {
	if ($mod->is_top) {
	    show_hier ($mod, "  ", "");
	}
    }

    sub show_hier {
	my $mod = shift;
	my $indent = shift;
	my $hier = shift;
	$hier .= $mod->name;
	printf ("%-38s %s\n", $indent."Module ".$mod->name,$hier);
	foreach my $sig ($mod->ports_sorted) {
	    printf ($indent."     %sput %s\n", $sig->direction, $sig->name);
	}
	foreach my $cell ($mod->cells_sorted) {
	    show_hier ($cell->submod, $indent."  ", $hier.".");
	    foreach my $pin ($cell->pins_sorted) {
		printf ($indent."     .%s(%s)\n", $pin->name, $pin->netname);
	    }
	}
    }
}
ok(1);
