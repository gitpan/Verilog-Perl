#!/usr/local/bin/perl -w
# $Revision: #7 $$Date: 2002/07/16 $$Author: wsnyder $
#DESCRIPTION: Perl ExtUtils: Common routines required by package tests

use IO::File;
use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib";

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
}

sub run_system {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    my $status = $?;
    ($status == 0) or die "%Error: Command Failed $command, $status, stopped";
}

sub files_identical {
    my $fn1 = shift;
    my $fn2 = shift;
    my $f1 = IO::File->new ($fn1) or die "%Error: $! $fn1,";
    my $f2 = IO::File->new ($fn2) or die "%Error: $! $fn2,";
    my @l1 = $f1->getlines();
    my @l2 = $f2->getlines();
    my $nl = $#l1;  $nl = $#l2 if ($#l2 > $nl);
    for (my $l=0; $l<$nl; $l++) {
	if (($l1[$l]||"") ne ($l2[$l]||"")) {
	    warn ("%Warning: Line ".($l+1)." mismatches; $fn1 != $fn2\n"
		  ."F1: ".($l1[$l]||"*EOF*\n")
		  ."F2: ".($l2[$l]||"*EOF*\n"));
	    return 0;
	}
    }
    return 1;
}

1;
