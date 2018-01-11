'''
This module defines the Timeseries class which provides the
ability to create, access and manipulate a remote scalable timeseries object.

'''

from __future__ import print_function as _
from __future__ import division as _
from __future__ import absolute_import as _
from .sarray import SArray, _create_sequential_sarray
from .sframe import SFrame

from ..connect import main as glconnect
from ..cython.cy_flexible_type import pytype_from_dtype, pytype_from_array_typecode
from ..cython.cy_flexible_type import infer_type_of_list, infer_type_of_sequence
from ..cython.cy_timeseries import UnityTimeSeriesProxy
from ..cython.context import debug_trace as cython_context
from ..util import _is_non_string_iterable, _make_internal_url
from .image import Image as _Image
from .. import aggregate as _aggregate
from ..deps import numpy, HAS_NUMPY
from ..deps import pandas, HAS_PANDAS


import logging as _logging

__all__ = ['TimeSeries']

class TimeSeries(object):

    __slots__ = ["__proxy__", "_getitem_cache"]

    def __init__(self, data=[], _proxy=None):
        if (_proxy):
            self.__proxy__ = _proxy
        elif type(data) == TimeSeries:
            self.__proxy__ = data.__proxy__
        else:
            self.__proxy__ = UnityTimeSeriesProxy()

    def testing(self):
        self.__proxy__.testing()
