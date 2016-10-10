#!/usr/bin/perl

package Asciilog;

# no 'use strict' here on purpose:
#
# 1. I use indirect variable accessing below: '$$a = $b' business
# 2. I want these variables to be acessible to the callback without any extra
#    context

use List::MoreUtils 'pairwise';

use base 'Exporter';
our @EXPORT = qw(loop);


sub loop
{
    # our callback is the sole argument
    my ($cb) = @_;


    my @labels;
    while (<>)
    {
        if (/^#\s/)
        {
            # The caller is in the 'main' package. I want them to be able to
            # access these variables directly by saying '$var', so I put these
            # variables directly into that package. This requires 'no strict'
            @labels = map { "main::$_" } substr($_, 1) =~ /\s+(\S+)/g;
            last;
        }
    }

    while (<>)
    {
        next if /^#/;

        my @fields = /(\S+)/g;
        pairwise { $$a = $b eq '-' ? undef : $b; } @labels, @fields;

        $cb->();
    }
}

1;

__END__


=head1 NAME

Asciilog - Simple utilities for a simple data format

=head1 SYNOPSIS

    $ cat /tmp/dat.asciilog

    # w x y z
    -10 40 asdf -
    5 6 - -
    6 7 - -
    7 8 - -
    -20 50 - 0.300000


    $ < /tmp/dat.asciilog | perl -MAsciilog -E 'loop( sub{ say $y // $w+$x; })'

    asdf
    11
    13
    15
    30

=head1 DESCRIPTION

This library provides a function that parses asciilog data, and for each record
calls an arbitrary callback, with the values in that record bound to variables.
This is very similar to what C<awk> does, but instead of referring to each field
by number, we can refer to it by name.

=head1 REPOSITORY

https://github.jpl.nasa.gov/maritime-robotics/asciilog/

=head1 AUTHOR

Dima Kogan C<< <Dmitriy.Kogan@jpl.nasa.gov> >>

=head1 LICENSE AND COPYRIGHT

Proprietary. Copyright 2016 California Institute of Technology
