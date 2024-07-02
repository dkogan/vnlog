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
   arr,list_keys,dict_key_index = \
        vnlog.slurp(filename_or_fileobject)

   This parses out the legend, and then calls numpy.loadtxt(). Null data values
   ('-') and any non-numerical data is not supported

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


def _slurp(f,
           *,
           dtype   = None,
           usecols = None):
    r'''Reads a whole vnlog into memory

    This is an internal function. The argument is a file object, not a filename.

    Returns a tuple (arr, list_keys, dict_key_index)

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

    # Expands the fields in a dtype into a flat list of names. This is an analogue
    # of field_type_grow_recursive() in
    # https://github.com/numpy/numpy/blob/9815c16f449e12915ef35a8255329ba26dacd5c0/numpy/core/src/multiarray/textreading/field_types.c#L95
    def field_names_in_dtype(dtype,
                             name0 = '',
                             *,
                             toplevel_names_only = False):
        def join(a,b):
            if a == '': return b
            if toplevel_names_only or a is None:
                return None
            return f"{a}.{b}"

        if dtype.subdtype is not None:
            size = np.prod(dtype.shape)
            for i in range(size):
                yield join(name0,i)
            return

        if dtype.fields is not None:
            for name1 in dtype.names:
                tup = dtype.fields[name1]
                field_descr = tup[0]
                yield from field_names_in_dtype(field_descr, join(name0,name1),
                                                toplevel_names_only = toplevel_names_only)
            return

        if name0 == '': raise Exception("Unnamed field. This is probably a bug")
        yield name0



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


    if dtype is None:
        x = np.loadtxt(f,
                       usecols = usecols)
    else:

        names_dtype_full = list(field_names_in_dtype(dtype, toplevel_names_only = False))
        names_dtype      = list(field_names_in_dtype(dtype, toplevel_names_only = True))

        # We have input fields in the vnl represented in:
        # - keys
        # - dict_key_index
        #
        # We have output fields represented in:
        # - usecols
        # - names_dtype
        #
        # 'usecols' and 'names_dtype' have the same number of elements: one describing
        # each field. 'usecols' are integers indexing the input fields in 'keys'.
        # 'names_dtype' are names of these input fields, which must match the input
        # names given in 'keys'. Compound fields in the names_dtype are None (an 'xyz'
        # field will appear as (None,None,None)), and will match any field name in
        # 'keys'. A None field in usecols will be auto-filled-in from 'dict_key_index'
        if len(names_dtype) != len(usecols):
            raise Exception(f"Have {len(names_dtype)} names in the given dtype and {len(usecols)} columns in usecols. These MUST match")

        Ncols_output = len(usecols)

        usecols_expanded = list(usecols) # make a modifiable copy

        for i_out in range(Ncols_output):
            name_dtype = names_dtype[i_out]
            if name_dtype is None:
                if usecols_expanded[i_out] is None:
                    raise Exception(f'Output field {i_out=} is in a compound type "{names_dtype_full[i_out]}", so its input column MUST be given in usecols, but it is None')
                continue

            try:
                i_in = dict_key_index[name_dtype]
            except:
                raise Exception(f"The given dtype has {name_dtype=} but this doesn't appear in the vnlog columns {keys=}")

            if usecols_expanded[i_out] is None:
                usecols_expanded[i_out] = i_in
            else:
                if usecols_expanded[i_out] != i_in:
                    raise Exception(f"The given dtype has {name_dtype=}, which appears in the input vnlog column {i_in=}, but usecols has it in column {usecols_expanded[i_out]}. These must match. Or leave the usecols entry as None to auto-fill")


        x = np.loadtxt(f,
                       dtype   = dtype,
                       usecols = usecols_expanded)

    return                   \
        atleast_dims(x, -2), \
        keys,                \
        dict_key_index


def slurp(f):
    r'''Reads a whole vnlog into memory

    Synopsis:

        import vnlog
        arr,list_keys,dict_key_index = \
             vnlog.slurp(filename_or_fileobject)

        This parses out the legend, and then calls numpy.loadtxt(). Null data
        values ('-') are not supported.

    Returns a tuple (arr, list_keys, dict_key_index)

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
