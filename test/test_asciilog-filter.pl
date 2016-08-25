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




sub check
{
    my ($expected, @args) = @_;

    my $in  = $dat;
    my $got = '';
    run( ["$Bin/../asciilog-filter", @args], \$in, \$got ) or confess "Couldn't run test";

    my $diff = diff(\$expected, \$got);
    if ( length $diff )
    {
        confess "Test failed; diff: '$diff'";
    }
}
