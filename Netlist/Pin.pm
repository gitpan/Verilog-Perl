# Verilog - Verilog Perl Interface
# $Revision: #15 $$Date: 2003/03/04 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
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

package Verilog::Netlist::Pin;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Port;
use Verilog::Netlist::Net;
use Verilog::Netlist::Cell;
use Verilog::Netlist::Module;
use Verilog::Netlist::Pin;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist::Pin::Struct
	Verilog::Netlist::Subclass);
$VERSION = '2.221';
use strict;

structs('new',
	'Verilog::Netlist::Pin::Struct'
	=>[name     	=> '$', #'	# Pin connection
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   userdata	=> '%',		# User information
	   #
	   netname	=> '$', #'	# Net connection
	   portname 	=> '$', #'	# Port connection name
	   cell     	=> '$', #'	# Cell reference
	   # below only after link()
	   net		=> '$', #'	# Net connection reference
	   port		=> '$', #'	# Port connection reference
	   # SystemPerl: below only after autos()
	   sp_autocreated => '$', #'	# Created by auto()
	   # below by accessor computation
	   #module
	   #submod
	   ]);

sub module {
    return $_[0]->cell->module;
}
sub submod {
    return $_[0]->cell->submod;
}
sub netlist {
    return $_[0]->cell->module->netlist;
}

sub _link {
    my $self = shift;
    my $change;
    if (!$self->net
	&& $self->netname) {
	$self->net($self->module->find_net($self->netname));
	$change = 1;
    }
    if (!$self->port
	&& $self->portname && $self->submod) {
	$self->port($self->submod->find_port($self->portname));
	$change = 1;
    }
    if ($change && $self->net && $self->port) {
	$self->net->_used_in_inc()    if ($self->port->direction() eq 'in');
	$self->net->_used_out_inc()   if ($self->port->direction() eq 'out');
	$self->net->_used_inout_inc() if ($self->port->direction() eq 'inout');
    }
}

sub lint {
    my $self = shift;
    if (!$self->net && !$self->netlist->{implicit_wires_ok}) {
        $self->error ("Pin's net declaration not found: ",$self->netname,"\n");
    }
    if (!$self->port && $self->submod) {
        $self->error ($self,"Port not found in module ",$self->submod->name,": ",$self->portname,"\n");
    }
    if ($self->port && $self->net) {
	my $nettype = $self->net->type;
	my $porttype = $self->port->type;
	if ($nettype ne $porttype) {
	    $self->error("Port pin type $porttype != Net type $nettype: "
			 ,$self->name,"\n");
	}
	my $netdir = "net";
	$netdir = $self->net->port->direction if $self->net->port;
	my $portdir = $self->port->direction;
	if (($netdir eq "in" && $portdir eq "out")
	    #Legal: ($netdir eq "in" && $portdir eq "inout")
	    #Legal: ($netdir eq "out" && $portdir eq "inout")
	    ) {
	    $self->error("Port is ${portdir}put from submodule, but ${netdir}put from this module: "
			 ,$self->name,"\n");
	    #$self->cell->module->netlist->dump;
	}
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Pin:",$self->name(),"  Net:",$self->netname(),"\n";
    if ($self->port) {
	$self->port->dump($indent+10, 'norecurse');
    }
    if ($self->net) {
	$self->net->dump($indent+10, 'norecurse');
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Netlist::Pin - Pin on a Verilog Cell

=head1 SYNOPSIS

  use Verilog::Netlist;

  ...
  my $pin = $cell->find_pin ('pinname');
  print $pin->name;

=head1 DESCRIPTION

Verilog::Netlist creates a pin for every pin connection on a cell.  A Pin
connects a net in the current design to a port on the instantiated cell's
module.

=head1 ACCESSORS

See also Verilog::Netlist::Subclass for additional accessors and methods.

=over 4

=item $self->cell

Reference to the Verilog::Netlist::Cell the pin is under.

=item $self->module

Reference to the Verilog::Netlist::Module the pin is in.

=item $self->name

The name of the pin.  May have extra characters to make vectors connect,
generally portname is a more readable version.  There may be multiple pins
with the same portname, only one pin has a given name.

=item $self->net

Reference to the Verilog::Netlist::Net the pin connects to.  Only valid after a link.

=item $self->netlist

Reference to the Verilog::Netlist the pin is in.

=item $self->netname

The net name the pin connects to.

=item $self->portname

The name of the port connected to.

=item $self->port

Reference to the Verilog::Netlist::Port the pin connects to.  Only valid after a link.

=back

=head1 MEMBER FUNCTIONS

See also Verilog::Netlist::Subclass for additional accessors and methods.

=over 4

=item $self->lint

Checks the pin for errors.  Normally called by Verilog::Netlist::lint.

=item $self->dump

Prints debugging information for this pin.

=back

=head1 SEE ALSO

L<Verilog::Netlist::Subclass>
L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
