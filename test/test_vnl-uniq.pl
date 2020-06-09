#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.10';

use FindBin '$Bin';
use lib $Bin;

use IPC::Run 'run';
use TestHelpers qw(test_init check);

use Term::ANSIColor;
my $Nfailed = 0;



# I try to detect the uniq flavor. Not doing FEATURE detection here, because I
# want to test the feature
my $in  = '';
my $out = '';
my $err = '';
my $have_fancy_uniq;
if(run(['uniq', '--version'], \$in, \$out, \$err))
{
    # success
    if($out =~ /GNU/)
    {
        $have_fancy_uniq = 1;
        say "Detected GNU uniq. Running a full test of vnl-uniq";
    }
    else
    {
        die "I don't know which 'uniq' this is. 'uniq --version' succeeed, but didn't say it was 'GNU' uniq";
    }
}
else
{
    $have_fancy_uniq = 0;
    say "Detected non-GNU uniq ('uniq --version' failed): Running a limited test of vnl-uniq";
}

my $data1 = <<'EOF';
#!/bin/xxx
# x y
1 1
2 2
# asdf
2 2
3 3
10 1
11 1
12 1
20 2
21 2
# asdf
22 2
30 3
31 3
32 3
33 3
40 4
EOF


test_init('vnl-uniq', \$Nfailed,
          '$data1' => $data1);




# Basic run. I ignore the duplicate line "2 2"
check( <<'EOF', qw(), '$data1' );
# x y
1 1
2 2
3 3
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
40 4
EOF

# Same thing, but make sure I can read STDIN with '-' as an arg and that I can
# read STDIN with no arg at all
check( <<'EOF', qw(), '-$data1' );
# x y
1 1
2 2
3 3
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
40 4
EOF
check( <<'EOF', qw(), '--$data1' );
# x y
1 1
2 2
3 3
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
40 4
EOF

check( <<'EOF', qw(-u), '--$data1' );
# x y
1 1
3 3
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
40 4
EOF

# I don't support this option
check( 'ERROR', qw(-z), '$data1' );

# only print the one duplicate line
check( <<'EOF', qw(-d), '$data1' );
# x y
2 2
EOF

if($have_fancy_uniq)
{
    # print the duplicate lines, but don't suppress their duplicate-ness
    check( <<'EOF', qw(-D), '$data1' );
# x y
2 2
2 2
EOF
}

# print duplicate lines, but don't look at the first column for the duplicate
# detection. Here I print just the first one of each group
check( <<'EOF', qw(-d -f1), '$data1' );
# x y
2 2
10 1
20 2
30 3
EOF
check( <<'EOF', qw(-d -f 1), '$data1' );
# x y
2 2
10 1
20 2
30 3
EOF
check( <<'EOF', qw(-d -f-1), '$data1' );
# x y
2 2
10 1
20 2
30 3
EOF
check( <<'EOF', qw(-d -f -1), '$data1' );
# x y
2 2
10 1
20 2
30 3
EOF

if($have_fancy_uniq)
{
    # print duplicate lines, but don't look at the first column for the duplicate
    # detection. Here I print ALL the duplicates; since I skipped the first column,
    # they're not really duplicates
    check( <<'EOF', qw(-D -f1), '$data1' );
# x y
2 2
2 2
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
EOF
    check( <<'EOF', qw(--all-repeated -f1), '$data1' );
# x y
2 2
2 2
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
EOF

    # same thing, but using different flavors of -D, and making sure my option
    # parser works right
    check( <<'EOF', qw(--all-repeated=none -f1), '$data1' );
# x y
2 2
2 2
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
EOF
    check( <<'EOF', qw(--all-repeated=prepend -f1), '$data1' );
# x y

2 2
2 2

10 1
11 1
12 1

20 2
21 2
22 2

30 3
31 3
32 3
33 3
EOF
    check( <<'EOF', qw(--all-repeated=separate -f1), '$data1' );
# x y
2 2
2 2

10 1
11 1
12 1

20 2
21 2
22 2

30 3
31 3
32 3
33 3
EOF
    check( 'ERROR', qw(--all-repeated separate -f1), '$data1' );

    # And now --group
    check( <<'EOF', qw(--group), '$data1' );
# x y
1 1

2 2
2 2

3 3

10 1

11 1

12 1

20 2

21 2

22 2

30 3

31 3

32 3

33 3

40 4
EOF
    check( <<'EOF', qw(--group -f1), '$data1' );
# x y
1 1

2 2
2 2

3 3

10 1
11 1
12 1

20 2
21 2
22 2

30 3
31 3
32 3
33 3

40 4
EOF
    check( <<'EOF', qw(--group=both -f1), '$data1' );
# x y

1 1

2 2
2 2

3 3

10 1
11 1
12 1

20 2
21 2
22 2

30 3
31 3
32 3
33 3

40 4

EOF
    check( 'ERROR', qw(--group both), '$data1' );
    check( 'ERROR', qw(--group -c), '$data1' );

    check( <<'EOF', qw(-D -s1), '$data1' );
# x y
2 2
2 2
EOF
    check( <<'EOF', qw(-D -s2), '$data1' );
# x y
2 2
2 2
10 1
11 1
12 1
20 2
21 2
22 2
30 3
31 3
32 3
33 3
EOF
}

check( <<'EOF', qw(-c), '$data1' );
# count x y
      1 1 1
      2 2 2
      1 3 3
      1 10 1
      1 11 1
      1 12 1
      1 20 2
      1 21 2
      1 22 2
      1 30 3
      1 31 3
      1 32 3
      1 33 3
      1 40 4
EOF
check( <<'EOF', qw(-c -f1), '$data1' );
# count x y
      1 1 1
      2 2 2
      1 3 3
      3 10 1
      3 20 2
      4 30 3
      1 40 4
EOF
check( <<'EOF', qw(--vnl-count xxx -f1), '$data1' );
# xxx x y
      1 1 1
      2 2 2
      1 3 3
      3 10 1
      3 20 2
      4 30 3
      1 40 4
EOF




if($Nfailed == 0 )
{
    say colored(["green"], "All tests passed!");
    exit 0;
}
else
{
    say colored(["red"], "$Nfailed tests failed!");
    exit 1;
}
