var $ = require("jquery");

var current_index = 0;
var sframe_length = 5000;
var clickable = false;
var ImageWidth = 0;
var ImageHeight = 0;
var ResizedImageWidth = 0;
var ResizedImageHeight = 0;
var label_array = new Array();
var bounding_box_array = new Array();
var context;
var close_box_size = 15;

var over_box = false;
var delete_array = -1;
var selected = -1;

var paint = false;
var start_coordinates = [-1000, -1000];
var end_coordinates = [-1000, -1000];
var start_drag_coordinates = [0, 0];
var end_drag_coordinates = new Array();

var clickX = new Array();
var clickY = new Array();
var clickDrag = new Array();

var error_disabled = false;

// TODO: Create Bounding Box Class
// TODO: Create Label Class
// TODO: Create labelLoadingClass

class Label {
    constructor(label_text, color) {
        this.text = label_text;
        this.color = color;
    }
}

class BoundingBox {
  constructor(topLeft, bottomRight, labelObject) {
    this.topLeft = topLeft;
    this.bottomRight = bottomRight;
    this.label = labelObject;
  }
}


$(document).ready(function(){
    window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'loaded'});
    context = document.getElementById('canvas').getContext("2d");

    $("#jump_to_next").click(function(){
      $("#loading_container").css("display", "block");
      window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'nextundefined', index: current_index-1});
    });

    $( "#jump_to_row_number" ).on( "keydown", function(event) {
      if(event.which == 13){
         var jump_row_value = $("#jump_to_row_number").val();

        if (jump_row_value == parseInt(jump_row_value, 10)){
          if(jump_row_value < 1 || jump_row_value > sframe_length){
              if(!error_disabled){
                error_disabled = true
                $("#error_hint").html("the requested row_number is out of bounds")
                $("#error_hint").css("left", "250px");
                $("#error_hint").animate({"top": "0px"}, 300)
                setTimeout(function(){
                  $("#error_hint").animate({"top": "-50px"}, 300, function(){
                    error_disabled = false;
                  });
                }, 2000);
              }
            }else{
              window.getSpecific(jump_row_value-1);
            }
          }else{
            if(!error_disabled){
              error_disabled = true
              $("#error_hint").html("the requested row_number is not an integer")
              $("#error_hint").css("left", "250px");
              $("#error_hint").animate({"top": "0px"}, 300)
              setTimeout(function(){
                $("#error_hint").animate({"top": "-50px"}, 300, function(){
                  error_disabled = false;
                });
              }, 2000);
            }
          }
       }
    });

    function getLabel(name){
      for(var v = 0; v < label_array.length; v++){
        if(name == label_array[v].text){
          return label_array[v];
        }
      }
      return undefined;
    }

    $("#add_label").click(function(){
        $("#modal_background").css("display", "block");
        $("#add_label_container").css("display", "block");
    });

    $("#cancel_button").click(function(){
        $("#modal_background").css("display", "none");
        $("#add_label_container").css("display", "none");
    });

    $("#add_label_button").click(function(){
        var label_text_box = $("#create_label_text_box").val();

        if(label_text_box == ''){
            $("#create_label_errors").html("Cannot have an empty label");
            return;
        }

        if(getLabel(label_text_box) != undefined){
            $("#create_label_errors").html("That label is already taken");
            return;
        }

        label_array.push(new Label(label_text_box, "#333333"));
        window.renderLabels(label_array, selected)
        window.drawBoundingBoxes();

        $("#modal_background").css("display", "none");
        $("#add_label_container").css("display", "none");
    });

    $("body").on("click", ".label_element", function(){
      if(selected != -1){
        var label_name = this.innerHTML;
        bounding_box_array[selected].label = getLabel(label_name);
        window.renderLabels(label_array, getLabel(label_name))
        window.drawBoundingBoxes();
      }
    })

    $('#canvas').mousedown(function(e){

      var mouseX = e.pageX - this.offsetLeft;
      var mouseY = e.pageY - this.offsetTop;

      over_box = check_click(mouseX, mouseY);

      // TODO: check if closed
      delete_array = check_close_clicked(mouseX, mouseY);

      if(!over_box && delete_array == -1){
        start_coordinates = [mouseX, mouseY]
        paint = true;
        addClick(mouseX, mouseY);
        return window.drawBoundingBoxes();
      }else if(over_box){
        selected = 0;
        start_drag_coordinates = [mouseX, mouseY]
        return window.drawBoundingBoxes();
      }else{
        return window.drawBoundingBoxes();
      }

    });


    $('#canvas').mousemove(function(e){
      var mouseX = e.pageX - this.offsetLeft;
      var mouseY = e.pageY - this.offsetTop;

      if(paint && !over_box){
        addClick(mouseX, mouseY, true);
        window.drawBoundingBoxes();
      }

      if(over_box){
        var delta_x = (mouseX - start_drag_coordinates[0])
        var delta_y = (mouseY - start_drag_coordinates[1])

        if(delta_x != null && delta_y != null){
          if(start_drag_coordinates[0] != 0 && start_drag_coordinates[1] != 0){
            bounding_box_array[0].topLeft[0] = bounding_box_array[0].topLeft[0] + delta_x;
            bounding_box_array[0].topLeft[1] = bounding_box_array[0].topLeft[1] + delta_y;
            bounding_box_array[0].bottomRight[0] = bounding_box_array[0].bottomRight[0] + delta_x;
            bounding_box_array[0].bottomRight[1] = bounding_box_array[0].bottomRight[1] + delta_y;
          }

          start_drag_coordinates = [mouseX, mouseY];
        }

        window.drawBoundingBoxes();
      }
    });


    $('#canvas').mouseup(function(e){
      release(true);
      start_drag_coordinates = [0, 0]
      if(delete_array != -1){
        var mouseX = e.pageX - this.offsetLeft;
        var mouseY = e.pageY - this.offsetTop;

        var v_returned = check_close_clicked(mouseX, mouseY);
        if(v_returned == delete_array){
          if(selected == v_returned){
            selected = -1;
            window.renderLabels(label_array, undefined);
          }
          bounding_box_array.splice(v_returned, 1)
          delete_array = -1
          window.drawBoundingBoxes();
        }
      }
    });


    $('#canvas').mouseleave(function(e){
      release(false);
      start_drag_coordinates = [0, 0]
      delete_array = -1
    });

    function release(free_box){
      paint = false;

      if((Math.abs(start_coordinates[0]-end_coordinates[0]) > 8 || Math.abs(start_coordinates[1]-end_coordinates[1]) > 8 ) && !over_box){
        bounding_box_array.unshift(new BoundingBox(JSON.parse(JSON.stringify(start_coordinates)), JSON.parse(JSON.stringify(end_coordinates)), undefined))
        selected = 0;
      }

      start_coordinates = [-1000, -1000]
      end_coordinates = [-1000, -1000]

      window.drawBoundingBoxes();

      if(free_box){
        over_box = false;
      }
    }

    function addClick(x, y, dragging)
    {
      end_coordinates = [x, y]
      clickX.push(JSON.parse(JSON.stringify(x)));
      clickY.push(JSON.parse(JSON.stringify(y)));
      clickDrag.push(JSON.parse(JSON.stringify(dragging)));
    }

    function check_click(x, y){
      if(x != undefined && y != undefined){
        for(var v = 0; v < bounding_box_array.length; v++){
          var start_x = bounding_box_array[v].topLeft[0];
          var start_y = bounding_box_array[v].topLeft[1];

          var end_x = bounding_box_array[v].bottomRight[0];
          var end_y = bounding_box_array[v].bottomRight[1];

          if((x > start_x && y > start_y && x < end_x && y < end_y) || (x > end_x && y > end_y && x < start_x && y < start_y) || (x > end_x && y > start_y && x < start_x && y < end_y) || (x > start_x && y > end_y && x < end_x && y < start_y)){
            var spliced_value = JSON.parse(JSON.stringify(bounding_box_array.splice(v, 1)[0]))
            bounding_box_array.unshift(spliced_value);
            if(bounding_box_array[0].label != undefined){
              window.renderLabels(label_array, getLabel(bounding_box_array[0].label.text))
            }
            return true;
          }
        }
      }
      return false;
    }

    function check_close_clicked(x, y){
      if(x != undefined && y != undefined){
        for(var v = 0; v < bounding_box_array.length; v++){
          var top_right = window.find_top_right(bounding_box_array[v]);
          var smaller_x = top_right[0] - close_box_size;
          var smaller_y = top_right[1] - close_box_size;

          var greater_x = top_right[0];
          var greater_y = top_right[1];

          if(x > smaller_x && y > smaller_y && x < greater_x && y < greater_y){
            return v;
          }
        }
      }

      return -1;
    }
});

window.isValid = function(){
  var output_valid = true;
  for(var c = 0; c < bounding_box_array.length; c++){
    if(bounding_box_array[c].label == undefined){
      output_valid = false;
      break;
    }
  }
  return output_valid;
}

window.find_top_left = function(box_array_element){
  var y = box_array_element.topLeft[1]
  var x = box_array_element.topLeft[0]
  if(box_array_element.bottomRight[1] < y){
    y = box_array_element.bottomRight[1]
  }
  if(box_array_element.bottomRight[0] < x){
    x = box_array_element.bottomRight[0]
  }
  return [x, y]
}

window.find_bottom_right = function(box_array_element){
  var y = box_array_element.topLeft[1]
  var x = box_array_element.topLeft[0]
  if(box_array_element.bottomRight[1] > y){
    y = box_array_element.bottomRight[1]
  }
  if(box_array_element.bottomRight[0] > x){
    x = box_array_element.bottomRight[0]
  }
  return [x, y]
}

window.find_top_right = function(box_array_element){
  var y = box_array_element.topLeft[1]
  var x = box_array_element.topLeft[0]
  if(box_array_element.bottomRight[1] < y){
    y = box_array_element.bottomRight[1]
  }
  if(box_array_element.bottomRight[0] > x){
    x = box_array_element.bottomRight[0]
  }
  return [x, y]
}

window.displayImage = function(value){
    $(document).ready(function(){
        $("#image_canvas_container").children('img').attr('src', value.data.image);
        bounding_box_array = [];
        window.loadLabels(value);
        window.setIndex(value);
        window.resizeImageCanvas(value);
        $("#loading_container").css("display", "none");
        clickable = true;

        if(value.error != undefined){
            $("#error_hint").html("There are no un-annotated images in the dataset")
            $("#error_hint").css("left", "230px");
            $("#error_hint").animate({"top": "0px"}, 300)
            setTimeout(function(){
              $("#error_hint").animate({"top": "-50px"}, 300, function(){
              });
            }, 2000);
        }
    });
}

window.loadLabels = function(value){
    for(var x = 0; x < value.data.labels.length; x++){
        var found = false;
        for(var r = 0; r < label_array.length; r++){
            if(value.data.labels[x] == label_array[r].text){
                found = true;
                break;
            }
        }
        if(!found){
            label_array.push(new Label(JSON.parse(JSON.stringify(value.data.labels[x])), "#333333"));
        }
    }
    window.renderLabels(label_array, undefined);
}

window.renderLabels = function(render_label_array, label_highlited){
  $(document).ready(function(){
    $("#label_container").html("");
    for(var x = 0; x < render_label_array.length; x++){
      if(label_highlited != render_label_array[x]){
        $("#label_container").append("<div class=\"label_element\">"+render_label_array[x].text+"</div>")
      }else{
        $("#label_container").append("<div class=\"label_element active_label\">"+render_label_array[x].text+"</div>")
      }
    }
  });
}

window.resizeImageCanvas = function(value){
    $(document).ready(function(){
        var image_width = 0;
        var image_height = 0;

        var image_container_width = $("#image_canvas_container").width();
        var image_container_height = $("#image_canvas_container").height();

        if(value.data.height){
            image_height = value.data.height;
        }else{
            image_height = $("#image_canvas_container img:first-child").height();
        }

        if(value.data.width){
            image_width = value.data.width;
        }else{
            image_width = $("#image_canvas_container img:first-child").width();
        }

        ImageWidth = image_width;
        ImageHeight = image_height;

        if((image_container_width*1.0/image_container_height) > (image_width*1.0/image_height)){
          var width_variable = parseInt((image_container_height*(image_width*1.0/image_height)), 10);
          var left_variable = ((image_container_width - width_variable)/2.0);

          ResizedImageWidth = width_variable;
          ResizedImageHeight = image_container_height;

          $("#image_canvas_container").children('img').css("position", "absolute");
          $("#image_canvas_container").children('img').css("width", width_variable+"px");
          $("#image_canvas_container").children('img').css("height", image_container_height+"px");
          $("#image_canvas_container").children('img').css("top", "0px");
          $("#image_canvas_container").children('img').css("left", left_variable+"px");

          $('#canvas').css("position", "absolute");
          $('#canvas').attr("width", width_variable);
          $('#canvas').attr("height", image_container_height);
          $('#canvas').css("top", "0px");
          $('#canvas').css("left", left_variable+"px");

        }else if((image_container_width*1.0/image_container_height) < (image_width*1.0/image_height)){
          var height_variable = parseInt((image_container_width/(image_width*1.0/image_height)), 10);
          var top_variable = ((image_container_height - height_variable)/2.0);

          ResizedImageWidth = image_container_width;
          ResizedImageHeight = height_variable;

          $("#image_canvas_container").children('img').css("position", "absolute");
          $("#image_canvas_container").children('img').css("height", height_variable+"px");
          $("#image_canvas_container").children('img').css("width", image_container_width+"px");
          $("#image_canvas_container").children('img').css("top", top_variable+"px");
          $("#image_canvas_container").children('img').css("left", "0px");

          $('#canvas').css("position", "absolute");
          $('#canvas').attr("height", height_variable);
          $('#canvas').attr("width", image_container_width);
          $('#canvas').css("top", top_variable+"px");
          $('#canvas').css("left", "0px");
        }else{
          ResizedImageWidth = image_container_width;
          ResizedImageHeight = image_container_height;

          $("#image_canvas_container").children('img').css("position", "absolute");
          $("#image_canvas_container").children('img').css("height", image_container_height+"px");
          $("#image_canvas_container").children('img').css("width", image_container_width+"px");
          $("#image_canvas_container").children('img').css("top", "0px");
          $("#image_canvas_container").children('img').css("left", "0px");

          $('#canvas').css("position", "absolute");
          $('#canvas').attr("height", image_container_height);
          $('#canvas').attr("width", image_container_width);
          $('#canvas').css("left", "0px");
          $('#canvas').css("top", "0px");
        }

        window.setAnnotations(value);
    });
}

window.findLabelObj = function(label_text){
    for(var r = 0; r < label_array.length; r++){
        if(label_array[r].text == label_text){
            return label_array[r];
        }
    }
    return undefined;
}

window.findTopLeft = function(center_x, center_y, half_bounding_width, half_bounding_height){
  var x_cord = center_x - half_bounding_width;
  var y_cord = center_y - half_bounding_height;
  return [x_cord, y_cord];
}

window.findBottomRight = function(center_x, center_y, half_bounding_width, half_bounding_height){
  var x_cord = center_x + half_bounding_width;
  var y_cord = center_y + half_bounding_height;
  return [x_cord, y_cord];
}

window.setAnnotations = function(value){
    $(document).ready(function(){
        if(value.data.annotations){
            for(var r = 0; r < value.data.annotations.length; r++){
                var center_x = parseInt(value.data.annotations[r].coordinates.x, 10);
                var center_y = parseInt(value.data.annotations[r].coordinates.y, 10);
                var half_bounding_width = parseInt(value.data.annotations[r].coordinates.width/2, 10);
                var half_bounding_height = parseInt(value.data.annotations[r].coordinates.height/2, 10);
                var data_label = value.data.annotations[r].label;

                center_x = parseInt((center_x/(ImageWidth*1.0/ResizedImageWidth)), 10)
                center_y = parseInt((center_y/(ImageHeight*1.0/ResizedImageHeight)), 10)

                half_bounding_width = parseInt(half_bounding_width/(ImageWidth*1.0/ResizedImageWidth), 10)
                half_bounding_height = parseInt(half_bounding_height/(ImageHeight*1.0/ResizedImageHeight), 10)

                var label_object = window.findLabelObj(data_label)

                var top_left_coordinates = window.findTopLeft(center_x, center_y, half_bounding_width, half_bounding_height);
                var bottom_right_coordinates = window.findBottomRight(center_x, center_y, half_bounding_width, half_bounding_height);

                bounding_box_array.push(new BoundingBox(JSON.parse(JSON.stringify(top_left_coordinates)), JSON.parse(JSON.stringify(bottom_right_coordinates)), label_object))
            }
        }

        window.drawBoundingBoxes();
    });
}

window.drawBoundingBoxes = function(){
  $(document).ready(function(){
    context.clearRect(0, 0, context.canvas.width, context.canvas.height);

    context.strokeStyle = "#df4b26";
    context.lineJoin = "round";
    context.lineWidth = 2;

    if(start_coordinates.length == 2 && end_coordinates.length == 2 && start_coordinates[0] != -1000 && start_coordinates[1] != -1000 && end_coordinates[0] != -1000 && end_coordinates[1] != -1000){
      context.shadowColor = 'black';
      context.shadowBlur = 10;
      context.beginPath();
      context.rect(start_coordinates[0],start_coordinates[1], end_coordinates[0]-start_coordinates[0], end_coordinates[1]-start_coordinates[1]);
      context.closePath();
      context.stroke();
    }

    for(var v = 0; v < bounding_box_array.length; v++){
      if(selected == v){
        continue
      }
      context.strokeStyle = "#CCCCCC";
      context.lineJoin = "round";
      context.lineWidth = 2;
      context.shadowColor = 'black';
      context.shadowBlur = 5;

      context.beginPath();
      context.rect(bounding_box_array[v].topLeft[0], bounding_box_array[v].topLeft[1], bounding_box_array[v].bottomRight[0]-bounding_box_array[v].topLeft[0], bounding_box_array[v].bottomRight[1] - bounding_box_array[v].topLeft[1]);
      context.closePath();
      context.stroke();

      var position = window.find_top_right(bounding_box_array[v]);

      position[0] -= close_box_size;
      position[1] -= close_box_size;

      context.fillStyle = "#CCCCCC";
      context.shadowColor = 'black';
      context.shadowBlur = 0;

      context.beginPath();
      context.fillRect(position[0], position[1], close_box_size+1, close_box_size+1);
      context.closePath();
      context.stroke();

      context.strokeStyle = "#333333";
      context.shadowColor = 'black';
      context.shadowBlur = 0;

      context.beginPath();
      context.moveTo(position[0]+2, position[1]+2);
      context.lineTo(position[0]+close_box_size-2, position[1]+close_box_size-2);
      context.moveTo(position[0]+2, position[1]+close_box_size-2);
      context.lineTo(position[0]+close_box_size-2, position[1]+2);
      context.stroke();

      if(bounding_box_array[v].label != undefined){
        context.font = "15px Arial";
        context.fillStyle = "#CCCCCC";
        context.shadowColor = 'black';
        context.shadowBlur = 0;

        var label = bounding_box_array[v].label.text;
        var width_label = context.measureText(label).width;

        context.beginPath();
        context.fillRect(position[0]- width_label - 4, position[1], width_label+4, close_box_size);
        context.stroke();

        context.fillStyle = "#333333";
        context.shadowColor = 'black';
        context.shadowBlur = 0;
        context.beginPath();
        context.fillText(label, position[0] - width_label - 2, position[1] + close_box_size - 2);
        context.stroke();
      }
    }

    if(selected != -1){
      context.strokeStyle = "#108EE9";
      context.lineJoin = "round";
      context.lineWidth = 6;
      context.shadowColor = 'black';
      context.shadowBlur = 10;

      context.beginPath();
      context.rect(bounding_box_array[0].topLeft[0], bounding_box_array[0].topLeft[1], bounding_box_array[0].bottomRight[0]-bounding_box_array[0].topLeft[0], bounding_box_array[0].bottomRight[1] - bounding_box_array[0].topLeft[1]);
      context.closePath();
      context.stroke();

      var position = window.find_top_right(bounding_box_array[0]);

      position[0] -= close_box_size;
      position[1] -= close_box_size;

      context.fillStyle = "#108EE9";
      context.shadowColor = 'black';
      context.shadowBlur = 0;

      context.beginPath();
      context.fillRect(position[0], position[1], close_box_size+3, close_box_size+3);
      context.closePath();
      context.stroke();

      context.lineWidth = 2;
      context.strokeStyle = "#FFFFFF";
      context.shadowColor = 'black';
      context.shadowBlur = 0;

      context.beginPath();
      context.moveTo(position[0]+2, position[1]+2);
      context.lineTo(position[0]+close_box_size-2, position[1]+close_box_size-2);
      context.moveTo(position[0]+2, position[1]+close_box_size-2);
      context.lineTo(position[0]+close_box_size-2, position[1]+2);
      context.stroke();

      if(bounding_box_array[0].label != undefined){
        context.font = "15px Arial";
        context.fillStyle = "#108EE9";
        context.shadowColor = 'black';
        context.shadowBlur = 0;

        var label = bounding_box_array[0].label.text;
        var width_label = context.measureText(label).width;

        context.beginPath();
        context.fillRect(position[0]- width_label - 4, position[1], width_label+4, close_box_size);
        context.stroke();

        context.fillStyle = "#FFFFFF";
        context.beginPath();
        context.fillText(label, position[0] - width_label - 2, position[1] + close_box_size - 2);
        context.stroke();
      }else{
        window.renderLabels(label_array, undefined);
      }

    }
  });

}

window.getAnnotationsDictionary = function(){
  var annotation_dictionary = [];
  for(var c = 0; c < bounding_box_array.length; c++){
    if(bounding_box_array[c].label == undefined){
        continue;
    }

    var top_left = window.find_top_left(bounding_box_array[c])
    var bottom_right = window.find_bottom_right(bounding_box_array[c])

    var center_x_val = parseInt(((top_left[0] + bottom_right[0]*1.0)/2.0), 10);
    var center_y_val = parseInt(((top_left[1] + bottom_right[1]*1.0)/2.0), 10);

    var box_width = parseInt(Math.abs(top_left[0] - bottom_right[0]*1.0), 10);
    var box_height = parseInt(Math.abs(top_left[1] - bottom_right[1]*1.0), 10);

    center_x_val = parseInt((center_x_val*(ImageWidth*1.0/ResizedImageWidth)), 10)
    center_y_val = parseInt((center_y_val*(ImageHeight*1.0/ResizedImageHeight)), 10)

    box_width = parseInt(box_width*(ImageWidth*1.0/ResizedImageWidth), 10)
    box_height = parseInt(box_height*(ImageHeight*1.0/ResizedImageHeight), 10)

    var annotation = {"label": bounding_box_array[c].label.text, "type": "rectangle", "coordinates":{"x": center_x_val, "y": center_y_val, "width": box_width, "height": box_height}}
    annotation_dictionary.push(annotation);
  }
  return annotation_dictionary;
}

window.setIndex = function(value){
    $(document).ready(function(){
        $("#image_index").html(value.data.index);
        $("#size_index").html(value.data.size);

        current_index = value.data.index
        sframe_length = value.data.size
    });
}

window.terminationApplication = function(){
  var annotation_dict = JSON.stringify(window.getAnnotationsDictionary());
  window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'sendrows', annotations: annotation_dict, index: (current_index-1)});
}

window.getNext = function(){
  if(window.isValid()){
    if(clickable && current_index < sframe_length){
        clickable = false;
        selected = -1
        $(document).ready(function(){
            $("#loading_container").css("display", "block");
            var annotation_dict = JSON.stringify(window.getAnnotationsDictionary());
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'sendrows', annotations: annotation_dict, index: (current_index-1)});
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'getrows', index: current_index});
        });
    }
  }else{
    $("#error_hint").html("All boxes must be labeled before proceeding")
    $("#error_hint").css("left", "250px");
    $("#error_hint").animate({"top": "0px"}, 300)
    setTimeout(function(){
      $("#error_hint").animate({"top": "-50px"}, 300)
    }, 2000);
  }
}

window.getSpecific = function(valid_index){
  if(window.isValid()){
    if(clickable && current_index < sframe_length){
        clickable = false;
        selected = -1
        $(document).ready(function(){
            $("#loading_container").css("display", "block");
            var annotation_dict = JSON.stringify(window.getAnnotationsDictionary());
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'sendrows', annotations: annotation_dict, index: (current_index-1)});
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'getrows', index: parseInt(valid_index, 10)});
        });
    }
  }else{
    $("#error_hint").html("All boxes must be labeled before proceeding")
    $("#error_hint").css("left", "250px");
    $("#error_hint").animate({"top": "0px"}, 300)
    setTimeout(function(){
      $("#error_hint").animate({"top": "-50px"}, 300)
    }, 2000);
  }
}

window.getPrevious= function(){
  if(window.isValid()){
    if(clickable && (current_index-2) >= 0){
        clickable = false;
        selected = -1
        $(document).ready(function(){
            $("#loading_container").css("display", "block");
            var annotation_dict = JSON.stringify(window.getAnnotationsDictionary());
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'sendrows', annotations: annotation_dict, index: (current_index-1)});
            window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'getrows', index: (current_index-2)});
        });
    }
  }else{
    $("#error_hint").animate({"top": "0px"}, 300)
    setTimeout(function(){
      $("#error_hint").animate({"top": "-50px"}, 300)
    }, 2000);
  }
}
