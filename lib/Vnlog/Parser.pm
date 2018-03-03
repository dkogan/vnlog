package Vnlog::Parser;

use strict;
use warnings;
use feature ':5.10';


our $VERSION = 1.00;
use base 'Exporter';
our @EXPORT_OK = qw();

sub new
{
    my $classname = shift;

    my $this = { 'keys'        => undef,
                 'values'      => undef,
                 'error'       => '',
                 'values_hash' => undef};
    bless($this, $classname);
    return $this;
}

sub parse
{
    my ($this, $line) = @_;

    # I reset the data first
    $this->{values}      = undef;
    $this->{values_hash} = undef;

    if( $line =~ /^\s*$/ )
    {
        # empty line
        # no data, no error
        return 1;
    }

    if( $line =~ /^\s*#[!#]/ )
    {
        # comment
        # no data, no error
        return 1;
    }

    if( $line =~ /^#\s*(.*?)\s*$/ )
    {
        if( $this->{keys} )
        {
            # already have legend, so this is just a comment
            # no data, no error
            return 1;
        }

        # got legend.
        # no data, no error
        $this->{keys} = [ split(' ', $1) ];
        return 1;
    }

    if( !$this->{'keys'} )
    {
        # Not comment, not empty line, but no legend yet. Barf
        $this->{error} = "Got dataline before legend";
        return undef;
    }

    $line =~ /^\s*(.*?)\s*$/; # get the non-newline part. Like chomp, but
                              # non-destructive
    $this->{values} = [ map {$_ eq '-' ? undef : $_} split(/ /, $1) ];
    if( scalar @{$this->{'keys'}} != scalar @{$this->{'values'}} )
    {
        # mismatched key/value counts
        $this->{error} = sprintf('Legend line "%s" has %d elements, but data line "%s" has %d elements. Counts must match!',
                                 "# " . join(' ', @{$this->{'keys'}}),
                                 scalar @{$this->{'keys'}},
                                 $line,
                                 scalar @{$this->{'values'}});
        return undef;
    }

    return 1;
}

sub error
{
    my ($this) = @_;
    return $this->{error};
}

sub getKeys
{
    my ($this) = @_;
    return $this->{keys};
}

sub getValues
{
    my ($this) = @_;
    return $this->{values}
}

sub getValuesHash
{
    my ($this) = @_;

    # internally:
    #   $this->{values_hash} == undef:  not yet computed
    #   $this->{values_hash} == {}:     computed, but no-data
    # returning: undef if computed, but no-data

    if( defined $this->{values_hash} )
    {
        return undef if 0 == scalar(%{$this->{values_hash}});
        return $this->{values_hash};
    }

    $this->{values_hash} = {};
    if($this->{keys} && $this->{values})
    {
        for my $i (0..$#{$this->{keys}})
        {
            $this->{values_hash}{$this->{keys}[$i]} = $this->{values}[$i];
        }
    }
    return $this->{values_hash};
}

1;

=head1 NAME

Vnlog::Parser - Simple library to parse vnlog data

=head1 SYNOPSIS

 use Vnlog::Parser;

 my $parser = Vnlog::Parser->new();
 while (<DATA>)
 {
     if( !$parser->parse($_) )
     {
         die "Error parsing vnlog line '$_': " . $parser->error();
     }

     my $d = $parser->getValuesHash();
     next unless %$d;

     say "$d->{time}: $d->{height}";
 }


=head1 DESCRIPTION

This is a simple perl script to parse vnlog input and make the incoming
key/values available. The example above is representative of normal use. API
functions are

=over

=item *

new()

Creates new Vnlog::Parser object. Takes no arguments.

=item *

parse(line)

Method to call for each input line. On error, a false value is returned.

=item *

error()

If an error occurred, returns a string that describes the error.

=item *

getKeys()

Returns a list-ref containing the current column labels or undef if this hasn't
been parsed yet.

=item *

getValues()

Returns a list-ref containing the values for the current line or undef if there
aren't any. This isn't an error necessarily because this line could have been a
comment. Empty fields are '-' in the vnlog and undef in the values returned
here.

=item *

getValuesHash()

Returns a hash-ref containing the key-value mapping for the current line or
undef if there's no data in this line. This isn't an error necessarily because
this line could have been a comment. Empty fields are '-' in the vnlog and undef
in the values returned here.

=item *

=back

=head1 REPOSITORY

L<https://github.com/dkogan/vnlog>

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 California Institute of Technology.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

=cut
