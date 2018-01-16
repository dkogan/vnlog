package Asciilog::Util;

use strict;
use warnings;
use feature ':5.10';

our $VERSION = 1.00;
use base 'Exporter';
our @EXPORT_OK = qw(get_unbuffered_line prepare_inner_command);


# The bulk of these is for the coreutils wrappers such as sort, join, cut and so
# on


use Asciilog::Parser;
use Fcntl qw(F_GETFD F_SETFD F_DUPFD FD_CLOEXEC);
use Getopt::Long 'GetOptionsFromArray';
Getopt::Long::Configure('gnu_getopt');





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



sub open_file_as_pipe
{
    my ($filename) = @_;

    if ($filename eq '-')
    {
        return *STDIN;
    }

    my $fh;
    if ( ! -r $filename )
    {
        die "'$filename' is not readable";
    }

    # This invocation of 'grep' is important. I want to read the legend in this
    # perl program from a FILE, and then exec the underlying application, with
    # the inner application using the post-legend file-descriptor. Conceptually
    # this works, BUT the inner application expects to get a filename that it
    # calls open() on, NOT an already-open file-descriptor. I can get an
    # open-able filename from /dev/fd/N, but on Linux this is a plain symlink to
    # the actual file, so the file would be re-opened, and the legend visible
    # again. By using a filtering process (grep here), /dev/fd/N is a pipe, not
    # a file. And opening this pipe DOES start reading the file from the
    # post-legend location
    open $fh, '-|', "grep -v '^ *##' '$filename'";
    if ( !$fh )
    {
        die "Couldn't open file '$filename'";
    }

    # I'm explicitly passing these to an exec, so FD_CLOSEXEC must be off
    my $fd    = fileno $fh;
    my $flags = fcntl $fh, F_GETFD, 0;
    fcntl $fh, F_SETFD, ($flags & ~FD_CLOEXEC);

    return $fh;
}
sub pull_key
{
    my ($input) = @_;
    my $filename = $input->{filename};
    my $fh       = $input->{fh};

    my $keys;

    my $parser = Asciilog::Parser->new();
    while (defined ($_ = get_unbuffered_line($fh)))
    {
        if ( !$parser->parse($_) )
        {
            die "Reading '$filename': Error parsing asciilog line '$_': " . $parser->error();
        }

        $keys = $parser->getKeys();
        if (defined $keys)
        {
            return $keys;
        }
    }

    return die "Reading '$filename': no legend found!";
}
sub parse_options
{
    my ($ARGV, $specs) = @_;

    my %options;
    my @ARGV_copy = @$ARGV;
    my $result;

    eval
    {
        $result =
          GetOptionsFromArray( \@ARGV_copy,
                               \%options,
                               @$specs );
    };

    if ( $@  )
    {
        die "Error parsing options: '$@'";
    }
    if ( !$result  )
    {
        die "Error parsing options";
    }

    push @ARGV_copy, '-' unless @ARGV_copy;
    return (\@ARGV_copy, \%options);
}
sub legends_match
{
    my ($l1, $l2) = @_;

    return 0 if scalar(@$l1) != scalar(@$l2);
    for my $i (0..$#$l1)
    {
        return 0 if $l1->[$i] ne $l2->[$i];
    }
    return 1;
}
sub ensure_all_legends_equivalent
{
    my ($inputs) = @_;

    for my $i (1..$#$inputs)
    {
        if (!legends_match($inputs->[0 ]{keys},
                           $inputs->[$i]{keys})) {
            die("All input legends must match! Instead files '$inputs->[0 ]{filename}' and '$inputs->[$i]{filename}' have keys " .
                "'@{$inputs->[0 ]{keys}}' and '@{$inputs->[$i]{keys}}' respectively");
        }
    }
    return 1;

}
sub interpret_argv
{
    my ($ARGV, $specs) = @_;

    my ($filenames,$options) = parse_options($ARGV, $specs);
    my @inputs = map { {filename => $_} } @$filenames;
    for my $input (@inputs)
    {
        $input->{fh}   = open_file_as_pipe($input->{filename});
        $input->{keys} = pull_key($input);
    }

    return (\@inputs, $options);
}
sub substitute_field_keys
{
    my ($options, $keys) = @_;

    my %key_indices;
    for my $i(0..$#$keys)
    {
        $key_indices{$keys->[$i]} = $i + 1; # sort indexes from 1
    }

    # manpage of sort says that key definitions are given as
    # "F[.C][OPTS][,F[.C][OPTS]]"
    my @keyspecs = split(',', $options->{key});

    $options->{key} =
      join(',',
           map
           {
               /^([^\.]+)(\..+)?$/ or die "Couldn't parse '$_' as a sort KEYDEF";

               my $extra = $2 // '';
               if (!exists $key_indices{$1})
               {
                   die "Requested key '$1' not found in the input asciilogs. Have known keys '@$keys'";
               }

               $key_indices{$1} . $extra;
           }
           @keyspecs);
}
sub reconstruct_substituted_command
{
    # reconstruct the command, invoking the internal GNU tool, but replacing the
    # filenames with the opened-and-read-past-the-legend pipe. The field
    # specifiers have already been replaced with their column indices
    my ($inputs, $options, $specs) = @_;

    my @argv;

    # First I pull in the arguments
    for my $option(keys %$options)
    {
        my $re_specs_noarg    = qr/^ $option (?: \| [^=:] + )*   $/x;
        my $re_specs_yesarg   = qr/^ $option (?: \| [^=:] + )* =  /x;
        my $re_specs_maybearg = qr/^ $option (?: \| [^=:] + )* :  /x;

        my @specs_noarg    = grep { /$re_specs_noarg/    } @$specs;
        my @specs_yesarg   = grep { /$re_specs_yesarg/   } @$specs;
        my @specs_maybearg = grep { /$re_specs_maybearg/ } @$specs;

        if( scalar(@specs_noarg) + scalar(@specs_yesarg) + scalar(@specs_maybearg) != 1)
        {
            die "Couldn't uniquely figure out where '$option' came from. This is a bug. Specs: '@$specs'";
        }

        if( @specs_noarg )
        {
            push @argv, "--$option";
        }
        elsif( @specs_yesarg )
        {
            my $value = $options->{$option};
            push @argv, "--$option=$value";
        }
        else
        {
            # optional arg. Value of '' means "no arg"
            my $value = $options->{$option};
            if( $value eq '')
            {
                push @argv, "--$option";
            }
            else
            {
                push @argv, "--$option=$value";
            }
        }
    }

    # And then I pull in the files
    push @argv, map { my $fd = fileno $_->{fh}; "/dev/fd/$fd" } @$inputs;

    return \@argv;
}

sub prepare_inner_command
{
    my ($ARGV_orig, $specs) = @_;

    my @ARGV = @$ARGV_orig;

    my ($inputs, $options) = interpret_argv( \@ARGV, $specs );
    ensure_all_legends_equivalent($inputs);
    substitute_field_keys($options, $inputs->[0]{keys});
    return (reconstruct_substituted_command($inputs, $options, $specs),
           $inputs);
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

=back

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
