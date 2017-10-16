#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use IPC::Run 'run';
use Text::Diff 'diff';
use Carp 'confess';
use FindBin '$Bin';


my $data_default = <<'EOF';
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

my $data_latlon = <<'EOF';
# lat lon lat2 lon2
37.0597792247 -76.1703387355 37.0602752259 -76.1705049567
37.0598883299 -76.1703577868 37.0604772596 -76.1705748082
37.0599879749 -76.1703966222 37.0605833650 -76.1706010153
37.0600739448 -76.1704347187 37.0606881510 -76.1706390439
37.0601797672 -76.1704662408 37.0607908914 -76.1706712460
EOF

my $data_t = <<'EOF';
# t
100e6
101e6
102e6
103e6
EOF



check( <<'EOF', qw(.) );
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( <<'EOF', qw(a b) );
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw([ab]) );
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw(--has a .) );
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--has b .) );
# a b c
1 2 3
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--has c .) );
# a b c
1 2 3
4 - 6
10 11 12
EOF

check( <<'EOF', qw(--has), 'b,c', '.' );
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c .) );
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c .) );
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c a) );
# a
1
10
EOF

check( <<'EOF', qw(c us2s(a)) );
# c us2s(a)
3 1e-06
6 4e-06
- 7e-06
12 1e-05
EOF

check( <<'EOF', qw(c us2s(us2s(a))) );
# c us2s(us2s(a))
3 1e-12
6 4e-12
- 7e-12
12 1e-11
EOF

check( <<'EOF', qw(rel(a) b c));
# rel(a) b c
0 2 3
3 - 6
6 9 -
9 11 12
EOF

check( <<'EOF', qw(rel(a) b diff(a) c a));
# rel(a) b diff(a) c a
0 2 0 3 1
3 - 3 6 4
6 9 3 - 7
9 11 3 12 10
EOF

check( <<'EOF', [qw(rel(a) b c)], [qw(rel(a))]);
# rel(a)
0
3
6
9
EOF

check( <<'EOF', [qw(rel(a) b c)], [qw(rel(rel(a)))]);
# rel(rel(a))
0
3
6
9
EOF

check( <<'EOF', [qw(rel(a) b c)], [qw(diff(rel(a)))]);
# diff(rel(a))
0
3
3
3
EOF

check( <<'EOF', 'us2s(t)', {data => $data_t});
# us2s(t)
100
101
102
103
EOF

check( <<'EOF', 'rel(t)', {data => $data_t});
# rel(t)
0
1000000
2000000
3000000
EOF

check( <<'EOF', 'rel(us2s(t))', {data => $data_t});
# rel(us2s(t))
0
1
2
3
EOF

check( <<'EOF', 'us2s(rel(t))', {data => $data_t});
# us2s(rel(t))
0
1
2
3
EOF

check( <<'EOF', qw(--has b [ab]) );
# a b
1 2
7 9
10 11
EOF

check( <<'EOF', qw(--has b diff([ab])) );
# diff(a) diff(b)
0 0
6 7
3 2
EOF

check( <<'EOF', qw(--matches a>5 .), {language => 'AWK'} );
# a b c
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--matches $a>5 .), {language => 'PERL'} );
# a b c
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--matches a>5 --no-skipempty c), {language => 'AWK'} );
# c
-
12
EOF

check( <<'EOF', qw(--matches $a>5 --no-skipempty c), {language => 'PERL'} );
# c
-
12
EOF

check( <<'EOF', qw(--matches a>5), '--eval', 'print a+b', {language => 'AWK'} );
16
21
EOF

check( <<'EOF', qw(--matches $a>5), '--eval', 'my $v = $a + $b + 2; say $v', {language => 'PERL'} );
18
23
EOF


# awk and perl write out the data with different precisions, so I test them separately for now
check( <<'EOF', 'rel_n(lat)', 'rel_e(lon)', 'rel_n(lat2)', 'rel_e(lon2)', {language => 'AWK', data => $data_latlon} );
# rel_n(lat) rel_e(lon) rel_n(lat2) rel_e(lon2)
0 0 55.1528 -14.7495
12.1319 -1.6905 77.6179 -20.9478
23.212 -5.13654 89.4163 -23.2732
32.7714 -8.51701 101.068 -26.6477
44.5383 -11.3141 112.492 -29.5051
EOF


check( <<'EOF', 'rel_n(lat)', 'rel_e(lon)', 'rel_n(lat2)', 'rel_e(lon2)', {language => 'PERL', data => $data_latlon} );
# rel_n(lat) rel_e(lon) rel_n(lat2) rel_e(lon2)
0 0 55.1528170494324 -14.7495300237067
12.1319447101403 -1.69050470904804 77.6179395005555 -20.9477574245461
23.2119631755057 -5.13653865865383 89.4163216701965 -23.2732273896387
32.7713799003105 -8.51700679638622 101.06799325373 -26.6476704659731
44.5382939050826 -11.3140998289326 112.492204495462 -29.505102855998
EOF

1;




sub check
{
    # I check stuff twice. Once with perl processing, and again with awk
    # processing

    my ($expected, @args) = @_;

    my @langs;
    my $data;
    if(ref($args[-1]) && ref($args[-1]) eq 'HASH' )
    {
        my $opts = pop @args;
        if($opts->{language})
        {
            push @langs, ($opts->{language} =~ /PERL/ ? 1 : 0);
        }
        if($opts->{data})
        {
            $data = $opts->{data};
        }
    }
    if( !@langs )
    {
        @langs = (0,1);
    }
    $data //= $data_default;

    for my $doperl (@langs)
    {
        # if the arguments are a list of strings, these are simply the args to a
        # filter run. If the're a list of list-refs, then we run the filter
        # multiple times, with the arguments in each list-ref
        if ( !ref $args[0] )
        {
            my @args2 = @args;
            @args = (\@args2);
        }

        # @args is now a list-ref. Each element is a filter operation
        my $in = $data;
        my $out;
        for my $arg (@args)
        {
            my @args_here = @$arg;
            push @args_here, '--perl' if $doperl;

            $out = '';
            run( ["$Bin/../asciilog-filter", @args_here], \$in, \$out ) or confess "Couldn't run test";
            $in = $out;
        }

        my $diff = diff(\$expected, \$out);
        if ( length $diff )
        {
            confess "Test failed when doperl=$doperl; diff: '$diff'";
        }
    }
}
