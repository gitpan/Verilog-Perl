# Verilog::Language.pm -- Verilog language keywords, etc
# $Id: Language.pm,v 1.6 2000/05/22 19:50:24 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@world.std.com>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License, with the exception that it cannot be placed
# on a CD-ROM or similar media for commercial distribution without the
# prior approval of the author.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

=head1 NAME

Verilog::Language - Verilog language utilities

=head1 SYNOPSIS

  use Verilog::Language;

  $result = Verilog::Language::is_keyword ($symbol_string)
  $result = Verilog::Language::number_value ($number_string)
  $result = Verilog::Language::number_bits  ($number_string)
  @vec    = Verilog::Language::split_bus ($bus)

=head1 DESCRIPTION

This package provides useful utilities for general use with the
Verilog Language.  General functions will be added as needed.

=over 4

=item Verilog::Language::is_keyword ($symbol_string)

Return true if the given symbol string is a Verilog reserved keyword.

=head1 EXAMPLE

  print Verilog::Language::is_keyword ("module");
     1
  print Verilog::Language::is_keyword ("signalname");
     undef

=item Verilog::Language::number_value ($number_string)

Return the numeric value of a Verilog value, or undef if incorrectly
formed.  Since it is returned as a signed integer, it may fail for over 31
bit integers.

=head1 EXAMPLE

  print Verilog::Language::number_value ("32'h13");
     19
  print Verilog::Language::number_value ("32'p2");
     undef

=item Verilog::Language::number_bits ($number_string)

Return the number of bits in a value string, or undef if incorrectly
formed, _or_ not specified.

=head1 EXAMPLE

  print Verilog::Language::number_bits ("32'h13");
     32

=item Verilog::Language::split_bus ($bus)

Return a list of expanded arrays.  When passed a string like
"foo[5:1:2,10:9]", it will return a array with ("foo[5]", "foo[3]", ...).
It correctly handles connectivity expansion also, so that "x[1:0] = y[3:0]"
will get intuitive results.

=back

=head1 DISTRIBUTION

The latest version is available from
C<http://www.ultranet.com/~wsnyder/verilog-perl>.

=head1 AUTHORS

Wilson Snyder <wsnyder@world.std.com>

=cut
######################################################################

package Verilog::Language;
require 5.000;
require Exporter;

use strict;
use vars qw($VERSION);
use English;

######################################################################
#### Configuration Section

$VERSION = '1.5';

######################################################################
#### Internal Variables

my $kwd;
foreach $kwd ("`define", "`else", "`endif", "`ifdef", "`include",
	      "`timescale", "`undef", "always", "and", "assign", "begin",
	      "buf", "bufif0", "bufif1", "case", "casex", "casez", "cmos",
	      "default", "defparam", "else", "end", "endcase",
	      "endfunction", "endmodule", "endprimitive", "endspecify",
	      "endtable", "endtask", "event", "for", "force", "forever",
	      "fork", "function", "if", "initial", "inout", "input",
	      "integer", "join", "macromodule", "makefile", "module",
	      "nand", "negedge", "nmos", "nor", "not", "notif0", "notif1",
	      "or", "output", "parameter", "pmos", "posedge", "primitive",
	      "pulldown", "pullup", "rcmos", "real", "realtime", "reg",
	      "repeat", "rnmos", "rpmos", "rtran", "rtranif0", "rtranif1",
	      "signed", "specify", "supply", "supply0", "supply1", "table",
	      "task", "time", "tran", "tranif0", "tranif1", "tri", "tri0",
	      "tri1", "triand", "trior", "trireg", "vectored", "wait",
	      "wand", "while", "wire", "wor", "xnor", "xor") {
    $Verilog::Language::keyword{$kwd} = 1;
}

######################################################################
#### Keyword utilities

sub is_keyword {
    my $symbol = shift;
    return ($Verilog::Language::keyword {$symbol});
}

######################################################################
#### Numeric utilities

sub number_bits {
    my $number = shift;
    if ($number =~ /^\s*([0-9]+)\'/i) {
	return $1;
    }
    return undef;
}

sub number_value {
    my $number = shift;
    $number =~ s/_//g;
    if ($number =~ /\'h([0-9a-f]+)$/i) {
	return (hex ($1));
    }
    elsif ($number =~ /\'o([0-9a-f]+)$/i) {
	return (oct ($1));
    }
    elsif ($number =~ /\'b([0-1]+)$/i) {
	my $val = 0;
	my $bit;
	$number = $1;
	foreach $bit (split(//, $number)) {
	    $val = ($val<<1) | ($bit=='1'?1:0);
	}
	return ($val);
    }
    elsif ($number =~ /\'d([0-9]+)$/i
	   || $number =~ /^([0-9]+)$/i) {
	return ($1);
    }
    return undef;
}

######################################################################
#### Signal utilities

sub split_bus {
    my $bus = shift;
    if ($bus !~ /\[/) {
	# Fast case: No bussing
	return $bus;
    } elsif ($bus =~ /^([^\[]+\[)([0-9]+):([0-9]+)(\][^\]])$/) {
	# Middle speed case: Simple max:min
	my $bit;
	my @vec = ();
	if ($2 >= $3) {
	    for ($bit = $2; $bit >= $3; $bit --) {
		push @vec, $1 . $bit . $4;
	    }
	} else {
	    for ($bit = $2; $bit <= $3; $bit ++) {
		push @vec, $1 . $bit . $4;
	    }
	}
	return @vec;
    } else {
	# Complex case: x:y:z,p,...	etc
	# Do full parsing
	my @pretext = ();	# [brnum]
	my @expanded = ();	# [brnum][bitoccurance]
	my $inbra = 0;
	my $brnum = 0;
	my ($beg,$end,$step);
	foreach (split (/([:\]\[,])/, $bus)) {
	    if (/^\[/) {
		$inbra = 1;
		$pretext[$brnum] .= $_;
	    } 
	    if (!$inbra) {
		# Not in bracket, just remember text
		$pretext[$brnum] .= $_;
		next;
	    }
	    if (/[\],]/) {
		if (defined $beg) {
		    # End of bus piece
		    #print "Got seg $beg $end $step\n";
		    my $bit;
		    if ($beg >= $end) {
			for ($bit = $beg; $bit >= $end; $bit -= $step) {
			    push @{$expanded[$brnum]}, $bit;
			}
		    } else {
			for ($bit = $beg; $bit <= $end; $bit += $step) {
			    push @{$expanded[$brnum]}, $bit;
			}
		    }
		}
		$beg = undef;
		# Now what?
		if (/^\]/) {
		    $inbra = 0;
		    $brnum++;
		    $pretext[$brnum] .= $_;
		}
		elsif (/,/) {
		    $inbra = 1;
		}
	    } elsif (/:/) {
		$inbra++;
	    }
	    else {
		if ($inbra == 1) {	# Begin value
		    $beg = $end = number_value ($_);	# [2'b11:2'b00] is legal
		    $step = 1;
		} elsif ($inbra == 2) {	# End value
		    $end = number_value ($_);		# [2'b11:2'b00] is legal
		} elsif ($inbra == 3) {	# Middle value
		    $step = number_value ($_);		# [2'b11:2'b00] is legal
		}
		# Else ignore extra colons
	    }
	}

	# Determine max size of any bracket expansion array
	my $br;
	my $max_size = $#{$expanded[0]};
	for ($br=1; $br<$brnum; $br++) {
	    my $len = $#{$expanded[$br]};
	    if ($len < 0) {
		push @{$expanded[$br]}, "";
		$len = 0;
	    }
	    $max_size = $len if $max_size < $len;
	}

	my $i;
	my @vec = ();
	for ($i=0; $i<=$max_size; $i++) {
	    $bus = "";
	    for ($br=0; $br<$brnum; $br++) {
		#print "i $i  br $br >", $pretext[$br],"<\n";
		$bus .= $pretext[$br] . $expanded[$br][$i % (1+$#{$expanded[$br]})];
	    }
	    $bus .= $pretext[$br];	# Trailing stuff
	    push @vec, $bus;
	}
	return @vec;
    }
}

#sub split_bus_test {
#    my $x;
#    $x = "ff[5:1:2,4]e";
#    foreach (Verilog::Language::split_bus ($x)) {
#	 print "MM $x .. $_\n";
#    }
#    $x = "ff[3:1]  bar [4'ha:3] end";
#    foreach (Verilog::Language::split_bus ($x)) {
#	 print "MM $x .. $_\n";
#    }
#    die;
#}

sub split_bus_nocomma {
    # Faster version of split_bus
    my $bus = shift;
    if ($bus !~ /:/) {
	# Fast case: No bussing
	return $bus;
    } elsif ($bus =~ /^([^\[]+\[)([0-9]+):([0-9]+)(\][^\]])$/) {
	# Middle speed case: Simple max:min
	my $bit;
	my @vec = ();
	if ($2 >= $3) {
	    for ($bit = $2; $bit >= $3; $bit --) {
		push @vec, $1 . $bit . $4;
	    }
	} else {
	    for ($bit = $2; $bit <= $3; $bit ++) {
		push @vec, $1 . $bit . $4;
	    }
	}
	return @vec;
    } else {
	# Complex case: x:y	etc
	# Do full parsing
	my @pretext = ();	# [brnum]
	my @expanded = ();	# [brnum][bitoccurance]
	my $inbra = 0;
	my $brnum = 0;
	my ($beg,$end);
	foreach (split (/([:\]\[])/, $bus)) {
	    if (/^\[/) {
		$inbra = 1;
		$pretext[$brnum] .= $_;
	    } 
	    if (!$inbra) {
		# Not in bracket, just remember text
		$pretext[$brnum] .= $_;
		next;
	    }
	    if (/[\]]/) {
		if (defined $beg) {
		    # End of bus piece
		    #print "Got seg $beg $end\n";
		    my $bit;
		    if ($beg >= $end) {
			for ($bit = $beg; $bit >= $end; $bit--) {
			    push @{$expanded[$brnum]}, $bit;
			}
		    } else {
			for ($bit = $beg; $bit <= $end; $bit++) {
			    push @{$expanded[$brnum]}, $bit;
			}
		    }
		}
		$beg = undef;
		# Now what?
		if (/^\]/) {
		    $inbra = 0;
		    $brnum++;
		    $pretext[$brnum] .= $_;
		}
	    } elsif (/:/) {
		$inbra++;
	    }
	    else {
		if ($inbra == 1) {	# Begin value
		    $beg = $end = $_;
		} elsif ($inbra == 2) {	# End value
		    $end = $_;
		}
		# Else ignore extra colons
	    }
	}

	# Determine max size of any bracket expansion array
	my $br;
	my $max_size = $#{$expanded[0]};
	for ($br=1; $br<$brnum; $br++) {
	    my $len = $#{$expanded[$br]};
	    if ($len < 0) {
		push @{$expanded[$br]}, "";
		$len = 0;
	    }
	    $max_size = $len if $max_size < $len;
	}

	my $i;
	my @vec = ();
	for ($i=0; $i<=$max_size; $i++) {
	    $bus = "";
	    for ($br=0; $br<$brnum; $br++) {
		#print "i $i  br $br >", $pretext[$br],"<\n";
		$bus .= $pretext[$br] . $expanded[$br][$i % (1+$#{$expanded[$br]})];
	    }
	    $bus .= $pretext[$br];	# Trailing stuff
	    push @vec, $bus;
	}
	return @vec;
    }
}

######################################################################
#### Package return
1;
