# Verilog - Verilog Perl Interface
# $Id: Cell.pm,v 1.1 2001/10/26 17:34:18 wsnyder Exp $
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

package Verilog::Netlist::Cell;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist::Cell::Struct
	Verilog::Netlist::Subclass);
$VERSION = '2.000';
use strict;

structs('new',
	'Verilog::Netlist::Cell::Struct'
	=>[name     	=> '$', #'	# Instantiation name
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   userdata	=> '%',		# User information
	   #
	   submodname	=> '$', #'	# Which module it instantiates
	   module	=> '$', #'	# Module reference
	   pins		=> '%',		# List of Verilog::Netlist::Pins
	   # after link():
	   submod	=> '$', #'	# Sub Module reference
	   # system perl
	   _autoinst	=> '$', #'	# Marked with AUTOINST tag
	   ]);

sub netlist {
    my $self = shift;
    return $self->module->netlist;
}

sub new_pin {
    my $self = shift;
    # @_ params
    # Create a new pin under this cell
    my $pinref = new Verilog::Netlist::Pin (cell=>$self, @_);
    $self->pins ($pinref->name(), $pinref);
    return $pinref;
}

sub _link_guts {
    my $self = shift;
    if ($self->submodname()) {
	my $name = $self->submodname();
	my $sm = $self->netlist->find_module ($self->submodname());
	$self->submod($sm);
	$sm->is_top(0) if $sm;
    }
    foreach my $pinref (values %{$self->pins}) {
	$pinref->_link();
    }
}
sub _link {
    my $self = shift;
    $self->_link_guts();
    if (!$self->submod()
	&& $self->netlist->{link_read}) {
	print "  Link_Read ",$self->submodname,"\n" if $Verilog::Netlist::Debug;
	$self->netlist->read_file(filename=>$self->submodname);
	$self->netlist->{_relink} = 1;
    }
}

sub lint {
    my $self = shift;
    if (!$self->submod()) {
        $self->error ($self,"Module reference not found: ",$self->submodname(),,"\n");
    }
    foreach my $pinref (values %{$self->pins}) {
	$pinref->lint();
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Cell:",$self->name(),"  is-a:",$self->submodname(),"\n";
    if ($self->submod()) {
	$self->submod->dump($indent+10, 'norecurse');
    }
    if (!$norecurse) {
	foreach my $pinref ($self->pins_sorted) {
	    $pinref->dump($indent+2);
	}
    }
}

sub pins_sorted {
    my $self = shift;
    return (sort {$a->name() cmp $b->name()} (values %{$self->pins}));
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Netlist::Cell - Instantiated cell within a Verilog Netlist

=head1 SYNOPSIS

  use Verilog::Netlist;

  ...
  my $cell = $module->find_cell ('cellname');
  print $cell->name;

=head1 DESCRIPTION

Verilog::Netlist creates a cell for every instantiation in the current
module.

=head1 ACCESSORS

=over 4

=item $self->filename

The filename the cell was created in.

=item $self->lineno

The line number the cell was created on.

=item $self->module

Pointer to the module the cell is in.

=item $self->name

The instantiation name of the cell.

=item $self->pins

List of pins connections for the cell.

=item $self->submod

Reference to the Verilog::Netlist::Module the cell instantiates.  Only
valid after the design is linked.

=item $self->submodname

The module name the cell instantiates (under the cell).

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->lint

Checks the cell for errors.  Normally called by Verilog::Netlist::lint.

=item $self->new_pin

Creates a new Verilog::Netlist::Pin connection for this cell.

=item $self->dump

Prints debugging information for this cell.

=back

=head1 SEE ALSO

L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
