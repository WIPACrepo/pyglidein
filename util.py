"""
Some JSON encoding and decoding utilities.
"""

from __future__ import absolute_import, division, print_function

import os
import json
from datetime import date,datetime,time
import base64
import zlib
import logging


class json_compressor:
    """Used for files and other large things sent over json.
       Great for log files.
    """
    @staticmethod
    def compress(obj):
        return base64.b64encode(zlib.compress(obj))
    @staticmethod
    def uncompress(obj):
        return zlib.decompress(base64.b64decode(obj))


class datetime_converter:
    @staticmethod
    def dumps(obj):
        return obj.isoformat()
    @staticmethod
    def loads(obj,name=None):
        if ':' in obj:
            if 'T' in obj or ' ' in obj:
                center = ' '
                if 'T' in obj:
                    center = 'T'
                # must be datetime
                if '.' in obj:
                    return datetime.strptime( obj, "%Y-%m-%d"+center+"%H:%M:%S.%f")
                else:
                    return datetime.strptime( obj, "%Y-%m-%d"+center+"%H:%M:%S")
            else:
                # must be time
                if '.' in obj:
                    return datetime.strptime( obj, "%H:%M:%S.%f")
                else:
                    return datetime.strptime( obj, "%H:%M:%S")
        else:
            # must be date
            return datetime.strptime( obj, "%Y-%m-%d")

class date_converter(datetime_converter):
    @staticmethod
    def loads(obj,name=None):
        d = datetime_converter.loads(obj)
        return date(d.year,d.month,d.day)

class time_converter(datetime_converter):
    @staticmethod
    def loads(obj,name=None):
        d = datetime_converter.loads(obj)
        return time(d.hour,d.minute,d.second,d.microsecond)

class binary_converter:
    """note that is is really only for decode of json, since python bytes are strings"""
    @staticmethod
    def dumps(obj,name=None):
        return base64.b64encode(obj)
    @staticmethod
    def loads(obj,name=None):
        return base64.b64decode(obj)

class bytearray_converter:
    @staticmethod
    def dumps(obj,name=None):
        return base64.b64encode(str(obj))
    @staticmethod
    def loads(obj,name=None):
        return bytearray(base64.b64decode(obj))

class set_converter:
    @staticmethod
    def dumps(obj):
        return list(obj)
    @staticmethod
    def loads(obj,name=None):
        return set(obj)

# do some default conversions
# for things like OrderedDict
import ast
from collections import OrderedDict

class repr_converter:
    @staticmethod
    def dumps(obj):
        return repr(obj)
    @staticmethod
    def loads(obj,name=None):
        parts = obj.split('(',1)
        type = parts[0]
        if type not in globals():
            raise Exception()
        parts2 = parts[1].rsplit(')',1)
        args = ast.literal_eval(parts2[0])
        if isinstance(args,tuple):
            ret = globals()['type'](*args)
        else:
            ret = globals()['type'](args)
        return ret

JSONConverters = {
    'datetime':datetime_converter,
    'date':date_converter,
    'time':time_converter,
    'binary':binary_converter,
    'bytearray':bytearray_converter,
    'OrderedDict':repr_converter,
    'set':set_converter,
}

def objToJSON(obj):
    if isinstance(obj,(dict,list,tuple,str,unicode,int,long,float,bool)) or obj is None:
        return obj
    else:
        name = obj.__class__.__name__
        if name in JSONConverters:
            return {'__jsonclass__':[name,JSONConverters[name].dumps(obj)]}
        else:
            raise Exception('Cannot encode %s class to JSON'%name)

def JSONToObj(obj):
    logging.debug(obj)
    ret = obj
    if isinstance(obj,dict) and '__jsonclass__' in obj:
        logging.info('try unpacking class')
        try:
            name = obj['__jsonclass__'][0]
            if name not in JSONConverters:
                raise Exception('class %r not found in converters'%name)
            obj_repr = obj['__jsonclass__'][1]
            ret = JSONConverters[name].loads(obj_repr,name=name)
        except Exception as e:
            logging.warn('error making json class: %r',e,exc_info=True)
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
    return json.dumps(recursive_unicode(value),default=objToJSON,separators=(',',':')).replace("</", "<\\/")

def json_decode(value):
    """Returns Python objects for the given JSON string."""
    return json.loads(value,object_hook=JSONToObj)

def config_options_dict(config):
    config_dict = {section: {option: config.get(section, option) \
                             for option in config.options(section)} \
                   for section in config.sections()}
    return config_dict

def glidein_parser():
    """Make a glidein option parser, and run it."""
    from optparse import OptionParser

    defaults = {
        'cpus':1,
        'memory':2000,
        'disk':10000,
        'gpus':0,
        'walltime':14
    }

    parser = OptionParser()
    parser.add_option('--cpus',type='float',default=defaults['cpus'],
                      help='number of cpus (default: 1)')
    parser.add_option('--memory',type='float',default=defaults['memory'],
                      help='amount of memory in MB (default: 2000)')
    parser.add_option('--disk',type='float',default=defaults['disk'],
                      help='amount of disk in MB (default: 10000)')
    parser.add_option('--gpus',type='float',default=defaults['gpus'],
                      help='number of gpus (default: 0)')
    parser.add_option('--cvmfs',type='string',default='True',
                      help='require cvmfs (default: True)')
    parser.add_option('--walltime', type='float', default=defaults["walltime"],
                      help="walltime desired (default: 14)")
    parser.add_option('--os',type='string',default=None,
                      help='OS requirement')
    parser.add_option('--glidein-loc',dest='glidein_loc',type='string',
                      default='$HOME/glidein',
                      help='glidein tarball directory')
    parser.add_option("--cluster", dest="cluster",type="string",
                      default="", 
                      help="what cluster we are running on.")
    (options,args) = parser.parse_args()

#    if options.cvmfs.lower() == 'true' or options.cvmfs == '1':
    options.cvmfs = True
#    else:
#        options.cvmfs = False

    for o in defaults:
        try:
            setattr(options,o,max(int(getattr(options,o)),defaults[o]))
        except Exception:
            continue

    options.glidein_loc = os.path.expandvars(options.glidein_loc)

    return (options,args)
