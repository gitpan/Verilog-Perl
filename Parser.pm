# Verilog::Parser.pm -- Verilog parsing
# $Id: Parser.pm,v 1.5 2000/05/18 14:34:33 wsnyder Exp $
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

Verilog::Parser - Parse Verilog language files

=head1 SYNOPSIS

  use Verilog::Parser;

  my $parser = new Verilog::Parser;
  $string = $parser->unreadback ();
  $line   = $parser->line ();
  $parser->parse ($text)
  $parser->parse_file ($filename)

=head1 DESCRIPTION

The C<Verilog::Parser> package will tokenize a Verilog file when the parse()
method is called and invoke various callback methods.  

The external interface to Verilog::Parser is:

=over 4

=item $parser = Verilog::Parser->new

Create a new Parser.

=item $parser->parse ($string)

Parse the $string as a verilog file.  Can be called multiple times.
The return value is a reference to the parser object.

=item $parser->parse_file ($filename);

This method can be called to parse text from a file.  The argument can
be a filename or an already opened file handle. The return value from
parse_file() is a reference to the parser object.

=item $parser->unreadback ()

Return any input string from the file that has not been sent to the
callback.  This will include whitespace and tokens which did not have a
callback.  (For example comments, if there is no comment callback.)  This
is useful for recording the entire contents of the input, for
preprocessors, pretty-printers, and such.

=item $parser->line ($set)

Return (if $set is undefined) or set current line number.

=back

In order to make the parser do anything interesting, you must make a
subclass where you override one or more of the following methods as
appropriate:

=over 4

=item $self->comment ( $token )

This method is called when any text in // or /**/ comments are recognized.
The first argument, $token, is the contents of the comment excluding the
comment delimiters.

=item $self->string ( $token )

This method is called when any text in double quotes are recognized.
The first argument, $token, is the contents of the string including the
quotes.

=item $self->keyword ( $token )

This method is called when any Verilog keyword is recognized.
The first argument, $token, is the keyword.

=item $self->symbol ( $token )

This method is called when any Verilog symbol is recognized.  A symbol is
considered a non-keyword bareword.  The first argument, $token, is the
symbol.

=item $self->operator ( $token )

This method is called when any symbolic operator (+, -, etc) is recognized.
The first argument, $token, is the operator.

=item $self->number ( $token )

This method is called when any number is recognized.  The first argument,
$token, is the number.  The Verilog::Language::number_value function may be
useful for converting a Verilog value to a perl integer.

=back

=head1 EXAMPLE

Here\'s a simple example which will print every symbol in a verilog
file.

package MyParser;
use Verilog::Parser;
@ISA = qw(Verilog::Parser);

# parse, parse_file, etc are inherited from Verilog::Parser
sub new {
    my $class = shift;
    #print "Class $class\n";
    my $self = $class->SUPER::new();
    # we could have inherited new, but we want to initialize symbols
    %{$self->{symbols}} = ();
    bless $self, $class; 
    return $self;
}

sub symbol {
    my $self = shift;
    my $token = shift;
    
    $self->{symbols}{$token}++;
}

sub report {
    my $self = shift;

    foreach my $sym (sort keys %{$self->{symbols}}) {
	 printf "Symbol %-30s occurs %4d times\n",
	 $sym, $self->{symbols}{$sym};
    }
}

package main;

my $parser = MyParser->new();
$parser->parse_file (shift);
$parser->report();

=head1 SEE ALSO

C<Verilog::ParserSig>, 
C<Verilog::Language>, 
C<vrename>

=head1 BUGS

This is being distributed as a baseline for future contributions.  Don\'t
expect a lot, the Parser is still nieve, and there are many awkward cases
that aren\'t covered.

The parser currently assumes the string it is passed ends on a newline
boundary.  It should be changed to allow arbitrary chunks.

=head1 DISTRIBUTION

The latest version is available from
C<http://www.ultranet.com/~wsnyder/verilog-perl>.

=head1 AUTHORS

Wilson Snyder <wsnyder@world.std.com>

=cut

######################################################################


package Verilog::Parser;
require 5.000;
require Exporter;

use strict;
use vars qw($VERSION $Debug);
use English;
use Carp;
use FileHandle;
use Verilog::Language;

######################################################################
#### Configuration Section

# Other configurable settings.
$Debug = 0;		# for debugging

$VERSION = '1.4';

#######################################################################

sub new {
    @_ >= 1 or croak 'usage: Verilog::Parser->new ({options})';
    my $class = shift;		# Class (Parser Element)
    $class ||= "Verilog::Parser";

    print "$class->new()\n" if $Debug;

    my $self = {unreadback => "",	# Text since last callback
		line => 0,
		incomment => 0,
		inquote => 0,
		preprocess => 0,
	    };
    while (@_) {
	my $param = shift; my $value = shift;
	$self->{$param} = $value;
    }

    bless $self, $class;
    return $self;
}

######################################################################
####  Accessors

sub unreadback {
    # Return any un read text and clear it
    my $self = shift;	# Parser
    if (@_) {
	$self->{unreadback} = shift;
    } else {
	my $info = $self->{unreadback};
	$self->{unreadback} = "";
	return $info;
    }
}

sub line {
    # Return any un read text and clear it
    my $self = shift;	# Parser
    if (@_) {
	$self->{line} = shift;
    }
    return $self->{line};
}

#######################################################################

sub comment {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

sub string {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

sub keyword {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

sub symbol {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

sub operator {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

sub number {
    # Default Internal callback
    my $self = shift;	# Parser invoked
    my $token = shift;	# What token was parsed
    $self->{unreadback} .= $token;
}

#######################################################################

sub parse {
    # Parse a string
    @_ == 2 or croak 'usage: $parser->parse($string)';
    my $self = shift;
    my $text = shift;

    my $line;
    $self->{line} ++ if ($text eq "\n");	# Foreach will find nothing
    foreach $line (split /\n/, $text) {
	# Keep parsing whatever is on this line
	$self->{line} ++;
	while ($line) {
	    print "Lnc $line\n" if ($Debug);
	    if ($self->{incomment}) {
		if ($line =~ /\*\//) {
		    $self->{token_string} .= $PREMATCH . $MATCH;
		    $line = $POSTMATCH;
		    my $token = $self->{token_string};
		    print "GotaCOMMENT $token\n"    if ($Debug);
		    $self->comment ($token);
		    $self->{incomment} = 0;
		}
		else {
		    $self->{token_string} .= $line;
		    $line = "";
		}
	    }
	    elsif ($self->{inquote}) {
		# Check for strings
		if ($line =~ /\"/) {
		    $self->{token_string} .= $PREMATCH . $MATCH;
		    $line = $POSTMATCH;
		    if ($PREMATCH !~ /\\$/) {
			my $token = $self->{token_string};
			print "GotaSTRING $token\n"    if ($Debug);
			$self->string ($token);
			$self->{inquote} = 0;
		    }
		} else {
		    $self->{token_string} .= $line;
		}
	    }
	    else {
		# not in comment
		# Strip leading whitespace
		if ($line =~ s/^(\s+)//) {
		    $self->{unreadback} .= $MATCH;
		}
		next if ($line eq "");
		if ($line =~ /^\"/) {
		    $line = $POSTMATCH;
		    $self->{token_string} = $MATCH;
		    $self->{inquote} = 1;
		}
		elsif (($line =~ /^[a-zA-Z_\`\$][a-zA-Z0-9_\`\$]*/)
                       || ($line =~ /^\\\S+\s+/)) { #cseddon - escaped identifiers
		    my $token = $MATCH;
		    $line = $POSTMATCH;
		    if (!$self->{inquote}) {
			if (Verilog::Language::is_keyword($token)) {
			    print "GotaKEYWORD $token\n"    if ($Debug);
			    $self->keyword ($token);
			} else {
			    print "GotaSYMBOL $token\n"    if ($Debug);
			    $self->symbol ($token);
			}
		    }
		}
		elsif ($line =~ /^\/\*/) {
		    $self->{token_string} = $MATCH;
		    $line = $POSTMATCH;
		    $self->{incomment} = 1;
		}
		elsif ($line =~ /^\/\//) {
		    my $token = $line;
		    print "GotaCOMMENT $token\n"    if ($Debug);
		    $self->comment ($token);
		    $line = "";
		}
		elsif (($line =~ /^(&& | \|\| | == | != | <= | >= | << | >> )/x)
		       || ($line =~ /^([][:;@\(\),.%!=<>?|&{}~^+---\/*\#])/)) {  #]
		    my $token = $MATCH;
		    $line = $POSTMATCH;
		    print "GotaOPERATOR $token\n"    if ($Debug);
		    $self->operator ($token);
		}
		elsif (($line =~ /^([0-9]*'[bhod]\ *[0-9A-FXZa-fxz_?]+)/)    #'
		    || ($line =~ /^([0-9]+[0-9a-fA-F_]*)/ )) {
		    my $token = $MATCH;
		    $line = $POSTMATCH;
		    print "GotaNUMBER $token\n"    if ($Debug);
		    $self->number ($token);
		}
		else {
		    if ($line ne "") {
			$self->{unreadback} .= $line;
		        carp $self->{line} . ":Unknown symbol, ignoring to eol: $line\n";
	                $line = "";
                    }
		}
            }
        }
    }
    return $self;
}

#######################################################################

sub parse_file {
    # Read a file and parse
    @_ == 2 or croak 'usage: $parser->parse_file($filename)';
    my $self = shift;
    my $filename = shift;

    my $fh = new FileHandle;
    $fh->open($filename) or croak "%Error: $! $filename";
    my $line;
    while ($line = $fh->getline() ) {
	$self->parse ($line);
    }
    $fh->close();
    return $self;
}


######################################################################
### Package return
1;
