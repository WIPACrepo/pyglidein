"""
Some JSON encoding and decoding utilities.
"""

from __future__ import absolute_import, division, print_function

import json
from datetime import date, datetime, time
import logging
from collections import defaultdict

logger = logging.getLogger('util')

class datetime_converter:
    @staticmethod
    def dumps(obj):
        return obj.isoformat()
    @staticmethod
    def loads(obj, name=None):
        if ':' in obj:
            if 'T' in obj or ' ' in obj:
                center = ' '
                if 'T' in obj:
                    center = 'T'
                # must be datetime
                if '.' in obj:
                    return datetime.strptime(obj, "%Y-%m-%d"+center+"%H:%M:%S.%f")
                else:
                    return datetime.strptime(obj, "%Y-%m-%d"+center+"%H:%M:%S")
            else:
                # must be time
                if '.' in obj:
                    return datetime.strptime(obj, "%H:%M:%S.%f")
                else:
                    return datetime.strptime(obj, "%H:%M:%S")
        else:
            # must be date
            return datetime.strptime(obj, "%Y-%m-%d")

class date_converter(datetime_converter):
    @staticmethod
    def loads(obj, name=None):
        d = datetime_converter.loads(obj)
        return date(d.year, d.month, d.day)

class time_converter(datetime_converter):
    @staticmethod
    def loads(obj, name=None):
        d = datetime_converter.loads(obj)
        return time(d.hour, d.minute, d.second, d.microsecond)

JSONConverters = {
    'datetime':datetime_converter,
    'date':date_converter,
    'time':time_converter,
}

def objToJSON(obj):
    if isinstance(obj,(dict,list,tuple,str,unicode,int,long,float,bool)) or obj is None:
        return obj
    else:
        name = obj.__class__.__name__
        if name in JSONConverters:
            return {'__jsonclass__': [name, JSONConverters[name].dumps(obj)]}
        else:
            raise Exception('Cannot encode %s class to JSON'%name)

def JSONToObj(obj):
    logger.debug(obj)
    ret = obj
    if isinstance(obj, dict) and '__jsonclass__' in obj:
        logger.info('try unpacking class')
        try:
            name = obj['__jsonclass__'][0]
            if name not in JSONConverters:
                raise Exception('class %r not found in converters'%name)
            obj_repr = obj['__jsonclass__'][1]
            ret = JSONConverters[name].loads(obj_repr, name=name)
        except Exception as e:
            logger.warn('error making json class', exc_info=True)
    return ret


# copied from tornado.escape so we don't have to include that project
def recursive_unicode(obj):
    """Walks a simple data structure, converting byte strings to unicode.

    Supports lists, tuples, and dictionaries.
    """
    if isinstance(obj, dict):
        return dict((recursive_unicode(k), recursive_unicode(v)) for (k, v) in obj.iteritems())
    elif isinstance(obj, list):
        return list(recursive_unicode(i) for i in obj)
    elif isinstance(obj, tuple):
        return tuple(recursive_unicode(i) for i in obj)
    elif isinstance(obj, bytes):
        return obj.decode("utf-8")
    else:
        return obj


def json_encode(value):
    """JSON-encodes the given Python object."""
    return json.dumps(recursive_unicode(value), default=objToJSON,
                      separators=(',', ':')).replace('</', '<\\/')

def json_decode(value):
    """Returns Python objects for the given JSON string."""
    return json.loads(value, object_hook=JSONToObj)
    

def counter(states):
    out_dict = defaultdict(int)
    for s in states:
        out_dict[s] += 1
    return out_dict
