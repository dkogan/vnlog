#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.10';

use FindBin '$RealBin';
use lib "$RealBin/../lib";


use Vnlog::Parser;

my $parser = Vnlog::Parser->new();
my $resultstring = '';
while (<DATA>)
{
    if( !$parser->parse($_) )
    {
        die "Error parsing vnlog line '$_': " . $parser->error();
    }

    my $d = $parser->getValuesHash();
    next unless %$d;

    use Data::Dumper;
    $resultstring .= Dumper [$d->{time},$d->{height}];
}

my $ref = <<'EOF';
$VAR1 = [
          '1',
          '2'
        ];
$VAR1 = [
          '3',
          '4'
        ];
$VAR1 = [
          undef,
          '5'
        ];
$VAR1 = [
          '6',
          undef
        ];
$VAR1 = [
          undef,
          undef
        ];
$VAR1 = [
          '7',
          '8'
        ];
EOF

if( $resultstring eq $ref)
{
    say "Test passed";
    exit 0;
}

say "Expected '$ref' but got '$resultstring'";
say "Test failed!";
exit 1;


__DATA__
#! zxcv
 # 
#time height
  ## qewr
	# asdf
1 2
3 4
# - 10
- 5
6 -
- -
7 8
