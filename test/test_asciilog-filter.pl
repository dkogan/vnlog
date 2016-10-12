#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use IPC::Run 'run';
use Text::Diff 'diff';
use Carp 'confess';
use FindBin '$Bin';


my $dat = <<'EOF';
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
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

check( <<'EOF', qw(--matches a>5 .), 'AWK' );
# a b c
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--matches $a>5 .), 'PERL' );
# a b c
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--matches a>5 --no-skipempty c), 'AWK' );
# c
-
12
EOF

check( <<'EOF', qw(--matches $a>5 --no-skipempty c), 'PERL' );
# c
-
12
EOF

check( <<'EOF', qw(--matches a>5), '--eval', 'print a+b', 'AWK' );
16
21
EOF

check( <<'EOF', qw(--matches $a>5), '--eval', 'my $v = $a + $b + 2; say $v', 'PERL' );
18
23
EOF


1;




sub check
{
    # I check stuff twice. Once with perl processing, and again with awk
    # processing

    my ($expected, @args) = @_;

    my @langs;
    if( $args[-1] =~ /PERL|AWK/ )
    {
        my $lang = pop @args;
        push @langs, ($lang =~ /PERL/ ? 1 : 0);
    }
    if( !@langs )
    {
        @langs = (0,1);
    }

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
        my $in = $dat;
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
