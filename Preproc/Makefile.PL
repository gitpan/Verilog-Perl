# $Revision: #5 $$Date: 2002/09/05 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;

sub MY::postamble {
'
LEX = flex
CCFLAGS += -Wall -Wno-unused

#CFLAGS += -DFLEX_DEBUG
#LEXFLAGS += -d -L

VPATH += src

.PHONY: src/VFileLine.o src/VPreproc.o src/VPreprocLex.o

src/VFileLine.o src/VPreproc.o src/VPreprocLex.o:
	cd src && $(MAKE) $(PASSTHRU) example

clean::
	-rm -rf test *.o VPreprocLex.cpp *.output
';
}

WriteMakefile(
              NAME => "Verilog::Preproc",
	      CC => 'g++',	# Don't change LD, it messes up cygwin
	      LIBS => '-lstdc++',
	      VERSION_FROM  => 'Preproc.pm',
	      XSOPT => '-C++',
    	      OBJECT => '$(O_FILES)',
	      # Included in .xs, as had problems
	      #MYEXTLIB => 'src/PreprocSrc.o',
	      MYEXTLIB => 'src/VFileLine.o src/VPreproc.o src/VPreprocLex.o',
	      #MYEXTLIB => 'VFileLine.o VPreproc.o VPreprocLex.o',
	      INC => (" -I. -Isrc"),
	      );
