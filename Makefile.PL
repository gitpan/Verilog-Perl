# $Id: Makefile.PL,v 1.15 2001/02/13 15:11:15 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;
use Carp;

$DOLLAR = '$$';	# Quoted properly for make
sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

vpm maintainer-copy:
	perl -pe '${DOLLAR}skip = 1 if /--MAKER--/; print ${DOLLAR}_ if ! ${DOLLAR}skip; ${DOLLAR}skip = 0 if /--ENDMAKER--/; ${DOLLAR}_=qq{};' < ../../vpm > vpm
	chmod a+x vpm

maintainer-clean: distclean
	-rm README Makefile

clean::
	-rm -rf simv .vpm

dist: maintainer-copy distcheck README

tag:
	cvs tag -F V\$(VERSION_SYM) .
";
}

WriteMakefile(
	      DISTNAME  => 'Verilog-Perl',
	      NAME      => 'Verilog::Language',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'Verilog language utilities and parsing',
	      VERSION_FROM  => 'Language.pm',
	      EXE_FILES => [qw( vrename vpm )],
	      'clean'	=> {FILES => qw (test_dir signals.vrename .vpm simv ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

