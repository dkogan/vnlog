#!/bin/bash

set -e

cd `dirname $0`

#### writer
./test1 > test1.got

diff -q test1.want test1.got
diff -q test2.want test2.got


#### reader

read -r -d '' ref <<'EOF' || true
======
time = 0
id = abc
x = 1
y = 5
z = 3
======
time = 1
id = def
x = 11
y = 25
z = 53
EOF

echo '
# time id x y z
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - 2>/dev/null > test-parser.got || { echo "LINE $LINENO: FAILED!"; exit 1; }

diff -q test-parser.got <(echo "$ref") >&/dev/null || { echo "LINE $LINENO: mismatched output!"; exit 1; }


echo '
## adsf
   #! zxcv
 # # #

   #   time id x y z
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - 2>/dev/null > test-parser.got || { echo "LINE $LINENO: FAILED!"; exit 1; }

diff -q test-parser.got <(echo "$ref") >&/dev/null || { echo "LINE $LINENO: mismatched output!"; exit 1; }


echo '
# 

# time id x y z # asdf err
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - 2>/dev/null > test-parser.got || { echo "LINE $LINENO: FAILED!"; exit 1; }

diff -q test-parser.got <(echo "$ref") >&/dev/null || { echo "LINE $LINENO: mismatched output!"; exit 1; }



## And the expected failures
echo '
# time id x y
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - >&/dev/null && { echo "LINE $LINENO: SHOULD HAVE FAILED!"; exit 1; } || true

echo '
# time id x y z z
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - >&/dev/null && { echo "LINE $LINENO: SHOULD HAVE FAILED!"; exit 1; } || true

echo '
## time id x y z
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - >&/dev/null && { echo "LINE $LINENO: SHOULD HAVE FAILED!"; exit 1; } || true

echo '
time id x y z
0 abc 1 5 3
1 def 11 25 53
' | ./test-parser - >&/dev/null && { echo "LINE $LINENO: SHOULD HAVE FAILED!"; exit 1; } || true
