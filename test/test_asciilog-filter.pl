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


1;




sub check
{
    my ($expected, @args) = @_;

    if( !ref $args[0] )
    {
        my @args2 = @args;
        @args = (\@args2);
    }

    # @args is now a list-ref. Each element is a filter operation

    my $in = $dat;
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
