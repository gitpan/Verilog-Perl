#$Id: test.pl,v 1.8 2001/02/09 15:43:48 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
######################################################################

use Verilog::Language;
print "ok 1\n";

######################################################################
# Test package
if (1) {
    print ((Verilog::Language::is_keyword("input"))
	   ? "ok 1\n" : "not ok 1\n");
    print ((!Verilog::Language::is_keyword("not_input"))
	   ? "ok 2\n" : "not ok 2\n");
    print ((Verilog::Language::is_compdirect("`define"))
	   ? "ok 3\n" : "not ok 3\n");
}

######################################################################
# Test vrename
if (1) {
    print "Checking vrename...\n";

    unlink 'signals.vrename';
    run_system ("perl -Iblib/arch -Iblib/lib vrename -list -xref verilog/test.v");
    print ((-r 'signals.vrename')
	   ? "ok 10\n" : "not ok 10\n");

    mkdir 'test_dir', 0777;
    mkdir 'test_dir/verilog', 0777;
    run_system ("perl -Iblib/arch -Iblib/lib vrename -change --changefile verilog/test.vrename -o test_dir verilog/test.v");
    print ((-r 'test_dir/verilog/test.v')
	   ? "ok 11\n" : "not ok 11\n");
}

######################################################################
# Test vpm
if (1) {
    print "Checking vpm...\n";

    # Preprocess the files
    mkdir ".vpm", 0777;
    run_system ("perl -Iblib/arch -Iblib/lib ./vpm --date verilog/");
    print ((-r '.vpm/pli.v')
	   ? "ok 20\n" : "not ok 20\n");

    # Build the model
    unlink "simv";
    if (!-r "$ENV{VCS_HOME}/bin/vcs") {
	warn "*** You do not have VCS installed, not running rest of test!\n";
	print ("not ok 21\n");
    } else {
	run_system (# We use VCS, insert your simulator here
		    "$ENV{VCS_HOME}/bin/vcs"
		    # vpm uses `pli to point to the hiearchy of the pli module
		    ." +define+pli=pli"
		    # vpm uses `__message_on to point to the message on variable
		    ." +define+__message_on=pli.message_on"
		    # Read files from .vpm BEFORE reading from other directories
		    ." +librescan +libext+.v -y .vpm"
		    # Finally, read the needed top level file
		    ." .vpm/example.v");
	
	# Execute the model (VCS is a compiled simulator)
	run_system ("./simv");
	
	print ("ok 21\n");
    }
}

######################################################################

sub run_system {
    # Run a system command, check errors
    my $command = shift;
    print "\t$command\n";
    system "$command";
    my $status = $?;
    ($status == 0) or die "%Error: Command Failed $command, $status, stopped";
}
