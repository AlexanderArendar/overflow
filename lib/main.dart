import 'dart:async';
import 'dart:ui' show window;

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class ImageViewportState extends State<ImageViewport> {
  double _mapWidth;
  double _mapHeight;
  double _alignmentX;
  double _alignmentY;
  Image _map;

  @override
  void initState() {
    super.initState();
    _map = widget.map;
    _mapWidth = widget.width;
    _mapHeight = widget.height;
    _alignmentX = 0;
    _alignmentY = 0;
  }

  @override
  void didUpdateWidget(ImageViewport oldWidget){
    _map = widget.map;
    _mapWidth = widget.width;
    _mapHeight = widget.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          onPanUpdate: (DragUpdateDetails updateDetails) {
            double oldAlignmentX = _alignmentX;
            double oldAlignmentY = _alignmentY;
            double xDelta = updateDetails.delta.dx;
            double xShift = (xDelta / _mapWidth);
            if (_alignmentX - xShift < -1)
              _alignmentX = -1;
            else if (_alignmentX - xShift > 1)
              _alignmentX = 1;
            else
              _alignmentX -= xShift;
            double yDelta = updateDetails.delta.dy;
            double yShift = (yDelta / _mapHeight);
            if (_alignmentY - yShift < -1)
              _alignmentY = -1;
            else if (_alignmentY - yShift > 1)
              _alignmentY = 1;
            else
              _alignmentY -= yShift;
            if (_alignmentX != oldAlignmentX || _alignmentY != oldAlignmentY) setState(() {
            });
          },
          child: OverflowBox(
            child: _map,
            minHeight: constraints.maxHeight,
            minWidth: constraints.maxWidth,
            maxHeight: double.infinity,
            maxWidth: double.infinity,
            alignment: Alignment(_alignmentX, _alignmentY),
          ),
        );
      },
    );
  }
}

class ImageViewport extends StatefulWidget {
  final Image map;
  final double width;
  final double height;

  ImageViewport({
    @required this.map,
    @required this.width,
    @required this.height,
  });

  @override
  State<StatefulWidget> createState() => ImageViewportState();
}

class ZoomContainerState extends State<ZoomContainer> {
  double _zoomLevel;
  Image _image;
  Completer<ImageInfo> _completer;

  void _init() {
    _image = Image.asset(
      "assets/map.jpg",
      scale: _zoomLevel,
    );
    _completer = Completer<ImageInfo>();
    ImageStream stream = _image.image.resolve(createLocalImageConfiguration(context));
    stream.addListener((ImageInfo info, _) {
      _completer.complete(info);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _init();
  }

  @override
  void initState() {
    super.initState();
    _zoomLevel = 1;
    print("device pixel ratio: ${window.devicePixelRatio}");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FutureBuilder<ImageInfo>(
          future: _completer.future,
          builder: (BuildContext context, AsyncSnapshot<ImageInfo> snapshot) {
            return (snapshot.data == null || snapshot.connectionState != ConnectionState.done)
                ? SizedBox()
                : ImageViewport(
                    map: _image,
                    width: (snapshot.data.image.width / window.devicePixelRatio) / _zoomLevel,
                    height: (snapshot.data.image.height / window.devicePixelRatio) / _zoomLevel,
                  );
          },
        ),
        Row(
          children: <Widget>[
            IconButton(
              color: Colors.red,
              icon: Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = _zoomLevel / 2;
                  _init();
                });
              },
            ),
            SizedBox(
              width: 5,
            ),
            IconButton(
              color: Colors.red,
              icon: Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _zoomLevel = _zoomLevel * 2;
                  _init();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ZoomContainer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ZoomContainerState();
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Move the map"),
      ),
      body: ZoomContainer(),
    );
  }
}
