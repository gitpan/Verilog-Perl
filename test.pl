#$Id: test.pl,v 1.3 2000/01/21 15:56:08 wsnyder Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
######################################################################

use Verilog::Language;
print "ok 1\n";

# Test vrename
print "Checking vrename...\n";

unlink 'signals.vrename';
system ("perl -Iblib/arch -Iblib/lib vrename -list -xref test.v");
print ((-r 'signals.vrename')
       ? "ok 2\n" : "not ok 2\n");

mkdir 'test_dir', 0777;
system ("perl -Iblib/arch -Iblib/lib vrename -change --changefile test.vrename -o test_dir test.v");
print ((-r 'test_dir/test.v')
       ? "ok 3\n" : "not ok 3\n");
