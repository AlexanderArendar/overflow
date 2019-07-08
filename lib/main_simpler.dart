import 'package:flutter/material.dart';

/// this is a draft of a probably simpler approach. It does not use low-level rendering with Canvas

class PicturePanZoomComponent extends StatefulWidget {
  const PicturePanZoomComponent({Key key}) : super(key: key);

  @override
  _PicturePanZoomComponentState createState() =>
      _PicturePanZoomComponentState();
}

class _PicturePanZoomComponentState extends State<PicturePanZoomComponent> {
  double top = 0;
  double left = 0;
  double ratio = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: GestureDetector(
            onPanUpdate: _handlePanUpdate,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: top,
                  left: left,
                  width: 660 * ratio,
                  child: Image.network(
                    "https://img.purch.com/w/660/aHR0cDovL3d3dy5saXZlc2NpZW5jZS5jb20vaW1hZ2VzL2kvMDAwLzEwNC84MTkvb3JpZ2luYWwvY3V0ZS1raXR0ZW4uanBn",
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _handleZoomIn,
                      ),
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: _handleZoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      top = top + details.delta.dy;
      left = left + details.delta.dx;
    });
  }

  void _handleZoomIn() {
    setState(() {
      ratio *= 1.5;
    });
  }

  void _handleZoomOut() {
    setState(() {
      ratio /= 1.5;
    });
  }
}

void main() => runApp(MyApp());

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Simpler approach"),
      ),
      body: Center(
        child: PicturePanZoomComponent(),
      ),
    );
  }
}

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
