import turicreate as __tc
import json as __json
import subprocess as __subprocess
import PIL as __PIL
from PIL import Image as __Image
import base64 as __base64

def _path_to_object_detection_client():
    import sys
    import os
    (tcviz_dir, _) = os.path.split(os.path.dirname(__file__))

    if sys.platform == 'darwin':
        return os.path.join(tcviz_dir, '..', '..', 'Turi Create Object Detection Annotation.app', 'Contents', 'MacOS', 'Turi Create Object Detection Annotation')

def _start_process():
    proc = __subprocess.Popen(_path_to_object_detection_client(), stdout=__subprocess.PIPE,stdin=__subprocess.PIPE)
    return proc

def _convert_image_base64_pil(image):
    import sys

    if(sys.version_info >= (3, 0)):
        from io import BytesIO

        image_buffer = BytesIO()
        image.save(image_buffer, format='PNG')
        return "data:image/png;base64,"+str(__base64.b64encode(image_buffer.getvalue()))

    else:
        import cStringIO

        image_buffer = cStringIO.StringIO()
        image.save(image_buffer, format="PNG")
        return "data:image/png;base64,"+str(__base64.b64encode(image_buffer.getvalue()))

def _convert_image_base64(image):
    import sys

    if(sys.version_info >= (3, 0)):
        from io import BytesIO

        image_buffer = BytesIO()
        image._to_pil_image().save(image_buffer, format='PNG')
        return "data:image/png;base64,"+str(__base64.b64encode(image_buffer.getvalue()))

    else:
        import cStringIO

        image_buffer = cStringIO.StringIO()
        image._to_pil_image().save(image_buffer, format="PNG")
        return "data:image/png;base64,"+str(__base64.b64encode(image_buffer.getvalue()))

def _get_next_unlabeled_index(sframe, label_column, current_index):
    unlabeled_index = -1

    for x in range(current_index, sframe.shape[0]):
        if(sframe[label_column][x] == None):
            unlabeled_index = x
            break

    for x in range(0, current_index):
        if(sframe[label_column][x] == None):
            unlabeled_index = x
            break

    if unlabeled_index >= 0:
        return unlabeled_index, True
    else:
        return current_index, False

def _get_all_current_labels(sframe, label_column):
    labels = sframe[label_column].dropna()
    labels.materialize()
    return labels.unique().to_numpy().tolist()

def _change_label_value_at_index(sframe, label_column, current_index, value):
    sframe["label_column"] = sframe["label_column"][0:current_index].append(__tc.SArray([value])).append(sframe["label_column"][current_index, sframe.shape[0]])
    sframe.materialize()
    return sframe

def _set_sframe_values_from_json(sframe, label_column, labels, input_json):
    new_label = data['label']
    indicies = data['indicies']

    for i in indices:
        sframe = _change_label_value_at_index(sframe, label_column, i, new_label)

    labels = _get_all_current_labels(sframe, label_column)

    return sframe, labels

def _get_similarity_graph_values(sframe, simalarity_graph, image_column, index):
    returned_similarity = simalarity_graph.query(sframe[image_column][index], k=10)
    list_graphs = returned_similarity["reference_label"].to_numpy().tolist()
    list_graphs.remove(index)
    return list_graphs

def _to_img_from_Image(img):
    i = img._to_pil_image()
    i_height = i.height
    i_width = i.width

    set_height = 150
    set_width = int((i_width*1.0/i_height*1.0)*set_height)


    i = i.resize((set_width, set_height), __PIL.Image.HAMMING)

    return _convert_image_base64_pil(i)

def _create_image_array(sframe, label_column, image_column, indicies):
    image_dict = {}
    for i in indicies:
        img_str = _to_img_from_Image(sframe[image_column][i])
        image_dict[i] = {}
        image_dict[i]["image"] = img_str
        image_dict[i]["label"] = sframe[label_column][i]

    return image_dict

def _get_json_values_from_sframe(sframe, label_column, labels, image_column, simalarity_graph, current_index):
    next_value, success = _get_next_unlabeled_index(sframe, label_column, current_index)
    new_index = next_value

    if(sframe.shape[0] <= (current_index+1)  and not success):
        new_index = 0

    list_of_similar_images = _get_similarity_graph_values(sframe, simalarity_graph, image_column, new_index)

    related_image_dict = _create_image_array(sframe, label_column, image_column, list_of_similar_images)

    labels = _get_all_current_labels(sframe, label_column)

    return {"classify": {"image": _convert_image_base64(sframe[image_column][new_index]), "label": sframe[label_column][new_index], "related": related_image_dict, "labels": labels}}

def _process_value(value, proc, data, label_column, image_column, labels, simalarity_graph):
    json_value = None

    try:
        json_value = __json.loads(value)
    except:
        pass

    if json_value != None:
        if 'loaded' in json_value:
            proc.stdin.write(__json.dumps({"data": {"setType": "ImageSimilarity"}})+"\n")
            proc.stdin.write(__json.dumps(_get_json_values_from_sframe(data, label_column, labels, image_column, simalarity_graph, 0))+"\n")
        if 'set' in json_value:
            data, labels = _set_sframe_values_from_json(data, label_column, labels, json_value['set'])
        if 'next' in json_value:
            proc.stdin.write(__json.dumps(_get_json_values_from_sframe(data, label_column, labels, image_column, simalarity_graph, json_value['next']))+"\n")

    return data, labels

def annotate(data, image_column = 'image', label_column = 'label'):
    """
        Label your images loaded in either an SFrame or SArray (Only on Mac)

        The annotate util is a GUI assisted application used to place labels
        in SArray Image data. A specifying a column, with dtype Image, of
        an SFrame works as well since SFrames are composed of multiple SArrays.

        When the GUI is terminated an SFrame is returned with the representative,
        images and labels.

        The returned SFrame includes the newly created labels.

        Parameters
        --------------
        data : SArray | SFrame
            The data containing the images. If the data type is 'SArray'
            the 'image_column', and 'label_column' variables are used to construct
            a new 'SFrame' containing the 'SArray' data for labeling.
            If the data type is 'SFrame' the 'image_column', and 'label_column'
            variables are used to label the images.

        image_column: string, optional
            If the data type is SFrame and the 'image_column' parameter is specified
            then the column name is used as the image column used in the labeling. If
            the data type is 'SFrame' and the 'image_column' variable is left empty. A
            default column value of 'image' is used in the labeling. If the data type is
            'SArray', the 'image_column' is used to construct the 'SFrame' data for
            the label

        label_column : string, optional
            If the data type is SFrame and the 'label_column' parameter is specified,
            then the column name is used as the label column used in the labeling. If
            the data type is 'SFrame' and the 'label_column' variable is left empty. A
            default column value of 'label' is used in the labeling. If the data type is
            'SArray', the 'label_column' name is is used to construct the column in the
            'SFrame' data for the labeling

        Returns
        -------

        out : SFrame
            A new SFrame that contains the newly labeled data.

        Examples
        --------


    """

    import sys
    if sys.platform != 'darwin':
         raise NotImplementedError('Visualization is currently supported only on macOS.')

    if image_column == None:
        raise ValueError("'image_column' cannot be 'None'")

    if type(image_column) != str:
        raise TypeError("'image_column' has to be of type 'str'")

    if label_column == None:
        raise ValueError("'label_column' cannot be 'None'")

    if type(label_column) != str:
        raise TypeError("'label_column' has to be of type 'str'")


    if type(data) == __tc.data_structures.image.Image:
        data = __tc.SFrame({image_column:__tc.SArray([data]), label_column: __tc.SArray([None]), "__idx": __tc.SArray([0])})

    elif type(data) == __tc.data_structures.sframe.SFrame:

        if(data.shape[0] == 0):
            return data

        if not (data[image_column].dtype == __tc.data_structures.image.Image):
            raise TypeError("'data[image_column]' must be an SFrame or SArray")

        try:
            data[label_column]
        except:
            data = data.add_column(__tc.SArray(([None] * data.shape[0]), str), label_column)

        data = data.add_column(__tc.SArray(range(0,(data.shape[0]))), "__idx")

    elif type(data) == __tc.data_structures.sarray.SArray:

        if(data.shape[0] == 0):
            return data

        data = __tc.SFrame({image_column:data, label_column: __tc.SArray(([None] * data.shape[0]), str), "__idx": __tc.SArray(range(0,(data.shape[0])))})
    else:
        raise TypeError("'data' must be an SFrame or SArray")

    print("Creating Similarity graph to assist in the Annotation")
    print("-----------------------------------------------------")

    similarity_graph = __tc.image_similarity.create(__tc.SFrame({image_column: data[image_column]}))

    print("Finished Creating Image Similarity graph")
    print("----------------------------------------")
    print("Starting Annotation Platform")

    proc = _start_process()
    labels = _get_all_current_labels(data, label_column)

    while(proc.poll() == None):
        value = proc.stdout.readline()
        if value == '':
            continue

        data, labels = _process_value(value, proc, data, label_column, image_column, labels, similarity_graph)

    data = data.remove_column('__idx')

    return data
