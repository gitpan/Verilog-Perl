# Verilog - Verilog Perl Interface
# $Id: Net.pm,v 1.1 2001/10/26 17:34:18 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
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

package Verilog::Netlist::Net;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist::Net::Struct
	Verilog::Netlist::Subclass);
$VERSION = '2.000';
use strict;

######################################################################

structs('new',
	'Verilog::Netlist::Net::Struct'
	=>[name     	=> '$', #'	# Name of the net
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   userdata	=> '%',		# User information
	   #
	   type	 	=> '$', #'	# C++ Type (bool/int)
	   comment	=> '$', #'	# Comment provided by user
	   array	=> '$', #'	# Vector
	   module	=> '$', #'	# Module entity belongs to
	   # below only after links()
	   port		=> '$', #'	# Reference to port connected to
	   msb		=> '$', #'	# MSB of signal (if known)
	   lsb		=> '$', #'	# LSB of signal (if known)
	   _used_input	=> '$', #'	# Declared as signal, or input to cell
	   _used_output	=> '$', #'	# Declared as signal, or output from cell
	   # SystemPerl only: below only after autos()
	   simple_type	=> '$', #'	# True if is uint (as opposed to sc_signal)
	   sp_autocreated	=> '$', #'	# Created by /*AUTOSIGNAL*/
	   ]);

######################################################################

sub _link {}

sub width {
    my $self = shift;
    # Return bit width (if known)
    if (defined $self->msb && defined $self->lsb) {
	return ($self->msb - $self->lsb + 1);
    }
    return undef;
}

sub lint {
    my $self = shift;
    # These tests don't work because we can't determine if sequential logic gen/uses a signal
    if (0&&$self->_used_input() && !$self->_used_output()) {
	$self->warn("Signal is not generated (or needs signal declaration): ",$self->name(), "\n");
    }
    if (0&&$self->_used_output() && !$self->_used_input()
	&& $self->name() !~ /unused/) {
	$self->dump(5);
	$self->port->dump(10) if $self->port;
	$self->warn("Signal is not used (or needs signal declaration): ",$self->name(), "\n");
	flush STDOUT;
	flush STDERR;
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Net:",$self->name()
	,"  ",($self->_used_input() ? "I":""),($self->_used_output() ? "O":""),
	,"  Type:",$self->type(),"  Array:",$self->array()||"","\n";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Netlist::Net - Net for a Verilog Module

=head1 SYNOPSIS

  use Verilog::Netlist;

  ...
  my $net = $module->find_net ('signalname');
  print $net->name;

=head1 DESCRIPTION

Verilog::Netlist creates a net for every sc_signal declaration in the
current module.

=head1 ACCESSORS

=over 4

=item $self->array

Any array declaration for the net.

=item $self->comment

Any comment the user placed on the same line as the net.

=item $self->filename

The filename the net was created in.

=item $self->lineno

The line number the net was created on.

=item $self->module

Reference to the Verilog::Netlist::Module the net is in.

=item $self->name

The name of the net.

=item $self->type

The C++ type of the net.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->lint

Checks the net for errors.  Normally called by Verilog::Netlist::lint.

=item $self->dump

Prints debugging information for this net.

=back

=head1 SEE ALSO

L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
