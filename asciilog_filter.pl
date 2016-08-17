#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use feature qw(say state);


my $usage = "$0 [--dumpindices] col0 col1 col2 f(col0) g(col1)....\n";
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


my @transforms;

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
            # First off, I look for any requested functions. These all look like
            # "f(x)" and may be nested. f(g(h(x))) is allowed.

            my @funcs;
            while($col =~ /^           # start
                           ( [^\(]+ )  # Function name. Non-( characters
                           \( (.+) \)  # Function arg
                           $           # End
                          /x)
            {
                unshift @funcs, $1;
                $col = $2;
            }

            # OK. Done looking for transformations. Let's match the columns

            my @indices_here;
            my $accept = sub
            {
                if( @funcs )
                {
                    # This loop is important. It is possible to push it to later
                    # by doing this instead:
                    #
                    #   push @transforms, [\@indices_here, parse_transform_funcs(@funcs) ];
                    #
                    # but then all of @indices_here will get a single
                    # transformation subroutine object, and all of its internal
                    # state will be shared, which is NOT what you want. For
                    # instance if we're doing rel(.*time) or something, then the
                    # initial timestamp would be shared. This is wrong.
                    #
                    # The indices here index the OUTPUT columns list
                    foreach my $idx (0..$#indices_here)
                    {
                        push @transforms, [$idx + @indices, parse_transform_funcs(@funcs) ];
                    }
                }

                push @indices, @indices_here;
            };



            # I want to find the requested column in the legend. First I look
            # for an exact string match, and if that doesn't work, I try to
            # match as a regex.

            @indices_here = grep {$col eq $cols_all[$_]} 0..$#cols_all;
            if ( @indices_here > 1 )
            {
                die "Found more than one column that string-matched '$col' exactly";
            }
            if( @indices_here == 1 )
            {
                $accept->();
                next;
            }

            # No exact match found. Try a regex
            @indices_here = grep {$cols_all[$_] =~ qr/$col/} 0..$#cols_all;
            if( @indices_here >= 1 )
            {
                $accept->();
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
    @f = @f[@indices];


    for my $transform (@transforms)
    {
        # The indices here index the OUTPUT columns list
        my ($idx, @funcs) = @$transform;

        foreach my $func(@funcs)
        {
            $f[$idx] = $func->($f[$idx]);
        }
    }

    print "@f\n";
}






sub parse_transform_funcs
{
    sub parse_transform_func
    {
        my $f = shift;

        if( $f eq 'us2s' )
        {
            return sub { return $_[0] * 1e-6; };
        }
        elsif( $f eq 'deg2rad' )
        {
            return sub { return $_[0] * 3.141592653589793/180.0; };
        }
        elsif( $f eq 'rad2deg' )
        {
            return sub { return $_[0] * 180.0/3.141592653589793; };
        }
        elsif( $f eq 'rel' )
        {
            # relative to the starting value. The 'state' variable should be a
            # different instance for each sub instance
            return sub
            {
                state $x0;
                $x0 //= $_[0];
                return $_[0] - $x0;
            };
        }
        elsif( $f eq 'diff' )
        {
            # relative to the previous value. The 'state' variable should be a
            # different instance for each sub instance
            return sub
            {
                state $xprev;
                my $ret = 0;
                if(defined $xprev)
                {
                    $ret = $_[0] - $xprev;
                }
                $xprev = $_[0];
                return $ret;
            };
        }
        else
        {
            die "Unknown transform function '$f'";
        }
    }


    my @funcs = @_;
    return map { parse_transform_func($_) } @funcs;
}
