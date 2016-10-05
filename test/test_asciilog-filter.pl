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




check( $dat, <<'EOF', qw(.) );
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( $dat, <<'EOF', qw(a b) );
# a b
1 2
4 -
7 9
10 11
EOF

check( $dat, <<'EOF', qw([ab]) );
# a b
1 2
4 -
7 9
10 11
EOF

check( $dat, <<'EOF', qw(--has a .) );
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( $dat, <<'EOF', qw(--has b .) );
# a b c
1 2 3
7 9 -
10 11 12
EOF

check( $dat, <<'EOF', qw(--has c .) );
# a b c
1 2 3
4 - 6
10 11 12
EOF

check( $dat, <<'EOF', qw(--has), 'b,c', '.' );
# a b c
1 2 3
10 11 12
EOF

check( $dat, <<'EOF', qw(--has b --has c .) );
# a b c
1 2 3
10 11 12
EOF

check( $dat, <<'EOF', qw(--has b --has c .) );
# a b c
1 2 3
10 11 12
EOF

check( $dat, <<'EOF', qw(--has b --has c a) );
# a
1
10
EOF

check( $dat, <<'EOF', qw(rel(a) b c));
# rel(a) b c
0 2 3
3 - 6
6 9 -
9 11 12
EOF

check( $dat, <<'EOF', qw(rel(a) b diff(a) c a));
# rel(a) b diff(a) c a
0 2 0 3 1
3 - 3 6 4
6 9 3 - 7
9 11 3 12 10
EOF

check( $dat, <<'EOF', [qw(rel(a) b c)], [qw(rel(a))]);
# rel(a)
0
3
6
9
EOF

check( $dat, <<'EOF', [qw(rel(a) b c)], [qw(rel(rel(a)))]);
# rel(rel(a))
0
3
6
9
EOF

check( $dat, <<'EOF', [qw(rel(a) b c)], [qw(diff(rel(a)))]);
# diff(rel(a))
0
3
3
3
EOF

check( $dat, <<'EOF', qw(--has b [ab]) );
# a b
1 2
7 9
10 11
EOF

check( $dat, <<'EOF', qw(--has b diff([ab])) );
# diff(a) diff(b)
0 0
6 7
3 2
EOF



$dat = <<'EOF';
# a b c
1    -   3
4    -   6
7    8   9
10  11  12
13  -   14
15  16  17
18  -   -
-   -   181
182 -   183
-   19  -
20  21  22
23  -   24
-   -   26
27  -   28
29  30  -
EOF

check( $dat, <<'EOF', qw(--fill b ));
# a b c
1 8 3
4 8 6
7 8 9
10 11 12
13 16 14
15 16 17
18 19 -
- 19 181
182 19 183
- 19 -
20 21 22
23 30 24
29 30 26
27 30 28
29 30 -
EOF

check( $dat, <<'EOF', qw(--fill b --has a ));
# a b c
1 8 3
4 8 6
7 8 9
10 11 12
13 16 14
15 16 17
18 19 -
182 19 183
20 21 22
23 30 24
27 30 28
29 30 -
EOF

# - anchor lines ALWAYS processed to fill in the prev lines
# - anchor lines MAY be filtered-out with --has after filling
# - an input line MUST satisfy the --has to be output

1;




sub check
{
    my ($input, $expected, @args) = @_;

    if( !ref $args[0] )
    {
        my @args2 = @args;
        @args = (\@args2);
    }

    # @args is now a list-ref. Each element is a filter operation

    my $in = $input;
    my $out;
    for my $arg(@args)
    {
        $out = '';
        run( ["$Bin/../asciilog-filter", @$arg], \$in, \$out ) or confess "Couldn't run test";
        $in = $out;
    }

    my $diff = diff(\$expected, \$out);
    if ( length $diff )
    {
        confess "Test failed; diff: '$diff'";
    }
}
