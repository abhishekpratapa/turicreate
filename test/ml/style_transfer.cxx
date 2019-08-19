#define BOOST_TEST_MODULE

#include <boost/test/unit_test.hpp>
#include <core/util/test_macros.hpp>
#include <fstream>

#include <ml/neural_net/style_transfer/mps_style_transfer_backend.hpp>

using namespace turi::neural_net;
using namespace turi::style_transfer;

struct style_transfer_test {
 public:
  void test_empty() {
    
  }
};

BOOST_FIXTURE_TEST_SUITE(_style_transfer_test, style_transfer_test)
BOOST_AUTO_TEST_CASE(test_empty) {
  style_transfer_test::test_empty();
}
BOOST_AUTO_TEST_SUITE_END()
