#!/usr/bin/python

import os
import sys

sys.path[:0] = (os.path.abspath(os.path.dirname(sys.argv[0])) + "/../lib",)

import vnlog
import cStringIO

f = cStringIO.StringIO('''#! zxcv
# time height
## qewr
1 2
3 4
# - 10
- 5
6 -
- -
7 8
''')

parser = vnlog.vnlog()
resultstring = ''
for l in f:
    parser.parse(l)
    d = parser.values_dict()
    if not d:
        continue

    resultstring += '{} {}\n'.format(d['time'],d['height'])



ref = r'''1 2
3 4
None 5
6 None
None None
7 8
'''

if resultstring == ref:
    print "Test passed";
    sys.exit(0);

print "Expected '{}' but got '{}'".format(ref, resultstring)
print "Test failed!"
sys.exit(1)
