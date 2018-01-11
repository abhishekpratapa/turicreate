
#ifndef TURI_UNITY_TURICREATE_INTERFACE_HPP
#define TURI_UNITY_TURICREATE_INTERFACE_HPP
#include <memory>
#include <vector>
#include <string>
#include <flexible_type/flexible_type.hpp>
#include <unity/lib/api/function_closure_info.hpp>
#include <cppipc/magic_macros.hpp>

namespace turi {
  class unity_timeseries_base;
  GENERATE_INTERFACE_AND_PROXY(unity_timeseries_base, unity_timeseries_proxy,
    (void, testing, )
  )
}

#endif
#include <unity/lib/api/unity_sframe_interface.hpp>
