# Verilog::Getopt.pm -- Verilog command line parsing
# $Id: Getopt.pm,v 1.3 2001/05/17 18:04:10 wsnyder Exp $
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

package Verilog::Getopt;
require 5.000;
require Exporter;

use strict;
use vars qw($VERSION $Debug);
use Carp;
use IO::File;

######################################################################
#### Configuration Section

$VERSION = '1.12';

#######################################################################
#######################################################################
#######################################################################

sub new {
    @_ >= 1 or croak 'usage: Verilog::Getopt->new ({options})';
    my $class = shift;		# Class (Getopt Element)
    $class ||= "Verilog::Getopt";

    my $self = {defines => {},
		incdir => ['.', ],
		module_dir => ['.', ],
		libext => ['.v', ],
		library => [ ],
		gcc_style => 1,
		vcs_style => 1,
		fileline => 'Command_Line',
		@_
		};
    bless $self, $class;
    return $self;
}

#######################################################################
# Option parsing

sub parameter_file {
    my $self = shift;
    my $filename = shift;

    print "*parameter_file $filename\n" if $Debug;
    my $fh = IO::File->new($filename) or die "%Error: ".$self->fileline().": $! $filename\n";
    my $hold_fileline = $self->fileline();
    while (my $line = $fh->getline()) {
	chomp $line;
	$line =~ s/\/\/.*$//;
	next if $line =~ /^\s*$/;
	$self->fileline ("$filename:$.");
	my @p = (split /\s+/,"$line ");
	$self->parameter (@p);
    }
    $fh->close();
    $self->fileline($hold_fileline);
}

sub parameter {
    my $self = shift;
    # Parse VCS like parameters, and perform standard setup based on it
    # Return list of leftover parameters
    
    my @new_params = ();
    foreach my $param (@_) {
	next if ($param =~ /^\s*$/);
	print " parameter($param)\n" if $Debug;

	### GCC & VCS style
	if ($param eq '-f') {
	    $self->{_parameter_next} = $param;
	}

	### VCS style
	elsif (($param eq '-v'
		|| $param eq '-y') && $self->{vcs_style}) {
	    $self->{_parameter_next} = $param;
	}
	elsif ($param =~ /^\+libext\+(.*)$/ && $self->{vcs_style}) {
	    my $ext = $1;
	    foreach (split /\+/, $ext) {
		$self->libext($_);
	    }
	}
	elsif ($param =~ /^\+incdir\+(.*)$/ && $self->{vcs_style}) {
	    $self->incdir($1);
	}
	elsif (($param =~ /^\+define\+([^+=]*)[+=](.*)$/
		|| $param =~ /^\+define\+(.*?)()$/) && $self->{vcs_style}) {
	    $self->define ($1, $2);
	}
	# Ignored
	elsif ($param =~ /^\+librescan$/ && $self->{vcs_style}) {
	}

	### GCC style
	elsif (($param =~ /^-D([^=]*)=(.*)$/
		|| $param =~ /^-D([^=]*)()$/) && $self->{gcc_style}) {
	    $self->define($1,$2);
	}
	elsif ($param =~ /^-I(.*)$/ && $self->{gcc_style}) {
	    $self->incdir($1);
	}

	# Second parameters
	elsif ($self->{_parameter_next}) {
	    my $pn = $self->{_parameter_next};
	    $self->{_parameter_next} = undef;
	    if ($pn eq '-f') {
		$self->parameter_file ($param);
	    }
	    elsif ($pn eq '-v') {
		$self->library ($param);
	    }
	    elsif ($pn eq '-y') {
		$self->module_dir ($param);
	    }
	    else {
		die "%Error: ".$self->fileline().": Bad internal next param ".$pn;
	    }
	}

	else { # Unknown
	    push @new_params, $param;
	}
    }

    return @new_params;
}

#######################################################################
# Accessors

sub fileline {
    my $self = shift;
    if (@_) { $self->{fileline} = shift; }
    return ($self->{fileline});
}
sub incdir {
    my $self = shift;
    if (@_) {
	my $token = shift;
	print "incdir $token\n" if $Debug;
	push @{$self->{incdir}}, $token;
    }
    return ($self->{incdir});
}
sub libext {
    my $self = shift;
    if (@_) {
	my $token = shift;
	print "libext $token\n" if $Debug;
	push @{$self->{libext}}, $token;
    }
    return ($self->{libext});
}
sub library {
    my $self = shift;
    if (@_) {
	my $token = shift;
	print "library $token\n" if $Debug;
	push @{$self->{library}}, $token;
    }
    return ($self->{library});
}
sub module_dir {
    my $self = shift;
    if (@_) {
	my $token = shift;
	print "module_dir $token\n" if $Debug;
	push @{$self->{module_dir}}, $token;
    }
    return ($self->{module_dir});
}

#######################################################################
# Utility functions

sub file_path {
    my $self = shift;
    my $filename = shift;
    # return path to given filename using library directories & files, or undef

    return $filename if -r $filename;
    # Check each search path
    # We use both the incdir and moduledir.  This isn't strictly correct,
    # but it's fairly silly to have to specify both all of the time.
    my %checked = ();
    foreach my $dir (@{$self->{incdir}}, @{$self->{module_dir}}) {
	next if $checked{$dir}; $checked{$dir}=1;  # -r can be quite slow
	return "$dir/$filename" if -r "$dir/$filename";
	# Check each postfix added to the file
	foreach my $postfix (@{$self->{libext}}) {
	    return "$dir/$filename$postfix" if -r "$dir/$filename$postfix";
	}
    }
    return undef;
}

#######################################################################
# Getopt functions

sub defvalue {
    my $self = shift;
    my $token = shift;
    my $val = $self->{defines}{$token};
    (defined $val) or carp "%Warning: ".$self->fileline().": No definition for $token,";
    return $val;
}
sub defvalue_nowarn {
    my $self = shift;
    my $token = shift;
    my $val = $self->{defines}{$token};
    return $val;
}
sub define {
    my $self = shift;
    if (@_) {
	my $token = shift;
	my $value = shift;
	print "Define $token = $value\n" if $Debug;
	my $oldval = $self->{defines}{$token};
	(!defined $oldval or ($oldval eq $value)) or warn "%Warning: ".$self->fileline().": Redefining `$token\n";
	$self->{defines}{$token} = $value;
    }
}
sub undef {
    my $self = shift;
    my $token = shift;
    my $oldval = $self->{defines}{$token};
    (defined $oldval) or carp "%Warning: ".$self->fileline().": No definition to undef for $token,";
    delete $self->{defines}{$token};
}

######################################################################
### Package return
1;
__END__

=pod

=head1 NAME

Verilog::Getopt - Get Verilog command line options

=head1 SYNOPSIS

  use Verilog::Getopt;

  my $opt = new Verilog::Getopt;
  $opt->parameter (qw( +incdir+standard_include_directory ));

  @ARGV = $opt->parameter (@ARGV);
  ...
  print "Path to foo.v is ", $opt->file_path('foo.v');

=head1 DESCRIPTION

The C<Verilog::Getopt> package provides standardized handling of options similar
to Verilog/VCS and cc/GCC.

=over 4

=item $opt = Verilog::Getopt->new ( I<opts> )

Create a new Getopt.  If gcc_style=>0 is passed as a parameter, parsing of
GCC-like parameters is disabled.  If vcs_style=>0 is passed as a parameter,
parsing of VCS-like parameters is disabled.

=item $self->file_path ( I<filename> )

Returns a new path to the filename, using the library directories and
search paths to resolve the file.

=item $self->parameter ( \@params )

Parses any recognized parameters in the referenced array, removing the
standard parameters and returning a array with all unparsed parameters.

The below list shows the VCS-like parameters that are supported, and the
functions that are called:

    +libext+I<ext>+I<ext>...	libext (I<ext>)
    +incdir+I<dir>		incdir (I<dir>)
    +define+I<var>+I<value>	define (I<val>,I<value>)
    +define+I<var>		define (I<val>,undef)
    -f I<file>		Parse parameters in file
    -v I<file>		library (I<file>)
    -y I<dir>		module_dir (I<dir>)
    all others		Put in returned list

The below list shows the GCC-like parameters that are supported, and the
functions that are called:

    -DI<var>=I<value>		define (I<val>,I<value>)
    -DI<var>		define (I<val>,undef)
    -II<dir>		incdir (I<dir>)
    -f I<file>		Parse parameters in file
    all others		Put in returned list

=back

=head1 ACCESSORS

=over 4

=item $self->define ( $token, $value )

This method is called when a define is recognized.  The default behavior
loads a hash that is used to fufill define references.  This fuction may
also be called outside parsing to predefine values.

=item $self->defvalue ( $token )

This method returns the value of a given define, or undef.

=item $self->incdir ()

Returns reference to list of include directories.  With argument, adds that
directory.

=item $self->libext ()

Returns reference to list of library extensions.  With argument, adds that
extension.

=item $self->library ()

Returns reference to list of libraries.  With argument, adds that library.

=item $self->module_dir ()

Returns reference to list of module directories.  With argument, adds that
directory.

=item $self->undef ( $token )

Deletes a hash element that is used to fufill define references.  This
fuction may also be called outside parsing to erase a predefined value.

=back

=head1 SEE ALSO

C<Verilog::Language>, 

=head1 DISTRIBUTION

The latest version is available from CPAN or
C<http://veripool.com/verilog-perl>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
