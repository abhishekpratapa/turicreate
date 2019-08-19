project(ml)

make_boost_test(style_transfer.cxx REQUIRES 
  unity_shared_for_testing
)