# $Id: Makefile.PL,v 1.21 2002/03/11 15:27:28 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;
use Carp;

$DOLLAR = '$$';	# Quoted properly for make
sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

clean::
	-rm -rf simv .vpm test_dir

dist: maintainer-copy distcheck README

## Maintainer use:
tag:
	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-dist: dist tag
	cp \$(DISTVNAME).tar.gz \$(HOME)/src/kits
	mv \$(DISTVNAME).tar.gz \$(HOME)/backpack

maintainer-copy:
#vpm maintainer-copy:
#	perl -pe '${DOLLAR}skip = 1 if /--MAKER--/; print ${DOLLAR}_ if ! ${DOLLAR}skip; ${DOLLAR}skip = 0 if /--ENDMAKER--/; ${DOLLAR}_=qq{};' < ../../vpm > vpm
#	chmod a+x vpm

maintainer-clean: distclean
	-rm README Makefile

";
}

local $! = undef;
`flex --version`; ($?==0) or die "\n%Error: 'flex' must be installed to build\n";
`g++ --version`; ($?==0) or die "\n%Error: 'gcc/g++' must be installed to build\n";

WriteMakefile(
	      DISTNAME  => 'Verilog-Perl',
	      NAME      => 'Verilog::Language',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'Verilog language utilities and parsing',
	      VERSION_FROM  => 'Language.pm',
	      PMLIBDIRS => ['lib', 'Verilog', 'Netlist',],
	      EXE_FILES => [qw( vrename vpm )],
	      'clean'	=> {FILES => qw (test_dir signals.vrename .vpm simv ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

