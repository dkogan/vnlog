#!/usr/bin/env python3

r'''A simple parser for vnlog data

Synopsis:

    import vnlog
    for d in vnlog.vnlog(f):
        print(d['time'],d['height'])

Vnlog is simple, and you don't NEED a parser to read it, but this makes it a bit
nicer.

This module provides three different ways to parse vnlog

1. slurp the whole thing into a numpy array: the slurp() function. Basic usage:

   import vnlog
   log_numpy_array,list_keys,dict_key_index = \
        vnlog.slurp(filename_or_fileobject)

   This parses out the legend, and then calls numpy.loadtxt(). Null data values
   ('-') are not supported

2. Iterate through the records: vnlog class, used as an iterator. Basic usage:

   import vnlog
   for d in vnlog.vnlog(filename_or_fileobject):
       print(d['time'],d['height'])

   Null data values are represented as None


3. Parse incoming lines individually: vnlog class, using the parse() method.
   Basic usage:

   import vnlog
   parser = vnlog.vnlog()
   for l in file:
       parser.parse(l)
       d = parser.values_dict()
       if not d:
           continue
       print(d['time'],d['height'])

Most of the time you'd use options 1 or 2 above. Option 3 is the most general,
but also the most verbose

'''


from __future__ import print_function
import re

class vnlog:

    r'''Class to facilitate vnlog parsing

    This class provides two different ways to parse vnlog

    1. Iterate through the records: vnlog class, used as an iterator. Basic
       usage:

       import vnlog
       for d in vnlog.vnlog(filename_or_fileobject):
           print(d['time'],d['height'])

       Null data values are represented as None


    2. Parse incoming lines individually: vnlog class, using the parse() method.
       Basic usage:

       import vnlog
       parser = vnlog.vnlog()
       for l in file:
           parser.parse(l)
           d = parser.values_dict()
           if not d:
               continue
           print(d['time'],d['height'])

    '''

    def __init__(self, f = None):
        r'''Initialize the vnlog parser

        If using this class as an iterator, you MUST pass a filename or file
        object into this constructor
        '''

        self._keys        = None
        self._values      = None
        self._values_dict = None

        if f is None or type(f) is not str:
            self.f = f
            self.f_need_close = False
        else:
            self.f = open(f, 'r')
            self.f_need_close = True

    def __del__(self):
        try:
            if self.f_need_close:
                self.f.close()
        except:
            pass

    def parse(self, l):
        r'''Parse a new line of data.

        The user only needs to call this if they're not using this class as an
        iterator. When this function returns, the keys(), values() and
        values_dict() functions return the data from this line. Before the
        legend was parsed, all would return None. After the legend was parsed,
        keys() returns non-None. When a comment is encountered, values(),
        values_dict() return None

        '''

        # I reset the data first
        self._values      = None
        self._values_dict = None

        if not hasattr(self, 're_hard_comment'):
            self.re_hard_comment = re.compile(r'^\s*(?:#[#!]|#\s*$|$)')
            self.re_soft_comment = re.compile(r'^\s*#\s*(.*?)\s*$')

        if self.re_hard_comment.match(l):
            # empty line or hard comment.
            # no data, no error
            return True

        m = self.re_soft_comment.match(l)
        if m:
            if self._keys is not None:
                # already have legend, so this is just a comment
                # no data, no error
                return True

            # got legend.
            # no data, no error
            self._keys = m.group(1).split()
            return True

        if self._keys is None:
            # Not comment, not empty line, but no legend yet. Barf
            raise Exception("Got dataline before legend")

        # string trailing comments
        i = l.find('#')
        if i >= 0:
            l = l[:i]

        # strip leading, trailing whitespace
        l = l.strip()
        if len(l) == 0:
            return True

        self._values = [ None if x == '-' else x for x in l.split()]
        if len(self._values) != len(self._keys):
            raise Exception('Legend line "{}" has {} elements, but data line "{}" has {} elements. Counts must match!'. \
                            format( "# " + ' '.join(self._keys),
                                    len(self._keys),
                                    l,
                                    len(self._values)))
        return True

    def keys(self):
        r'''Returns the keys of the so-far-parsed data

        Returns None if we haven't seen the legend line yet'''
        return self._keys

    def values(self):
        r'''Returns the values list of the last-parsed line

        Returns None if the last line was a comment. Null fields ('-') values
        are represented as None
        '''
        return self._values

    def values_dict(self):
        r'''Returns the values dict of the last-parsed line

        This dict maps field names to values. Returns None if the last line was
        a comment. Null fields ('-') values are represented as None.
        '''

        # internally:
        #   self._values_dict == None:  not yet computed
        #   self._values_dict == {}:    computed, but no-data
        # returning: None if computed, but no-data

        if self._values_dict is not None:
            if len(self._values_dict) == 0:
                return None
            return self._values_dict

        self._values_dict = {}
        if self._keys and self._values:
            for i in range(len(self._keys)):
                self._values_dict[self._keys[i]] = self._values[i]
        return self._values_dict


    def __iter__(self):
        if self.f is None:
            raise Exception("Cannot iterate since this vnlog instance was not given a log to iterate on")
        return self

    def __next__(self):
        for l in self.f:
            self.parse(l)
            if self._values is None:
                continue

            return self.values_dict()
        raise StopIteration

    # to support python2 and python3
    next = __next__


def _slurp(f):
    r'''Reads a whole vnlog into memory

    This is an internal function. The argument is a file object, not a filename.

    Returns a tuple (log_numpy_array, list_keys, dict_key_index)

    '''
    import numpy as np


    # Stripped down numpysane.atleast_dims(). I don't want to introduce that
    # dependency
    def atleast_dims(x, d):
        if d >= 0: raise Exception("Requires d<0")
        need_ndim = -d
        if x.ndim >= need_ndim:
            return x
        num_new_axes = need_ndim-x.ndim
        return x[ (np.newaxis,)*(num_new_axes) ]


    parser = vnlog()

    keys = None
    for line in f:
        parser.parse(line)
        keys = parser.keys()
        if keys is not None:
            break
    else:
        raise Exception("vnlog parser did not find a legend line")

    dict_key_index = {}
    for i in range(len(keys)):
        dict_key_index[keys[i]] = i

    return                               \
        atleast_dims(np.loadtxt(f), -2), \
        keys,                            \
        dict_key_index


def slurp(f):
    r'''Reads a whole vnlog into memory

    Synopsis:

        import vnlog
        log_numpy_array,list_keys,dict_key_index = \
             vnlog.slurp(filename_or_fileobject)

        This parses out the legend, and then calls numpy.loadtxt(). Null data
        values ('-') are not supported.

    Returns a tuple (log_numpy_array, list_keys, dict_key_index)

    '''

    if type(f) is str:
        with open(f, 'r') as fh:
            return _slurp(fh)
    else:
        return _slurp(f)





# Basic usage. More examples in test_python_parser.py
if __name__ == '__main__':

    try:
        from StringIO import StringIO
    except ImportError:
        from io import StringIO

    f = StringIO('''#! zxcv
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

    for d in vnlog(f):
        print(d['time'],d['height'])
