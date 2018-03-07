import turicreate as __tc
import json as __json
import subprocess as __subprocess

def _path_to_object_detection_client():
    import sys
    import os
    (tcviz_dir, _) = os.path.split(os.path.dirname(__file__))

    if sys.platform == 'darwin':
        return os.path.join(tcviz_dir, '..', '..', 'Turi Create Object Detection Annotation.app', 'Contents', 'MacOS', 'Turi Create Object Detection Annotation')

def _start_process():
    proc = __subprocess.Popen(_path_to_object_detection_client(), stdout=__subprocess.PIPE,stdin=__subprocess.PIPE)
    # TODO: FIX window not popping in front

    return proc

def _get_all_current_labels(sframe, annotation_column):

    sfm = __tc.SFrame({annotation_column : sframe[annotation_column]})
    sfm.materialize()

    sfm = sfm.dropna()
    sfm.materialize()

    if(sfm.shape[0] == 0):
        return []

    sfm = sfm.add_column(sfm.apply(lambda x: len(x[annotation_column])), '__len_ann')
    sfm = sfm.sort('__len_ann', ascending = False)
    sfm.materialize()

    unpacked_sfm = sfm[annotation_column].unpack()

    aggregrate_sfm = unpacked_sfm["X.0"]

    for x in range(1, unpacked_sfm.shape[1]):
        aggregrate_sfm = aggregrate_sfm.append(unpacked_sfm["X."+str(x)])

    aggregrate_sfm = aggregrate_sfm.dropna()
    aggregrate_sfm.materialize()

    if(aggregrate_sfm.shape[0] == 0):
        return []

    aggregrate_sfm = aggregrate_sfm.apply(lambda x: x['label'] if 'label' in x else None)
    aggregrate_sfm = aggregrate_sfm.dropna()
    aggregrate_sfm.materialize()

    if(aggregrate_sfm.shape[0] == 0):
        return []

    return aggregrate_sfm.unique().to_numpy().tolist()

def _convert_image_base64(image):
    from PIL import Image
    import base64
    import sys

    if(sys.version_info >= (3, 0)):
        from io import BytesIO

        image_buffer = BytesIO()
        image._to_pil_image().save(image_buffer, format='PNG')
        return "data:image/png;base64,"+str(base64.b64encode(image_buffer.getvalue()))

    else:
        import cStringIO

        image_buffer = cStringIO.StringIO()
        image._to_pil_image().save(image_buffer, format="PNG")
        return "data:image/png;base64,"+str(base64.b64encode(image_buffer.getvalue()))

def _sframe_index_to_json(sframe, index, image_column, annotation_column, labels):
    if sframe.shape[0] > index and index >= 0:
        image = sframe.filter_by([index], '__idx')[0][image_column]
        current_annotations = sframe.filter_by([index], '__idx')[0][annotation_column]

        return {"data": {"image": _convert_image_base64(image), "annotations": current_annotations, "width": image.width, "height": image.height, "index": index + 1, "size": sframe.shape[0], "labels": labels}}
    else:
        return {"error": "Invalid Query: out of bounds"}

def _set_data_sframe(sframe, data, annotation_column, labels):
    sframe[annotation_column] = sframe.apply(lambda x: data["annotations"] if x['__idx'] == data["index"] else x[annotation_column])
    for d in data:
        if('label' in d):
            if(data['label'] != None):
                if not (data['label'] in labels):
                    labels.append(data['label'])
    return sframe, labels

def _process_value(value, proc, data, annotation_column, image_column, labels):
    json_value = None

    try:
        json_value = __json.loads(value)
    except:
        pass

    if json_value != None:
        if 'loaded' in json_value:
            proc.stdin.write(__json.dumps(_sframe_index_to_json(data, 0, image_column, annotation_column, labels))+"\n")
        if 'set' in json_value:
            data, labels = _set_data_sframe(data, json_value['set'], annotation_column, labels)
        if 'get' in json_value:
            proc.stdin.write(__json.dumps(_sframe_index_to_json(data, json_value['get'], image_column, annotation_column, labels))+"\n")

    return data, labels

def annotate(data, image_column = 'image', annotation_column = 'annotations'):
    """
        Annotate your images loaded in either an SFrame or SArray (Only on Mac)

        The annotate util is a GUI assisted application used to create bounding
        boxes in SArray Image data. A specifying a column, with dtype Image, of
        an SFrame works as well since SFrames are composed of multiple SArrays.

        When the GUI is terminated an SFrame is returned with the representative,
        images and annotations.

        The returned SFrame includes the newly created annotations.

        Parameters
        --------------
        data : SArray | SFrame
            The data containing the images. If the data type is 'SArray'
            the 'image_column', and 'annotation_column' variables are used to construct
            a new 'SFrame' containing the 'SArray' data for annotation.
            If the data type is 'SFrame' the 'image_column', and 'annotation_column'
            variables are used to annotate the images.

        image_column: string, optional
            If the data type is SFrame and the 'image_column' parameter is specified
            then the column name is used as the image column used in the annotation. If
            the data type is 'SFrame' and the 'image_column' variable is left empty. A
            default column value of 'image' is used in the annotation. If the data type is
            'SArray', the 'image_column' is used to construct the 'SFrame' data for
            the annotation

        annotation_column : string, optional
            If the data type is SFrame and the 'annotation_column' parameter is specified
            then the column name is used as the annotation column used in the annotation. If
            the data type is 'SFrame' and the 'annotation_column' variable is left empty. A
            default column value of 'annotation' is used in the annotation. If the data type is
            'SArray', the 'annotation_column' is used to construct the 'SFrame' data for
            the annotation


        Returns
        -------

        out : SFrame
            A new SFrame that contains the newly annotated data.

        Examples
        --------

        >> import turicreate as tc
        >> images = tc.image_analysis.load_images("path/to/images")
        >> images

            Columns:

            	path	str
            	image	Image

            Rows: 4

            Data:
            +------------------------+--------------------------+
            |          path          |          image           |
            +------------------------+--------------------------+
            | /Users/username/Doc... | Height: 1712 Width: 1952 |
            | /Users/username/Doc... | Height: 1386 Width: 1000 |
            | /Users/username/Doc... |  Height: 536 Width: 858  |
            | /Users/username/Doc... | Height: 1512 Width: 2680 |
            +------------------------+--------------------------+
            [4 rows x 2 columns]

        >> images = tc.object_detector.util.annotate(images)
        >> images

            Columns:
            	path	str
            	image	Image
            	annotation	list

            Rows: 4

            Data:
            +------------------------+--------------------------+-------------------+
            |          path          |          image           |    annotation     |
            +------------------------+--------------------------+-------------------+
            | /Users/username/Doc... | Height: 1712 Width: 1952 |   [{"coordi"...   |
            | /Users/username/Doc... | Height: 1386 Width: 1000 |   [{"coordi"...   |
            | /Users/username/Doc... |  Height: 536 Width: 858  |   [{"coordi"...   |
            | /Users/username/Doc... | Height: 1512 Width: 2680 |   [{"coordi"...   |
            +------------------------+--------------------------+-------------------+
            [4 rows x 3 columns]


    """

    import sys
    if sys.platform != 'darwin':
         raise NotImplementedError('Visualization is currently supported only on macOS.')

    if image_column == None:
        raise ValueError("'image_column' cannot be 'None'")

    if type(image_column) != str:
        raise TypeError("'image_column' has to be of type 'str'")

    if annotation_column == None:
        raise ValueError("'annotation_column' cannot be 'None'")

    if type(annotation_column) != str:
        raise TypeError("'annotation_column' has to be of type 'str'")

    if type(data) == __tc.data_structures.image.Image:
        data = __tc.SFrame({image_column:__tc.SArray([data]), annotation_column: __tc.SArray([None]), "__idx": __tc.SArray([0])})

    elif type(data) == __tc.data_structures.sframe.SFrame:

        if(data.shape[0] == 0):
            return data

        if not (data[image_column].dtype == __tc.data_structures.image.Image):
            raise TypeError("'data[image_column]' must be an SFrame or SArray")

        try:
            data[annotation_column]
        except:
            data = data.add_column(__tc.SArray(([None] * data.shape[0]), list), annotation_column)

        data = data.add_column(__tc.SArray(range(0,(data.shape[0]))), "__idx")
    elif type(data) == __tc.data_structures.sarray.SArray:

        if(data.shape[0] == 0):
            return data

        data = __tc.SFrame({image_column:data, annotation_column: __tc.SArray(([None] * data.shape[0]), list), "__idx": __tc.SArray(range(0,(data.shape[0])))})
    else:
        raise TypeError("'data' must be an SFrame or SArray")

    proc = _start_process()
    labels = _get_all_current_labels(data, annotation_column)

    while(proc.poll() == None):
        value = proc.stdout.readline()
        if value == '':
            continue

        data, labels = _process_value(value, proc, data, annotation_column, image_column, labels)

    data = data.remove_column('__idx')

    return data
