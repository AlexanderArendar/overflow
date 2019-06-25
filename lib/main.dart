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

class ImageHolderState extends State<ImageHolder> {
  double _mapWidth;
  double _mapHeight;
  double _alignmentX;
  double _alignmentY;
  Image _map;
  bool _imageResolved;

  @override
  void initState() {
    super.initState();
    _imageResolved = false;
    _map = Image.asset("assets/map.jpg", fit: BoxFit.none);
    _alignmentX = 0;
    _alignmentY = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ImageStream stream = _map.image.resolve(createLocalImageConfiguration(context));
    stream.addListener((ImageInfo info, _) {
      _mapWidth = info.image.width / window.devicePixelRatio;
      _mapHeight = info.image.height / window.devicePixelRatio;
    });
    setState(() {
      _imageResolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _imageResolved
            ? GestureDetector(
                onPanUpdate: (DragUpdateDetails updateDetails) {
                  double oldAlignmentX = _alignmentX;
                  double oldAlignmentY = _alignmentY;
                  double xDelta = updateDetails.delta.dx;
                  double xShift = (xDelta / _mapWidth) * 2;
                  if (_alignmentX - xShift < -1)
                    _alignmentX = -1;
                  else if (_alignmentX - xShift > 1)
                    _alignmentX = 1;
                  else
                    _alignmentX -= xShift;
                  double yDelta = updateDetails.delta.dy;
                  double yShift = (yDelta / _mapHeight) * 2;
                  if (_alignmentY - yShift < -1)
                    _alignmentY = -1;
                  else if (_alignmentY - yShift > 1)
                    _alignmentY = 1;
                  else
                    _alignmentY -= yShift;
                  if(_alignmentX != oldAlignmentX || _alignmentY != oldAlignmentY) setState(() {

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
              )
            : SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );
      },
    );
  }
}

class ImageHolder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ImageHolderState();
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Move the map"),
      ),
      body: ImageHolder(),
    );
  }
}
