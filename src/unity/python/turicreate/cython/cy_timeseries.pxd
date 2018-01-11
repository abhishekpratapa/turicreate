# -*- coding: utf-8 -*-
# Copyright © 2017 Apple Inc. All rights reserved.
#
# Use of this source code is governed by a BSD-3-clause license that can
# be found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause
from .cy_flexible_type cimport flex_type_enum
from .cy_flexible_type cimport flexible_type
from .cy_flexible_type cimport flex_list
from .cy_flexible_type cimport gl_options_map
from libcpp.vector cimport vector
from libcpp.string cimport string
from .cy_unity_base_types cimport *
from .cy_unity cimport function_closure_info
from .cy_unity cimport make_function_closure_info

cdef extern from "<unity/lib/unity_timeseries.hpp>" namespace "turi":
    cdef cppclass unity_timeseries nogil:
        unity_timeseries() except +
        void testing() except +

cdef create_proxy_wrapper_from_existing_proxy(const unity_timeseries_base_ptr& proxy)

cdef class UnityTimeSeriesProxy:
    cdef unity_timeseries_base_ptr _base_ptr
    cdef unity_timeseries* thisptr
    cdef _cli

    cpdef testing(self)
