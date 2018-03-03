#!/usr/bin/python2

import re
import numpy as np


class vnlog:

    def __init__(self):
        self._keys        = None
        self._values      = None
        self._values_dict = None

    def parse(self, l):
        # I reset the data first
        self._values      = None
        self._values_dict = None

        if re.match('^\s*$', l):
            # empty line
            # no data, no error
            return True

        if re.match('^\s*#[!#]', l):
            # comment
            # no data, no error
            return True

        m = re.match('^#\s*(.*?)\s*$', l)
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

        # strip leading, trailing whitespace
        m = re.match('\s*(.*?)\s*$', l)
        l = m.group(1)

        self._values = [ None if x == '-' else x for x in l.split()]
        if len(self._values) != len(self._keys):
            raise Exception('Legend line "{}" has {} elements, but data line "{}" has {} elements. Counts must match!'. \
                            format( "# " + ' '.join(self._keys),
                                    len(self._keys),
                                    l,
                                    len(self._values)))
        return True

    def keys(self):
        return self._keys

    def values(self):
        return self._values

    def values_dict(self):

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
            for i in xrange(len(self._keys)):
                self._values_dict[self._keys[i]] = self._values[i]
        return self._values_dict




# basic usage
if __name__ == '__main__':

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

    parser = vnlog()

    for l in f:
        parser.parse(l)
        d = parser.values_dict()
        if not d:
            continue

        print d['time'],d['height']
