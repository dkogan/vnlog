package Asciilog::Parser;

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

    if( $line =~ /^##/ )
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
        $this->{keys} = [ split(/ /, $1) ];
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
    $this->{values} = [ map {$_ eq '-' ? '' : $_} split(/ /, $1) ];
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

sub lookup
{
    my ($this, $k) = @_;

    return undef unless $this->{keys};

    if( !$this->{values_hash} )
    {
        $this->{values_hash} = {};

        for my $i(0..$#{$this->{keys}})
        {
            $this->{values_hash}{$this->{keys}[$i]} = $this->{values}[$i];
        }
    }

    return $this->{values_hash}{$k};
}

sub pairs
{
    my ($this) = @_;
    return () unless $this->{values};

    return map { [$this->{keys}[$_], $this->{values}[$_]] } 0..$#{$this->{keys}};
}

1;

=head1 NAME

Asciilog::Parser - Simple library to parse asciilog data

=head1 SYNOPSIS

 use Asciilog::Parser;

 my $parser = Asciilog::Parser->new();
 while (<>)
 {
     if( !$parser->parse($_) )
     {
         die "Error parsing asciilog line '$_': " . $parser->error();
     }

     next unless $parser->getValues();

     printf( "At time %f got height %f\n", $parser->lookup('time'), $parser->lookup('height') );

     for my $kv ($parser->pairs())
     {
         printf( "got %s = %s\n", $kv->[0], $kv->[1] );
     }
 }

=head1 DESCRIPTION

This is a simple perl script to parse asciilog input and make the incoming
key/values available. The example above is representative of normal use. API
functions are

=over

=item new

Creates new Asciilog::Parser object. Takes no arguments.

=item parse

Method to call for each input line. On error, a false value is returned.

=item error

If an error occurred, returns a string that describes the error.

=item getKeys

Returns a list-ref containing the current column labels or undef if this hasn't
been parsed yet.

=item getValues

Returns a list-ref containing the values for the current line or undef if there
aren't any. This isn't an error necessarily because this line could have been a
comment.

=item lookup

Given a string for a specific key, looks up the corresponding value in this
line.

=item pairs

Returns a list of [$key,$value] tuples.

=back

=head1 REPOSITORY

L<https://github.com/dkogan/asciilog>

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 California Institute of Technology

Proprietary software. Do not distribute without permission of copyright holder

See http://dev.perl.org/licenses/ for more information.
