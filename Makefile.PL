# vrename Makefile.PL

use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

maintainer-clean: distclean
	-rm README Makefile

dist: distcheck README
";
}

WriteMakefile(
	VERSION   => '1.3',
	DISTNAME  => 'Verilog-Perl',
	NAME      => 'Verilog::Language',
	EXE_FILES => [qw( vrename )],
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'README all tardist',
		     },
	);

