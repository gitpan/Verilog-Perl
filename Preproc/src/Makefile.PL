# $Id: Makefile.PL,v 1.3 2002/02/27 20:08:09 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;

sub MY::postamble {
'
LEX = flex
CCFLAGS += -Wall -Wno-unused

#CFLAGS += -DFLEX_DEBUG
#LEXFLAGS += -d -L

VPATH += src

example: example.o VPreproc.o VFileLine.o VPreprocLex.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

VPreprocLex.o:	VPreprocLex.h VPreproc.h VFileLine.h
VPreproc.o:	VPreprocLex.h VPreproc.h VFileLine.h
VFileLine.o:	VPreprocLex.h VPreproc.h VFileLine.h

VPreprocLex.cpp: VPreprocLex.l
	$(LEX) $(LEXFLAGS) -o$@ $<

clean::
	-rm -rf test *.d *.o VPreprocLex.cpp *.output example
';
}

WriteMakefile(
              NAME => "Verilog::Preproc::lib",
	      SKIP => [qw(all static static_lib dynamic dynamic_lib)],
	      CC => 'g++',
	      LD => 'g++',
	      );
