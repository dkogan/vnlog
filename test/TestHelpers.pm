package TestHelpers;

use strict;
use warnings;
use feature ':5.10';
use Carp qw(cluck confess);
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use IPC::Run 'run';
use Text::Diff 'diff';
use FindBin '$Bin';


our $VERSION = 1.00;
use base 'Exporter';
our @EXPORT_OK = qw(check test_init);

my $tool;
my $Nfailed_ref;
my %data;

sub test_init
{
    $tool        = shift;
    $Nfailed_ref = shift;

    %data = @_;
}

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
            print $fhwrite $data{$args[$iarg]};
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
            $in = $data{substr($args[$iarg], 1)};
            $args[$iarg] = '-';
        }
        elsif($args[$iarg] =~ /^--\$/)
        {
            # I'm passing it data via stdin
            if(defined $in)
            {
                die "A test passed in more than one chunk of data on stdin";
            }
            $in = $data{substr($args[$iarg], 2)};
            $args[$iarg] = undef; # mark the arg for removal
        }
    }

    # remove marked args
    @args = grep {defined $_} @args;

    my $out = '';
    my $err = '';
    $in //= '';
    my @cmd = ("perl", "$Bin/../$tool", @args);
    my $result =
      run( \@cmd, \$in, \$out, \$err );

    if($expected ne 'ERROR')
    {
        if( !$result )
        {
            cluck
              "Test failed. Expected success, but got failure.\n" .
              "Ran '@cmd'.\n" .
              "STDERR: '$err'";
            $$Nfailed_ref++;
        }
        else
        {
            my $diff = diff(\$expected, \$out);
            if ( length $diff )
            {
                cluck
                  "Test failed: diff mismatch.\n" .
                  "Ran '@cmd'.\n" .
                  "Diff: '$diff'";
                $$Nfailed_ref++;
            }
        }
    }
    else
    {
        if( $result )
        {
            cluck
              "Test failed. Expected failure, but got success.\n".
              "Ran '@cmd'.\n" .
              "STDERR: '$err'\n" .
              "STDOUT: '$err'";
            $$Nfailed_ref++;
        }
    }

    for my $pipe(@pipes)
    {
        close $pipe;
    }
}

1;
