import 'dart:ui';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
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

class MapPainter extends CustomPainter {
  final ui.Image image;
  final double zoomLevel;
  final Offset centerOffset;

  MapPainter(this.image, this.zoomLevel, this.centerOffset);

  @override
  void paint(Canvas canvas, Size size) {
    double pixelRatio = window.devicePixelRatio;
    Size sizeInDevicePixels = Size(size.width * pixelRatio, size.height * pixelRatio);
    Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    Offset centerOffsetInDevicePixels = centerOffset.scale(pixelRatio / zoomLevel, pixelRatio / zoomLevel);
    Offset centerInDevicePixels = Offset(image.width / 2, image.height / 2).translate(centerOffsetInDevicePixels.dx, centerOffsetInDevicePixels.dy);
    Offset topLeft = centerInDevicePixels.translate(-sizeInDevicePixels.width / (2 * zoomLevel), -sizeInDevicePixels.height / (2 * zoomLevel));
    Offset rightBottom = centerInDevicePixels.translate(sizeInDevicePixels.width / (2 * zoomLevel), sizeInDevicePixels.height / (2 * zoomLevel));
    canvas.drawImageRect(
      image,
      Rect.fromPoints(topLeft, rightBottom),
      Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ImageViewportState extends State<ImageViewport> {
  double _zoomLevel;
  ui.Image _image;
  bool _resolved;
  Offset _centerOffset;
  double _maxHorizontalDelta;
  double _maxVerticalDelta;
  Offset _normalized;
  bool _denormalize = false;

  double abs(double value) {
    return value < 0 ? value * (-1) : value;
  }

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _resolved = false;
    _centerOffset = Offset(0, 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ImageStream stream = Image.asset("assets/map.jpg").image.resolve(createLocalImageConfiguration(context));
    stream.addListener((info, _) {
      _image = info.image;
      _resolved = true;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ImageViewport oldWidget) {
    double normalizedDx = _maxHorizontalDelta == 0 ? 0 : _centerOffset.dx / _maxHorizontalDelta;
    double normalizedDy = _maxVerticalDelta == 0 ? 0 : _centerOffset.dy / _maxVerticalDelta;
    _normalized = Offset(normalizedDx, normalizedDy);
    _denormalize = true;
    _zoomLevel = widget.zoomLevel;
  }

  @override
  Widget build(BuildContext context) {

    void handleDrag(DragUpdateDetails updateDetails){
      Offset newOffset = _centerOffset.translate(-updateDetails.delta.dx, -updateDetails.delta.dy);
      if (abs(newOffset.dx) <= _maxHorizontalDelta && abs(newOffset.dy) <= _maxVerticalDelta)
        setState(() {
          _centerOffset = newOffset;
        });
    }
    return _resolved
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double actualImageWidth = (_image.width / window.devicePixelRatio) * _zoomLevel;
              double actualImageHeight = (_image.height / ui.window.devicePixelRatio) * _zoomLevel;
              double viewportWidth = min(constraints.maxWidth, actualImageWidth);
              double viewportHeight = min(constraints.maxHeight, actualImageHeight);
              _maxHorizontalDelta = (actualImageWidth - viewportWidth) / 2;
              _maxVerticalDelta = (actualImageHeight - viewportHeight) / 2;
              bool reactOnHorizontalDrag = _maxHorizontalDelta > _maxVerticalDelta;
              bool reactOnPan = (_maxHorizontalDelta > 0 && _maxVerticalDelta > 0);
              if (_denormalize) {
                _centerOffset = Offset(_maxHorizontalDelta * _normalized.dx, _maxVerticalDelta * _normalized.dy);
                _denormalize = false;
              }
              return GestureDetector(
                onPanUpdate: reactOnPan ? handleDrag : null,
                onHorizontalDragUpdate: reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                onVerticalDragUpdate: !reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                child: CustomPaint(
                  size: Size(viewportWidth, viewportHeight),
                  painter: MapPainter(_image, _zoomLevel, _centerOffset),
                ),
              );
            },
          )
        : SizedBox();
  }
}

class ImageViewport extends StatefulWidget {
  final double zoomLevel;

  ImageViewport({
    @required this.zoomLevel,
  });

  @override
  State<StatefulWidget> createState() => ImageViewportState();
}

class ZoomContainerState extends State<ZoomContainer> {
  double _zoomLevel;

  @override
  void initState() {
    super.initState();
    _zoomLevel = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ImageViewport(
          zoomLevel: _zoomLevel,
        ),
        Row(
          children: <Widget>[
            IconButton(
              color: Colors.red,
              icon: Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = _zoomLevel * 2;
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
                  _zoomLevel = _zoomLevel / 2;
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
      body: Center(
        child: ZoomContainer(),
      ),
    );
  }
}
