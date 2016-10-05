#!/bin/sh

set -e

cd `dirname $0`

./test1 > test1.got

diff -q test1.want test1.got
diff -q test2.want test2.got
