# Verilog - Verilog Perl Interface
# $Revision: #14 $$Date: 2002/10/21 $$Author: wsnyder $
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

package Verilog::Netlist;
use Carp;
use IO::File;

use Verilog::Netlist::Module;
use Verilog::Netlist::File;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist::Subclass);
use strict;
use vars qw($Debug $Verbose $VERSION);

$VERSION = '2.214';

######################################################################
#### Error Handling

# Netlist file & line numbers don't apply
sub filename { return 'Verilog::Netlist'; }
sub lineno { return ''; }

######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = {_modules => {},
		_files => {},
		options => undef,	# Usually pointer to Verilog::Getopt
		implicit_wires_ok => 1,
		link_read => 1,
		sp_allow_output_tracing => 0,
		@_};
    bless $self, $class;
    return $self;
}

######################################################################
#### Functions

sub link {
    my $self = shift;
    $self->{_relink} = 1;
    while ($self->{_relink}) {
	$self->{_relink} = 0;
	foreach my $modref ($self->modules) {
	    next if $modref->is_libcell();
	    $modref->link();
	}
	foreach my $fileref ($self->files) {
	    $fileref->_link();
	}
    }
}
sub lint {
    my $self = shift;
    foreach my $modref ($self->modules_sorted) {
	next if $modref->is_libcell();
	$modref->lint();
    }
}
sub dump {
    my $self = shift;
    foreach my $modref ($self->modules_sorted) {
	$modref->dump();
    }
}

######################################################################
#### Module access

sub new_module {
    my $self = shift;
    # @_ params
    # Can't have 'new Verilog::Netlist::Module' do this,
    # as not allowed to override Class::Struct's new()
    my $modref = new Verilog::Netlist::Module
	(netlist=>$self,
	 is_top=>1,
	 @_);
    $self->{_modules}{$modref->name} = $modref;
    return $modref;
}

sub defvalue_nowarn {
    my $self = shift;
    my $sym = shift;
    # Look up the value of a define, letting the user pick the accessor class
    if ($self->{options}) {
	return $self->{options}->defvalue_nowarn($sym);
    }
    return undef;
}

sub remove_defines {
    my $self = shift;
    my $sym = shift;
    my $val = "x";
    while (defined $val) {
	last if $sym eq $val;
	(my $xsym = $sym) =~ s/^\`//;
	$val = $self->defvalue_nowarn($xsym);  #Undef if not found
	$sym = $val if defined $val;
    }
    return $sym;
}

sub find_module {
    my $self = shift;
    my $search = shift;
    # Return module maching name
    my $mod = $self->{_modules}{$search};
    return $mod if $mod;
    # Allow FOO_CELL to be a #define to choose what instantiation is really used
    my $rsearch = $self->remove_defines($search);
    if ($rsearch ne $search) {
	return $self->find_module($rsearch);
    }
    return undef;
}
    
sub modules {
    my $self = shift;
    # Return all modules
    return (values %{$self->{_modules}});
}

sub modules_sorted {
    my $self = shift;
    # Return all modules
    return (sort {$a->name() cmp $b->name()} (values %{$self->{_modules}}));
}

######################################################################
#### Files access

sub resolve_filename {
    my $self = shift;
    my $filename = shift;
    my $from = shift;
    if ($self->{options}) {
	$filename = $self->remove_defines($filename);
	$filename = $self->{options}->file_path($filename);
    }
    if (!-r $filename) {
	$from->error("Cannot open $filename") if $from;
	die "%Error: Cannot open $filename\n";
    }
    $self->dependency_in ($filename);
    return $filename;
}

sub new_file {
    my $self = shift;
    # @_ params
    # Can't have 'new Verilog::Netlist::File' do this,
    # as not allowed to override Class::Struct's new()
    my $fileref = new Verilog::Netlist::File
	(netlist=>$self,
	 @_);
    defined $fileref->name or carp "%Error: No name=> specified, stopped";
    $self->{_files}{$fileref->name} = $fileref;
    $fileref->basename (Verilog::Netlist::Module::modulename_from_filename($fileref->name));
    return $fileref;
}

sub find_file {
    my $self = shift;
    my $search = shift;
    # Return file maching name
    return $self->{_files}{$search};
}
    
sub files {
    my $self = shift; ref $self or die;
    # Return all files
    return (sort {$a->name() cmp $b->name()} (values %{$self->{_files}}));
}
sub files_sorted { return files(@_); }

sub read_file {
    my $self = shift;
    my $fileref = Verilog::Netlist::File::read
	(netlist=>$self,
	 @_);
}

######################################################################
#### Dependancies

sub dependency_in {
    my $self = shift;
    my $filename = shift;
    $self->{_depend_in}{$filename} = 1;
}
sub dependency_out {
    my $self = shift;
    my $filename = shift;
    $self->{_depend_out}{$filename} = 1;
}

sub dependency_write {
    my $self = shift;
    my $filename = shift;

    my $fh = IO::File->new(">$filename") or die "%Error: $! $filename\n";
    print $fh "$filename";
    foreach my $dout (sort (keys %{$self->{_depend_out}})) {
	print $fh " $dout";
    }
    print $fh " :";
    foreach my $din (sort (keys %{$self->{_depend_in}})) {
	print $fh " $din";
    }
    print $fh "\n";
    $fh->close();
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Netlist - Verilog Netlist

=head1 SYNOPSIS

  use Verilog::Netlist;

    # Setup options so files can be found
    use Verilog::Getopt;
    my $opt = new Verilog::Getopt;
    $opt->parameter( "+incdir+verilog",
		     "-y","verilog",
		     );

    # Prepare netlist
    my $nl = new Verilog::Netlist (options => $opt,);
    foreach my $file ('testnetlist.sp') {
	$nl->read_file (filename=>$file);
    }
    # Read in any sub-modules
    $nl->link();
    $nl->lint();
    $nl->exit_if_error();

    foreach my $mod ($nl->modules_sorted) {
	if ($mod->is_top) {
	    show_hier ($mod, "  ", "");
	}
    }

    sub show_hier {
	my $mod = shift;
	my $indent = shift;
	my $hier = shift;
	$hier .= $mod->name;
	printf ("%-38s %s\n", $indent."Module ".$mod->name,$hier);
	foreach my $cell ($mod->cells_sorted) {
	    show_hier ($cell->submod, $indent."  ", $hier.".");
	}
    }

=head1 DESCRIPTION

Verilog::Netlist contains interconnect information about a whole design
database.

The database is composed of files, which contain the text read from each
file.

A file may contain modules, which are individual blocks that can be
instantiated (designs, in Synopsys terminology.)

Modules have ports, which are the interconnection between nets in that
module and the outside world.  Modules also have nets, (aka signals), which
interconnect the logic inside that module.

Modules can also instantiate other modules.  The instantiation of a module
is a Cell.  Cells have pins that interconnect the referenced module's pin
to a net in the module doing the instantiation.

Each of these types, files, modules, ports, nets, cells and pins have a
class.  For example Verilog::Netlist::Cell has the list of
Verilog::Netlist::Pin (s) that interconnect that cell.

=head1 FUNCTIONS

=over 4

=item $netlist->error

Prints an error in a standard way, and increments $Errors.

=item $netlist->lint

Error checks the entire netlist structure.

=item $netlist->link()

Resolves references between the different modules.  If link_read=>1 is
passed when netlist->new is called (it is by default), undefined modules
will be searched for using the Verilog::Getopt package, passed by a
reference in the creation of the netlist.

=item $netlist->new

Creates a new netlist structure.  Pass optional parameters by name.  The
parameter "options" may contain a reference to a Verilog::Getopt module,
to be used for locating files.

=item $netlist->dump

Prints debugging information for the entire netlist structure.

=item $netlist->warn

Prints a warning in a standard way, and increments $Warnings.

=back

=head1 MODULE FUNCTIONS

=over 4

=item $netlist->find_module($name)

Returns Verilog::Netlist::Module matching given name.

=item $netlist->modules_sorted

Returns list of all Verilog::Netlist::Module.

=item $netlist->new_module

Creates a new Verilog::Netlist::Module.

=back

=head1 FILE FUNCTIONS

=over 4

=item $netlist->find_file($name)

Returns Verilog::Netlist::File matching given name.

=item $netlist->read_file( filename=>$name)

Reads the given Verilog file, and returns a Verilog::Netlist::File
reference.

=item $netlist->files

Returns list of all files.

Generally called as $netlist->read_file.  Pass a hash of parameters.  Reads
the filename=> parameter, parsing all instantiations, ports, and signals,
and creating Verilog::Netlist::Module structures.

=item $netlist->dependency_write($name)

Writes a dependency file for make, listing all input and output files.

=back

=head1 SEE ALSO

L<Verilog::Netlist::Cell>,
L<Verilog::Netlist::File>,
L<Verilog::Netlist::Module>,
L<Verilog::Netlist::Net>,
L<Verilog::Netlist::Pin>,
L<Verilog::Netlist::Port>,
L<Verilog::Netlist::Subclass>

=head1 DISTRIBUTION

The latest version is available from CPAN and from C<http://veripool.com/>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
