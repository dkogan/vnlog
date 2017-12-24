package Asciilog::Util;

use strict;
use warnings;
use feature ':5.10';

our $VERSION = 1.00;
use base 'Exporter';
our @EXPORT_OK = qw(get_unbuffered_line);


# Reads a line from STDIN one byte at a time. This means that as far as the OS
# is concerned we never read() past our line.
sub get_unbuffered_line
{
    my $fd = shift;

    my $line = '';

    while(1)
    {
        my $c = '';
        return undef unless 1 == sysread($fd, $c, 1);

        $line .= $c;
        return $line if $c eq "\n";
    }
}

1;

=head1 NAME

Asciilog::Util - Various utility functions useful in asciilog parsing

=head1 SYNOPSIS

 use Asciilog::Util 'get_unbuffered_line';

 while(defined ($_ = get_unbuffered_line(*STDIN)))
 {
   print "got line '$_'.";
 }


=head1 DESCRIPTION

This module provides some useful utilities

=over

=item get_unbuffered_line

Reads a line of input from the given pipe, and returns it. Common usage is like

 while(defined ($_ = get_unbuffered_line(*STDIN)))
 { ... }

which is identical to the basic form

 while(<STDIN>)
 { ... }

except C<get_unbuffered_line> reads I<only> the bytes in the line from the OS.
The rest is guaranteed to be available for future reading. This is useful for
tools that bootstrap asciilog processing by reading up-to the legend, and then
C<exec> some other tool to process the rest.

=head1 REPOSITORY

L<https://github.com/dkogan/asciilog>

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dima Kogan <dima@secretsauce.net>

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

=cut
