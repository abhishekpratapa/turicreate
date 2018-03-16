#include "ml_model_wrapper.hpp"
#include <unity/lib/toolkit_function_macros.hpp>

namespace turi{
  void MLModelWrapper::save(std::string path_to_save_file) {
    // TODO: validate filename
    CoreML::Result r = m_pipeline->save(path_to_save_file);

    if(!r.good()) {
      log_and_throw("Could not export model: " + r.message());
    }
  }

  void MLModelWrapper::add_metadata(std::map<std::string, flexible_type> context_metadata) {
    ::turi::add_metadata(m_pipeline->m_spec, context_metadata);
  }

  BEGIN_CLASS_REGISTRATION
  REGISTER_CLASS(MLModelWrapper)
  END_CLASS_REGISTRATION
}
