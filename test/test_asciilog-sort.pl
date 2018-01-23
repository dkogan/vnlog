#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';

use FindBin '$Bin';
use lib $Bin;

use TestHelpers qw(test_init check);

use Term::ANSIColor;
my $Nfailed = 0;



my $data1 = <<'EOF';
## xxx
# a b
1 1.69
## asdf
# 1234
20 0.09# xxx
3 0.49 # yyy
4 2.89 ## zzz
5 7.29## zzz
EOF

my $data2 = <<'EOF';
## zzz
# a b
## yyy
# 345
9 -2
8 -4
7 -6
6 -8
5 -10
EOF

my $data_not_ab = <<'EOF';
# a b c
1 2 3
4 5 6
EOF


test_init('asciilog-sort', \$Nfailed,
          '$data1'       => $data1,
          '$data2'       => $data2,
          '$data_not_ab' => $data_not_ab);





check( <<'EOF', qw(-k a), '$data1', '$data2' );
# a b
1 1.69
20 0.09
3 0.49
4 2.89
5 -10
5 7.29
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k a), '$data2', '$data1' );
# a b
1 1.69
20 0.09
3 0.49
4 2.89
5 -10
5 7.29
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k a), '-$data1', '$data2' );
# a b
1 1.69
20 0.09
3 0.49
4 2.89
5 -10
5 7.29
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k a), '$data1', '-$data2' );
# a b
1 1.69
20 0.09
3 0.49
4 2.89
5 -10
5 7.29
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k a), '-$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k a), '--$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-k b), '--$data2' );
# a b
5 -10
9 -2
8 -4
7 -6
6 -8
EOF

check( <<'EOF', qw(-n -k b), '--$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
EOF

check( <<'EOF', qw(-n -k a), '$data1', '$data2' );
# a b
1 1.69
3 0.49
4 2.89
5 -10
5 7.29
6 -8
7 -6
8 -4
9 -2
20 0.09
EOF

check( <<'EOF', qw(-n -k b), '$data1', '$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
20 0.09
3 0.49
1 1.69
4 2.89
5 7.29
EOF

check( <<'EOF', qw(-n --key b), '$data1', '$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
20 0.09
3 0.49
1 1.69
4 2.89
5 7.29
EOF

check( <<'EOF', qw(-n --key=b), '$data1', '$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
20 0.09
3 0.49
1 1.69
4 2.89
5 7.29
EOF

check( <<'EOF', qw(--key=b.2), '$data1', '$data2' );
# a b
20 0.09
5 7.29
3 0.49
1 1.69
4 2.89
5 -10
9 -2
8 -4
7 -6
6 -8
EOF

check( <<'EOF', qw(-n --key=b.2), '$data1', '$data2' );
# a b
20 0.09
5 7.29
3 0.49
1 1.69
4 2.89
9 -2
8 -4
7 -6
6 -8
5 -10
EOF

check( <<'EOF', qw(--key=b.2n), '$data1', '$data2' );
# a b
5 -10
6 -8
7 -6
8 -4
9 -2
20 0.09
3 0.49
1 1.69
4 2.89
5 7.29
EOF


# don't have this field
check( 'ERROR', qw(-k x), '$data1', '-$data2' );

# inconsistent fields
check( 'ERROR', qw(-k a), '$data1', '-$data2', '$data_not_ab' );

# unsupported options
check( 'ERROR', qw(-t f),   '$data1' );
check( 'ERROR', qw(-z),     '$data1' );
check( 'ERROR', qw(-o xxx), '$data1' );







if($Nfailed == 0 )
{
    say colored(["green"], "All tests passed!");
}
else
{
    say colored(["red"], "$Nfailed tests failed!");
}

1;