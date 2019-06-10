#define BOOST_TEST_MODULE image_classification_annotation_tests
#include <unity/lib/annotation/object_detection.hpp>

#include <unity/lib/gl_sarray.hpp>

#include <boost/test/unit_test.hpp>
#include <util/test_macros.hpp>

#include <sframe/testing_utils.hpp>
#include <util/testing_utils.hpp>

#include <image/image_type.hpp>

#include "utils.cpp"

struct object_detection_test {

  void test_pass_through() {
    std::string image_column_name = "image";
    std::string annotation_column_name = "bounding_boxes";
    std::shared_ptr<turi::unity_sframe> annotation_sf =
        annotation_testing::random_od_sframe(50, image_column_name,
                                             annotation_column_name);

    turi::annotate::ObjectDetection od_annotate(
        annotation_sf, std::vector<std::string>({image_column_name}),
        annotation_column_name);

    std::shared_ptr<turi::unity_sframe> returned_sf =
        od_annotate.returnAnnotations(false);

    TS_ASSERT(annotation_testing::check_equality(annotation_sf, returned_sf));
  }

  void test_get_metadata() {
    std::string image_column_name = "image";
    std::string annotation_column_name = "bounding_boxes";
    std::shared_ptr<turi::unity_sframe> annotation_sf =
        annotation_testing::random_od_sframe(50, image_column_name,
                                             annotation_column_name);

    turi::annotate::ObjectDetection od_annotate(
        annotation_sf, std::vector<std::string>({image_column_name}),
        annotation_column_name);

    annotate_spec::MetaData od_meta_data = od_annotate.metaData();

    TS_ASSERT(od_meta_data.Type_case() == annotate_spec::MetaData::TypeCase::kObjectDetection);
  }

  void test_get_items() {
    std::string image_column_name = "image";
    std::string annotation_column_name = "bounding_boxes";
    std::shared_ptr<turi::unity_sframe> annotation_sf =
        annotation_testing::random_od_sframe(50, image_column_name,
                                          annotation_column_name);

    turi::annotate::ObjectDetection od_annotate(
            annotation_sf, std::vector<std::string>({image_column_name}),
            annotation_column_name);

    TuriCreate::Annotation::Specification::Data items =
        od_annotate.getItems(0, 10);

    TS_ASSERT(items.data_size() == 10);

    std::shared_ptr<turi::unity_sarray> image_sa =
        std::static_pointer_cast<turi::unity_sarray>(
            annotation_sf->select_column(image_column_name));

    std::vector<turi::flexible_type> image_vector = image_sa->to_vector();

    for (int x = 0; x < items.data_size(); x++) {
      TuriCreate::Annotation::Specification::Datum item = items.data(x);
      TS_ASSERT(item.images_size() == 1);

      TuriCreate::Annotation::Specification::ImageDatum image_datum =
          item.images(0);

      size_t datum_width = image_datum.width();
      size_t datum_height = image_datum.height();
      size_t datum_channels = image_datum.channels();

      turi::flex_image image = image_vector.at(x).get<turi::flex_image>();

      TS_ASSERT(image.m_width == datum_width);
      TS_ASSERT(image.m_height == datum_height);
      TS_ASSERT(image.m_channels == datum_channels);
    }
  }

  void test_get_items_out_of_index() {
    std::string image_column_name = "image";
    std::string annotation_column_name = "bounding_boxes";
    std::shared_ptr<turi::unity_sframe> annotation_sf =
        annotation_testing::random_od_sframe(50, image_column_name,
                                          annotation_column_name);

    turi::annotate::ObjectDetection od_annotate(
            annotation_sf, std::vector<std::string>({image_column_name}),
            annotation_column_name);

    TuriCreate::Annotation::Specification::Data items =
        od_annotate.getItems(50, 100);

    TS_ASSERT(items.data_size() == 0);
  }

  void test_set_annotations_pass() {
    // TODO: plumb through `test_set_annotations_pass`
  }

  void test_set_annotations_out_of_index() {
    std::string image_column_name = "image";
    std::string annotation_column_name = "bounding_boxes";
    std::shared_ptr<turi::unity_sframe> annotation_sf =
        annotation_testing::random_od_sframe(50, image_column_name,
                                          annotation_column_name);

    turi::annotate::ObjectDetection od_annotate(
            annotation_sf, std::vector<std::string>({image_column_name}),
            annotation_column_name);

    TuriCreate::Annotation::Specification::Annotations annotations;
    TuriCreate::Annotation::Specification::Annotation *annotation =
        annotations.add_annotation();

    annotate_spec::Label *label = annotation->add_labels();
    annotate_spec::ObjectDetectionLabel *od_label = label->mutable_objectdetectionlabel();

    std::string label_value = annotation_testing::random_string();
    turi::flex_list label_bounding_box = annotation_testing::random_bounding_box();
    
    od_label->set_height((int)(rand() % 256) + 1);
    od_label->set_width((int)(rand() % 256) + 1);
    od_label->set_x((int)(rand() % 256) + 1);
    od_label->set_y((int)(rand() % 256) + 1);

    label->set_stringlabel(label_value);
    annotation->add_rowindex(100);

    /* Check if the annotations get properly handled */
    TS_ASSERT(!od_annotate.setAnnotations(annotations));
  }

  void test_set_annotations_wrong_type() {
    // TODO: plumb through `test_set_annotations_wrong_type`
  }

  void test_set_annotations_empty() {
    // TODO: plumb through `test_set_annotations_empty`
  }

  void test_return_annotations() {
    // TODO: plumb through `test_return_annotations`
  }

  void test_return_annotations_drop_na() {
    // TODO: plumb through `test_return_annotations_drop_na`
  }

  void test_annotation_registry() {
    // TODO: plumb through `test_annotation_registry`
  }
};

BOOST_FIXTURE_TEST_SUITE(_object_detection_test, object_detection_test)
BOOST_AUTO_TEST_CASE(test_pass_through) {
  object_detection_test::test_pass_through();
}
BOOST_AUTO_TEST_CASE(test_get_metadata) {
  object_detection_test::test_get_metadata();
}
BOOST_AUTO_TEST_CASE(test_get_items_out_of_index) {
  object_detection_test::test_get_items_out_of_index();
}
BOOST_AUTO_TEST_CASE(test_get_items) {
  object_detection_test::test_get_items();
}
BOOST_AUTO_TEST_CASE(test_set_annotations_pass) {
  object_detection_test::test_set_annotations_pass();
}
BOOST_AUTO_TEST_CASE(test_set_annotations_out_of_index) {
  object_detection_test::test_set_annotations_out_of_index();
}
BOOST_AUTO_TEST_CASE(test_set_annotations_wrong_type) {
  object_detection_test::test_set_annotations_wrong_type();
}
BOOST_AUTO_TEST_CASE(test_set_annotations_empty) {
  object_detection_test::test_set_annotations_empty();
}
BOOST_AUTO_TEST_CASE(test_return_annotations) {
  object_detection_test::test_return_annotations();
}
BOOST_AUTO_TEST_CASE(test_return_annotations_drop_na) {
  object_detection_test::test_return_annotations_drop_na();
}
BOOST_AUTO_TEST_CASE(test_annotation_registry) {
  object_detection_test::test_annotation_registry();
}
BOOST_AUTO_TEST_SUITE_END()