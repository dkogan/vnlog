#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.10';

use FindBin '$RealBin';
use lib $RealBin;

use IPC::Run 'run';
use TestHelpers qw(test_init check);

use Term::ANSIColor;
my $Nfailed = 0;


my $data1 = <<'EOF';
## gathered from sensor model xxx
# humidity temperature
90 25
80 20
81 19
82 18
70 15
EOF

my $data2 = <<'EOF';
# position
10
20
## we moved the sensor
150
160
170
EOF

my $data3 = <<'EOF';
# position
12
18
155
168
190
EOF

test_init('vnl-paste', \$Nfailed,
          '$data1'     => $data1,
          '$data2'     => $data2,
          '$data3'     => $data3);


check( <<'EOF', '$data1', '$data2' );
# humidity temperature position 
90 25	10
80 20	20
81 19	150
82 18	160
70 15	170
EOF

check( <<'EOF', '$data1', '$data2', '$data3' );
# humidity temperature position position 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
EOF

check( <<'EOF', qw(--vnl-suffix1 _a --vnl-prefix2 b_), '$data1', '$data2', '$data3' );
# humidity_a temperature_a b_position position 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
EOF

check( <<'EOF', '--vnl-suffix', ',_a,_b', '$data1', '$data2', '$data3' );
# humidity temperature position_a position_b 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
EOF

check( <<'EOF', '--vnl-suffix', '_a,_b', '$data1', '$data2', '$data3' );
# humidity_a temperature_a position_b position 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
EOF

check( <<'EOF', '--vnl-suffix', '_a,_b,', '$data1', '$data2', '$data3' );
# humidity_a temperature_a position_b position 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
EOF

check( <<'EOF', qw(--vnl-autosuffix), '$data1', '$data2', '$data3' );
# humidity_1 temperature_1 position_2 position_3 
90 25	10	12
80 20	20	18
81 19	150	155
82 18	160	168
70 15	170	190
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
