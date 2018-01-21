#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use IPC::Run 'run';
use Text::Diff 'diff';
use Carp qw(cluck confess);
use FindBin '$Bin';

use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);

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




sub check
{
    # arguments:
    #
    # - expected output. 'ERROR' means the invocation should fail
    # - arguments to the tool.
    #   - if an arg is '$xxx', replace that arg with a pipe containing the data
    #     in $xxx
    #   - if an arg is '-$xxx', replace that arg with '-', pipe $xxx into STDIN
    #   - if an arg is '--$xxx', remove the arg entirely, pipe $xxx into STDIN
    my ($expected, @args) = @_;

    my @pipes;

    my $in = undef;
    for my $iarg(0..$#args)
    {
        if($args[$iarg] =~ /^\$/)
        {
            # I'm passing it data. Make a pipe, stuff the data into one end, and
            # give the other end to the child
            my ($fhread, $fhwrite);
            pipe $fhread, $fhwrite;
            print $fhwrite eval $args[$iarg];
            close $fhwrite;
            $args[$iarg] = "/dev/fd/" . fileno($fhread);

            # The read handle must be inherited by the child, so I make sure it
            # survives the exec
            my $flags = fcntl $fhread, F_GETFD, 0;
            fcntl $fhread, F_SETFD, ($flags & ~FD_CLOEXEC);

            push @pipes, $fhread;
        }
        elsif($args[$iarg] =~ /^-\$/)
        {
            # I'm passing it data via stdin
            if(defined $in)
            {
                die "A test passed in more than one chunk of data on stdin";
            }
            $in = eval substr($args[$iarg], 1);
            $args[$iarg] = '-';
        }
        elsif($args[$iarg] =~ /^--\$/)
        {
            # I'm passing it data via stdin
            if(defined $in)
            {
                die "A test passed in more than one chunk of data on stdin";
            }
            $in = eval substr($args[$iarg], 2);
            $args[$iarg] = undef; # mark the arg for removal
        }
    }

    # remove marked args
    @args = grep {defined $_} @args;

    my $out = '';
    my $err = '';
    $in //= '';
    my $result =
      run( ["perl",
            "$Bin/../asciilog-sort", @args], \$in, \$out, \$err );

    if($expected ne 'ERROR')
    {
        if( !$result )
        {
            cluck "Test failed. Expected success, but got failure";
            $Nfailed++;
        }
        else
        {
            my $diff = diff(\$expected, \$out);
            if ( length $diff )
            {
                cluck "Test failed. diff: '$diff'";
                $Nfailed++;
            }
        }
    }
    else
    {
        if( $result )
        {
            cluck "Test failed. Expected failure, but got success";
            $Nfailed++;
        }
    }

    for my $pipe(@pipes)
    {
        close $pipe;
    }
}
