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

class _ImageViewportState extends State<ImageViewport> {
  double _zoomLevel;
  ImageProvider _imageProvider;
  ui.Image _image;
  bool _resolved;
  Offset _centerOffset;
  double _maxHorizontalDelta;
  double _maxVerticalDelta;
  Offset _normalized;
  bool _denormalize = false;
  Size _actualImageSize;
  Size _viewportSize;

  List<Offset> _objects;

  double abs(double value) {
    return value < 0 ? value * (-1) : value;
  }

  void _updateActualImageDimensions() {
    _actualImageSize = Size((_image.width / window.devicePixelRatio) * _zoomLevel, (_image.height / ui.window.devicePixelRatio) * _zoomLevel);
  }

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _imageProvider = widget.imageProvider;
    _resolved = false;
    _centerOffset = Offset(0, 0);
    _objects = widget.objects;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ImageStream stream = _imageProvider.resolve(createLocalImageConfiguration(context));
    stream.addListener((info, _) {
      _image = info.image;
      _resolved = true;
      _updateActualImageDimensions();
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
    _updateActualImageDimensions();
  }

  Offset _globaltoLocalOffset(Offset value) {
    double hDelta = (_actualImageSize.width / 2) * value.dx;
    double vDelta = (_actualImageSize.height / 2) * value.dy;
    double dx = (hDelta - _centerOffset.dx) + (_viewportSize.width / 2);
    double dy = (vDelta - _centerOffset.dy) + (_viewportSize.height / 2);
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    void handleDrag(DragUpdateDetails updateDetails) {
      Offset newOffset = _centerOffset.translate(-updateDetails.delta.dx, -updateDetails.delta.dy);
      if (abs(newOffset.dx) <= _maxHorizontalDelta && abs(newOffset.dy) <= _maxVerticalDelta)
        setState(() {
          _centerOffset = newOffset;
        });
    }

    List<Widget> buildObjects() {
      return _objects.map(
        (object) => Positioned(
              left: _globaltoLocalOffset(object).dx - 10,
              top: _globaltoLocalOffset(object).dy - 10,
              child: Container(
                color: Colors.red,
                width: 20,
                height: 20,
              ),
            ),
      ).toList();
    }

    return _resolved
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _viewportSize = Size(min(constraints.maxWidth, _actualImageSize.width), min(constraints.maxHeight, _actualImageSize.height));
              _maxHorizontalDelta = (_actualImageSize.width - _viewportSize.width) / 2;
              _maxVerticalDelta = (_actualImageSize.height - _viewportSize.height) / 2;
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
                child: Stack(
                  children: <Widget>[
                    CustomPaint(
                      size: _viewportSize,
                      painter: MapPainter(_image, _zoomLevel, _centerOffset),
                    ),
                  ] + buildObjects(),
                ),
              );
            },
          )
        : SizedBox();
  }
}

class ImageViewport extends StatefulWidget {
  final double zoomLevel;
  final ImageProvider imageProvider;
  final List<Offset> objects;

  ImageViewport({
    @required this.zoomLevel,
    @required this.imageProvider,
    this.objects,
  });

  @override
  State<StatefulWidget> createState() => _ImageViewportState();
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

class ZoomContainerState extends State<ZoomContainer> {
  double _zoomLevel;
  ImageProvider _imageProvider;
  List<Offset> _objects;

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _imageProvider = widget.imageProvider;
    _objects = widget.objects;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ImageViewport(
          zoomLevel: _zoomLevel,
          imageProvider: _imageProvider,
          objects: _objects,
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
  final double zoomLevel;
  final ImageProvider imageProvider;
  final List<Offset> objects;

  ZoomContainer({
    this.zoomLevel = 1,
    @required this.imageProvider,
    this.objects = const [],
  });

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
        child: ZoomContainer(
          zoomLevel: 4,
          imageProvider: Image.asset("assets/map.jpg").image,
          objects: [
            Offset(0, 0),
            Offset(0.5, 0.25),
            Offset(-0.5, -0.5),
          ],
        ),
      ),
    );
  }
}
