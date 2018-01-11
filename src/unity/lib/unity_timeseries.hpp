#ifndef TURI_UNITY_TIMESERIES_HPP
#define TURI_UNITY_TIMESERIES_HPP

#include <vector>
#include <memory>
#include <flexible_type/flexible_type.hpp>
#include <unity/lib/api/unity_timeseries_interface.hpp>

namespace turi {

template <typename T>
class timeseries;

class unity_timeseries: public unity_timeseries_base {
  public:

    unity_timeseries();

    ~unity_timeseries();

    void testing();

};

}

#endif
