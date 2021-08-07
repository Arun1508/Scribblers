import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class SignatureScreen extends StatefulWidget {
  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  GlobalKey globalKey = GlobalKey();
  List<Offset> _points = <Offset>[];
  var _isCaputure = false;
  File _image;
  final imagePicker = ImagePicker();

  Future<void> _capture() async {
    if (!(await Permission.camera.status.isGranted)) {
      await Permission.camera.request();
    }
    if(await Permission.camera.status.isGranted){
      final image = await ImagePicker.pickImage(
          source: ImageSource.camera);
      setState(() {
        _image = image as File;
        _isCaputure = true;
      });
    }
  }

  Future<void> _save() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    DateTime now = DateTime.now();
    if (!(await Permission.storage.status.isGranted))
      await Permission.storage.request();
    if(await Permission.storage.status.isGranted){
      final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 60,
          name: DateFormat('yyyy_MM_dd_kk_mm').format(now));
      print(result);
      setState(() {
        _isCaputure = false;
        _points = <Offset>[];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Scribblers'),
        actions: [
          IconButton(icon: Icon(Icons.camera), onPressed: () => _capture()),
          IconButton(icon: Icon(Icons.save), onPressed: () => _save()),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: RepaintBoundary(
          key: globalKey,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              setState(() {
                RenderBox object = context.findRenderObject();
                Offset _localPosition =
                    object.globalToLocal(details.globalPosition);
                _points = new List.from(_points)..add(_localPosition);
              });
            },
            onPanEnd: (DragEndDetails details) => _points.add(null),
            child: Stack(children: [
              _isCaputure
                  ? SizedBox(
                height: media.size.height,
                    width: media.size.width,
                    child: FittedBox(
                alignment: Alignment.center,
                    fit: BoxFit.fill,child: Image.file(_image)),
                  )
                  : Container(
                      color: Colors.white,
                    ),
              CustomPaint(
                painter: SignaturePainter(points: _points),
                size: Size.infinite,
                //child: Container(color: Colors.white,),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.clear),
        onPressed: () {
          setState(() {
            _points = <Offset>[];
          });
        },
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  List<Offset> points;

  SignaturePainter({this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}
