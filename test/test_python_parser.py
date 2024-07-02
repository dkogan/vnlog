#!/usr/bin/env python3

r'''Tests the python parser

This is intended to work with both python2 and python3.

'''

from __future__ import print_function

import os
import sys
import numpy as np

sys.path[:0] = (os.path.abspath(os.path.dirname(sys.argv[0])) + "/../lib",)

import vnlog

try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

inputstring = '''#! zxcv
 
 # 
#
	#
 ## fdd
 #time height
## qewr
1 2
 ## ff
3 4

# - 10
- 5 # abc
6 -
- -
7 8
'''

ref = r'''1 2
3 4
None 5
6 None
None None
7 8
'''



# Parsing manually
f = StringIO(inputstring)
parser = vnlog.vnlog()
resultstring = ''
for l in f:
    parser.parse(l)
    d = parser.values_dict()
    if not d:
        continue
    resultstring += '{} {}\n'.format(d['time'],d['height'])
if resultstring != ref:
    print("Expected '{}' but got '{}'".format(ref, resultstring))
    print("Test failed!")
    sys.exit(1)



# Iterating
f = StringIO(inputstring)
resultstring = ''
for d in vnlog.vnlog(f):
    resultstring += '{} {}\n'.format(d['time'],d['height'])
if resultstring != ref:
    print("Expected '{}' but got '{}'".format(ref, resultstring))
    print("Test failed!")
    sys.exit(1)


# Slurping
inputstring_noundef = r'''#! zxcv
# time height
## qewr
1 2
3 4 #fff
# - 10
7 8
'''
ref_noundef = np.array(((1,2),(3,4),(7,8)))
f = StringIO(inputstring_noundef)
arr,list_keys,dict_key_index = vnlog.slurp(f)
if np.linalg.norm((ref_noundef - arr).ravel()) > 1e-8:
    raise Exception("Array mismatch: expected '{}' but got '{}". \
                    format(ref_noundef, arr))
if len(list_keys) != 2 or list_keys[0] != 'time' or list_keys[1] != 'height':
    raise Exception("Key mismatch: expected '{}' but got '{}". \
                    format(('time','height'), list_keys))
if len(dict_key_index) != 2 or dict_key_index['time'] != 0 or dict_key_index['height'] != 1:
    raise Exception("Key-dict mismatch: expected '{}' but got '{}". \
                   format({'time': 0, 'height': 1}, dict_key_index))

# Slurping with simple dtypes
f = StringIO(inputstring_noundef)
arr = vnlog.slurp(f, dtype=int)[0]
if arr.dtype != int: raise Exception("Unexpected dtype")
if np.linalg.norm((ref_noundef - arr).ravel()) > 1e-8:
    raise Exception("Array mismatch")

f = StringIO(inputstring_noundef)
arr = vnlog.slurp(f, dtype=float)[0]
if arr.dtype != float: raise Exception("Unexpected dtype")
if np.linalg.norm((ref_noundef - arr).ravel()) > 1e-8:
    raise Exception("Array mismatch")

f = StringIO(inputstring_noundef)
arr = vnlog.slurp(f, dtype=np.dtype(float))[0]
if arr.dtype != float: raise Exception("Unexpected dtype")
if np.linalg.norm((ref_noundef - arr).ravel()) > 1e-8:
    raise Exception("Array mismatch")



# Slurping a single row should still produce a 2d result
inputstring = '''
## asdf
# x name y name2 z
1 2 3
'''
f = StringIO(inputstring)
arr = vnlog.slurp(f)[0]
if arr.shape != (1,3): raise Exception("Unexpected shape")


# Slurping with structured dtypes
inputstring = '''
## asdf
# x name y name2 z
1 a 2 zz2 3
4 fbb 5 qq2 6
'''
ref = np.array(((1,2,3),
                (4,5,6),),)
dtype = np.dtype([ ('name',  'U16'),
                   ('x y z', int, (3,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
arr = vnlog.slurp(f, dtype=dtype)
if arr.shape != (2,):           raise Exception("Unexpected structured array outer shape")
if arr['name' ].shape != (2,):  raise Exception("Unexpected structured array inner shape")
if arr['name2'].shape != (2,):  raise Exception("Unexpected structured array inner shape")
if arr['x y z'].shape != (2,3): raise Exception("Unexpected structured array inner shape")
if arr['x y z'].dtype != int:   raise Exception("Unexpected structured array inner dtype")
if arr['name' ][0] != 'a':      raise Exception("mismatch")
if arr['name2'][1] != 'qq2':    raise Exception("mismatch")
if np.linalg.norm((ref - arr['x y z']).ravel()) > 1e-8:
    raise Exception("Array mismatch")

# selecting a subset of the data
ref = np.array(((1,3),
                (4,6),),)
dtype = np.dtype([ ('name2', 'U16'),
                   ('x z', int, (2,)) ])
f = StringIO(inputstring)
arr = vnlog.slurp(f, dtype=dtype)
if arr['x z'].shape != (2,2): raise Exception("Unexpected structured array inner shape")
if arr['x z'].dtype != int:   raise Exception("Unexpected structured array inner dtype")
if arr['name2'][1] != 'qq2':    raise Exception("mismatch")
if np.linalg.norm((ref - arr['x z']).ravel()) > 1e-8:
    raise Exception("Array mismatch")


dtype = np.dtype([ ('name',  'U16'),
                   ('x yz', int, (3,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
try:    arr = vnlog.slurp(f, dtype=dtype)
except: pass
else:   raise Exception("Bad dtype wasn't flagged")

dtype = np.dtype([ ('name',  'U16'),
                   ('x yz', int, (2,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
try:    arr = vnlog.slurp(f, dtype=dtype)
except: pass
else:   raise Exception("Bad dtype wasn't flagged")

dtype = np.dtype([ ('name',  'U16'),
                   ('x y z w', int, (4,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
try:    arr = vnlog.slurp(f, dtype=dtype)
except: pass
else:   raise Exception("Bad dtype wasn't flagged")

dtype = np.dtype([ ('name',  'U16'),
                   ('x y z', int, (2,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
try:    arr = vnlog.slurp(f, dtype=dtype)
except: pass
else:   raise Exception("Bad dtype wasn't flagged")

dtype = np.dtype([ ('name',  'U16'),
                   ('x y z', int, (3,)),
                   ('name 2', 'U16'), ])
f = StringIO(inputstring)
try:    arr = vnlog.slurp(f, dtype=dtype)
except: pass
else:   raise Exception("Bad dtype wasn't flagged")

# Slurping a single row with a structured dtype
inputstring = '''
## asdf
# x name y name2 z
4 fbb 5 qq2 6
'''
dtype = np.dtype([ ('name',  'U16'),
                   ('x y z', int, (3,)),
                   ('name2', 'U16'), ])
f = StringIO(inputstring)
arr = vnlog.slurp(f, dtype=dtype)
if arr.shape != (1,):           raise Exception("Unexpected structured array outer shape")
if arr['name' ].shape != (1,):  raise Exception("Unexpected structured array inner shape")
if arr['name2'].shape != (1,):  raise Exception("Unexpected structured array inner shape")
if arr['x y z'].shape != (1,3): raise Exception("Unexpected structured array inner shape")


print("Test passed")
sys.exit(0);

