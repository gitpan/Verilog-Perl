# $Revision: #6 $$Date: 2002/10/25 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;
use Config;

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

#print Config::myconfig();
my @ld_set;
if ($Config{osname} !~ /cygwin/i && $Config{archname} !~ /cygwin/i) {
    # Cygwin: Don't change LD, it breaks
    # Sun: Requires g++ LD
    # Linux: Either way
    push @ld_set, (LD => 'g++',);
}

WriteMakefile(
              NAME => "Verilog::Preproc",
	      CC => 'g++',
	      @ld_set,
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
