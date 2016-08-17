#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $usage = "$0 [--dumpindices] col0 col1 col2 ....\n";
if(! @ARGV)
{
    die $usage;
}

my %options;
GetOptions(\%options,
           "dumpindices!",
           "help") or die($usage);

if( defined $options{help} )
{
    print $usage;
    exit 0;
}

# useful for realtime plots
autoflush STDOUT;

my @cols_want = @ARGV;

# if no columns requested, just print everything
if(!@cols_want)
{
    while(<STDIN>)
    { print; }
}

# script to read intersense logs and to only select particular columns
my @indices = ();
while(<STDIN>)
{
    if(/^##/p)
    {
        print;
        next;
    }

    if( /^#/p )
    {
        chomp;

        # we got a legend line
        my @cols_all = split ' ', ${^POSTMATCH}; # split the field names (sans the #)
        my @cols_all_orig = @cols_all;

        # grab all the column indices
        foreach my $col (@cols_want)
        {
            # I want to find the requested column in the legend. First I look
            # for an exact string match, and if that doesn't work, I try to
            # match as a regex.

            my @indices_here = grep {$col eq $cols_all[$_]} 0..$#cols_all;
            if ( @indices_here > 1 )
            {
                die "Found more than one column that string-matched '$col' exactly";
            }
            if( @indices_here == 1 )
            {
                push @indices, @indices_here;
                next;
            }

            # No exact match found. Try a regex
            @indices_here = grep {$cols_all[$_] =~ qr/$col/} 0..$#cols_all;
            if( @indices_here >= 1 )
            {
                push @indices, @indices_here;
                next;
            }

            die "Couldn't find requested column '$col' in the legend line '$_'";
        }

        if ( $options{dumpindices} )
        {
            print "@indices\n";
            exit;
        }

        # print out the new legend
        if(@indices)
        { print "# @cols_all_orig[@indices]\n"; }
        else
        { print "# @cols_all_orig\n"; }

        next;
    }

    # we got a data line
    next if $options{dumpindices};

    # select the columns we want
    chomp;
    my @f = split;

    print "@f[@indices]\n";
}
