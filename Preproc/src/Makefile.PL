# $Revision: #5 $$Date: 2003/08/12 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;
use Config;

sub MY::postamble {
    my $out;
    #print Config::myconfig();
    $out .= "LD = g++\n";	# Always as we're making exe
    $out .= "CCFLAGS += -Wall -Wno-unused -Werror\n" if $ENV{VERILATOR_AUTHOR_SITE};
    $out .= '
CC = g++
LEX = flex

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
    return $out;
}

WriteMakefile(
              NAME => "Verilog::Preproc::lib",
	      SKIP => [qw(all static static_lib dynamic dynamic_lib)],
	      );
