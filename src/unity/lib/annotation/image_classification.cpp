#include "image_classification.hpp"
#include <functional>

#include <unity/lib/gl_sarray.hpp>

// TODO: add labels method

namespace turi {
namespace annotate {

ImageClassification::ImageClassification() {
  /* Since abstract classes cannot use std::make_shared and it needed for the
   * annotate process, we need the child class to construct the shared pointer
   * and store it in the protected variables of the inherited abstract
   * `AnnotationBase` class */
  m_self = std::make_shared<ImageClassification>(*this);
}

annotate_spec::Data ImageClassification::getItems(size_t start, size_t end) {
  annotate_spec::Data data;

  std::shared_ptr<unity_sarray> filtered_data =
      this->_filterDataSFrame(start, end);

  assert(filtered_data->dtype() == flex_type_enum::IMAGE);

  std::vector<flexible_type> flex_data = filtered_data->to_vector();

  for (size_t i = 0; i < flex_data.size(); i++) {
    flex_image img = flex_data.at(i).get<flex_image>();

    size_t img_width = img.m_width;
    size_t img_height = img.m_height;
    size_t img_channels = img.m_channels;

    const unsigned char *img_bytes = img.get_image_data();

    annotate_spec::Datum *datum = data.add_data();
    annotate_spec::ImageDatum *img_datum = datum->add_images();

    img_datum->set_width(img_width);
    img_datum->set_height(img_height);
    img_datum->set_channels(img_channels);
    img_datum->set_imgdata((void *)img_bytes, img.m_image_data_size);

    datum->set_datumhash(start + i);
  }

  return data;
}

annotate_spec::Annotations ImageClassification::getAnnotations(size_t start,
                                                               size_t end) {
  annotate_spec::Annotations annotations;

  std::shared_ptr<unity_sarray> filtered_data =
      this->_filterAnnotationSFrame(start, end);

  assert((filtered_data->dtype() == flex_type_enum::STRING) ||
         (filtered_data->dtype() == flex_type_enum::INTEGER));

  std::vector<flexible_type> flex_data = filtered_data->to_vector();

  for (size_t i = 0; i < flex_data.size(); i++) {
    annotate_spec::Annotation *annotation = annotations.add_annotation();
    annotate_spec::Label *label = annotation->add_labels();

    label->imageclassificationlabel();

    if (flex_data.at(i).get_type() == flex_type_enum::STRING) {
      std::string label_value = flex_data.at(i).get<flex_string>();
      label->set_stringlabel(label_value);
    } else if (flex_data.at(i).get_type() == flex_type_enum::INTEGER) {
      int label_value = flex_data.at(i);
      label->set_intlabel(label_value);
    }

    annotation->add_datumhash(start + i);
  }

  return annotations;
}

bool ImageClassification::setAnnotations(
    const annotate_spec::Annotations &annotations) {

  /* For Image Classification a number of assumptions are made.
   *
   * - There can only be one label per image.
   * - There can only be one image per label.
   *
   * (Note: the future we may support multi-class labeling, multiple images per
   * label and this design supports it. To enable this feature refactor this
   * code.) */

  for (int a_idx = 0; a_idx < annotations.annotation_size(); a_idx++) {
    annotate_spec::Annotation annotation = annotations.annotation(a_idx);

    annotate_spec::Label label = annotation.labels(0);
    size_t sf_idx = annotation.datumhash(0);

    assert(label.has_imageclassificationlabel());

    switch (label.labelIdentifier_case()) {
    case annotate_spec::Label::LabelIdentifierCase::kIntLabel:
      _addAnnotationToSFrame(sf_idx, label.intlabel());
      break;
    case annotate_spec::Label::LabelIdentifierCase::kStringLabel:
      _addAnnotationToSFrame(sf_idx, label.stringlabel());
      break;
    default:
      throw std::runtime_error(
          "Unexpected label type type. Expected INTEGER or STRING.");
      return false;
    }
  }

  m_data->materialize();

  return true;
}

void ImageClassification::_addAnnotationToSFrame(size_t index,
                                                 std::string label) {
  /* Assert that the column type is indeed of type flex_enum::STRING */
  size_t annotation_column_index = m_data->column_index(m_annotation_column);
  flex_type_enum annotation_column_dtype =
      m_data->dtype().at(annotation_column_index);
  assert(annotation_column_dtype == flex_type_enum::STRING);


  std::shared_ptr<unity_sarray> data_sarray =
      std::static_pointer_cast<unity_sarray>(
          m_data->select_column(m_annotation_column));

  m_data->remove_column(annotation_column_index);

  std::shared_ptr<unity_sarray> place_holder =
        std::make_shared<unity_sarray>();

  place_holder->construct_from_const(label, 1, flex_type_enum::STRING);

  /* if index is not equal to the first index */
  if(index != 0){
    std::shared_ptr<unity_sarray> top_sarray = std::static_pointer_cast<unity_sarray>(data_sarray->copy_range(0, 1, index));
    place_holder = std::static_pointer_cast<unity_sarray>(top_sarray->append(place_holder));
  }

  /* if index is not equal to the last index */
  if(index != (m_data->size()-1)){
    std::shared_ptr<unity_sarray_base> bottom_sarray = data_sarray->copy_range((index + 1), 1, m_data->size());
    place_holder = std::static_pointer_cast<unity_sarray>(place_holder->append(bottom_sarray));
  }

  /* Assert that the sarray we just created and the sframe are the same size. */
  assert(place_holder->size() == m_data->size());

  m_data->add_column(place_holder, m_annotation_column);
}

void ImageClassification::_addAnnotationToSFrame(size_t index, int label) {
  /* Assert that the column type is indeed of type flex_enum::INTEGER */
  size_t annotation_column_index = m_data->column_index(m_annotation_column);
  flex_type_enum annotation_column_dtype =
      m_data->dtype().at(annotation_column_index);
  assert(annotation_column_dtype == flex_type_enum::INTEGER);

  std::shared_ptr<unity_sarray> data_sarray =
      std::static_pointer_cast<unity_sarray>(
          m_data->select_column(m_annotation_column));

  m_data->remove_column(annotation_column_index);

  std::shared_ptr<unity_sarray> place_holder =
        std::make_shared<unity_sarray>();

  place_holder->construct_from_const(label, 1, flex_type_enum::INTEGER);

  /* if index is not equal to the first index */
  if(index != 0){
    std::shared_ptr<unity_sarray> top_sarray = std::static_pointer_cast<unity_sarray>(data_sarray->copy_range(0, 1, index));
    place_holder = std::static_pointer_cast<unity_sarray>(top_sarray->append(place_holder));
  }

  /* if index is not equal to the last index */
  if(index != (m_data->size()-1)){
    std::shared_ptr<unity_sarray_base> bottom_sarray = data_sarray->copy_range((index + 1), 1, m_data->size());
    place_holder = std::static_pointer_cast<unity_sarray>(place_holder->append(bottom_sarray));
  }

  /* Assert that the sarray we just created and the sframe are the same size. */
  assert(place_holder->size() == m_data->size());

  m_data->add_column(place_holder, m_annotation_column);
}

annotate_spec::MetaData ImageClassification::metaData() {
  std::shared_ptr<unity_sarray> data_sarray =
      std::static_pointer_cast<unity_sarray>(
          m_data->select_column(m_annotation_column));

  gl_sarray in(data_sarray);
  // TODO: rename gl_sarray
  // TODO: get vector as string
  in.unique();

  annotate_spec::MetaData meta_data;
  return meta_data;
}

std::shared_ptr<unity_sarray>
ImageClassification::_filterDataSFrame(size_t &start, size_t &end) {
  this->_reshapeIndicies(start, end);

  /* ASSUMPTION
   *
   * Assume for Image Classification that there's only one column in the
   * annotation and that the column is of Type Image */

  std::shared_ptr<unity_sarray> data_sarray =
      std::static_pointer_cast<unity_sarray>(
          m_data->select_column(m_data_columns.at(0)));

  return std::static_pointer_cast<unity_sarray>(
      data_sarray->subslice(start, 1, end));
}

std::shared_ptr<unity_sarray>
ImageClassification::_filterAnnotationSFrame(size_t &start, size_t &end) {
  this->_reshapeIndicies(start, end);

  std::shared_ptr<unity_sarray> data_sarray =
      std::static_pointer_cast<unity_sarray>(
          m_data->select_column(m_annotation_column));

  return std::static_pointer_cast<unity_sarray>(
      data_sarray->subslice(start, 1, end));
}

} // namespace annotate
} // namespace turi