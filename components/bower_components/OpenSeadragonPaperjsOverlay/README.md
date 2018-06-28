# OpenSeadragonPaperjsOverlay

An [OpenSeadragon](http://openseadragon.github.io) plugin that adds [Paper.js](http://paperjs.org) overlay capability.

Compatible with OpenSeadragon 2.0.0 or greater.

License: The BSD 3-Clause License. The software was forked from [OpenseadragonFabricjsOverlay](https://github.com/altert/OpenseadragonFabricjsOverlay), that also is licensed under the BSD 3-Clause License.

##Demo web page

See the [online demo](http://eriksjolund.github.io/OpenSeadragonPaperjsOverlay/drag_circles.html)
where some Paper.js circles are shown on top of an OpenSeadragon window. The circles can be dragged with the mouse.

## Introduction

To use, include the `openseadragon-paperjs-overlay.js` file after `openseadragon.js` on your web page.
   
To add Paper.js overlay capability to your OpenSeadragon Viewer, call `paperjsOverlay()` on it. 

`````javascript
    var viewer = new OpenSeadragon.Viewer(...);
    var overlay = viewer.paperjsOverlay();
`````

This will return a new object with the following methods:

* `paperjsCanvas()`: Returns Paper.js canvas that you can add elements to
* `resize()`: If your viewer changes size, you'll need to resize the Paper.js overlay by calling this method.

##Add drag support
Functionality for dragging Paper.js objects can be added by using OpenSeadragon.MouseTracker


`````javascript
    new OpenSeadragon.MouseTracker({
        element: viewer.canvas,
        pressHandler: press_handler,
        dragHandler: drag_handler,
        dragEndHandler: dragEnd_handler
    }).setTracking(true);
`````

together with these callbacks

`````javascript
var hit_item = null;
var drag_handler = function(event) {
    if (hit_item) {
	var transformed_point1 = paper.view.viewToProject(new paper.Point(0,0));
        var transformed_point2 = paper.view.viewToProject(new paper.Point(event.delta.x, event.delta.y));
        hit_item.position = hit_item.position.add(transformed_point2.subtract(transformed_point1));
	window.viewer.setMouseNavEnabled(false);
	paper.view.draw();
    }
};
var dragEnd_handler = function(event) {
    if (hit_item) {
        window.viewer.setMouseNavEnabled(true);
    }
    hit_item = null;
};
var press_handler = function(event) {
    hit_item = null;
    var transformed_point = paper.view.viewToProject(new paper.Point(event.position.x, event.position.y));
    var hit_test_result = paper.project.hitTest(transformed_point);
    if (hit_test_result) {
        hit_item = hit_test_result.item;
    }
};
`````

As a side-note: My first attempt to implement drag support failed.
During that attempt I didn't use OpenSeadragon.MouseTracker but instead the mouse event callbacks inside Paper.js.
I noticed, though, that the onMouseUp callback was never called and the onMouseDrag callback was called at the wrong time.
The failed approach looked something like this:

`````javascript
var x_coord = 100;
var y_coord = 100;
var radius = 20;
var circle = new paper.Path.Circle(new paper.Point(x_coord, y_coord), radius);
circle.onMouseDown = function(event) {
  ...
}
circle.onMouseUp = function(event) {
  ...
}
circle.onMouseDrag = function(event) {
  ...
}
`````



Note: The file package.json was modified to reflect the change from Fabric.js to Paper.js.
But the file has not been tested.
