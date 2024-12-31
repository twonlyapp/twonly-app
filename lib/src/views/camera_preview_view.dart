import 'package:camera/camera.dart';
import 'camera_editor_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;
  static const routeName = '/camera_preview';

  @override
  CameraPreviewViewState createState() => CameraPreviewViewState();
}

class CameraPreviewViewState extends State<CameraPreviewView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  int _selectedCameraIdx = 0;

  double _baseScaleFactor = 1.0;
  double _basePanY = 0.0;
  double _scaleFactor = 1;
  double _minimumScaleFactor = 1;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras.first,
      // Define the resolution to use.
      ResolutionPreset.max,
    );

    final size = Size(50, 300);

    _controller.initialize().then((_) {
      _controller.value = _controller.value.copyWith(previewSize: size);
      setState(() {});
    });

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> updateController() async {
    await _controller.setDescription(widget.cameras[_selectedCameraIdx]);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  // function for cropping image
  Future<void> takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraEditorView(
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  List<double> getImageSize(double height, double width) {
    // https://github.com/flutter/flutter/issues/15953#issuecomment-855182376

    final screenH = max(height, width);
    final screenW = min(height, width);

    var ratioContainer = screenH / screenW;

    var tmp = _controller.value.previewSize!;
    final previewH = max(tmp.height, tmp.width);
    final previewW = min(tmp.height, tmp.width);

    var ratio = previewH / previewW;
    var missing = ratioContainer - ratio;

    final maxHeight = screenH;
    final maxWidth = screenH * 0.5625;

    _minimumScaleFactor = 1 + missing;

    return [maxHeight, maxWidth];
  }

  Future<void> updateScaleFactor(double newScale) async {
    var minFactor = await _controller.getMinZoomLevel();
    var maxFactor = await _controller.getMaxZoomLevel();
    if (newScale < minFactor) {
      newScale = minFactor;
    }
    if (newScale > maxFactor) {
      newScale = maxFactor;
    }

    print(newScale);
    if (newScale <= 1) {
      await _controller.setZoomLevel(newScale);
    } else {
      //await _controller.setZoomLevel(1.0);
    }
    setState(() {
      _scaleFactor = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isFront = widget.cameras[_selectedCameraIdx].lensDirection ==
        CameraLensDirection.front;
    // Fill this out in the next steps.
    // You must wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner until the
    // controller has finished initializing.
    return Scaffold(
      body: GestureDetector(
        onPanStart: (details) async {
          if (_scaleFactor <= 1) {
            await updateScaleFactor(1);
          }
          setState(() {
            _basePanY = details.localPosition.dy;
            _baseScaleFactor = _scaleFactor;
          });
        },
        onPanUpdate: (details) async {
          final diff = details.localPosition.dy - _basePanY;
          final updateScale = diff / 50;
          var tmp = _baseScaleFactor - updateScale;
          if (tmp <= 1) tmp = 1.00001;
          updateScaleFactor(tmp);
        },
        // onScaleStart: (details) {
        //   _baseScaleFactor = _scaleFactor;
        // },
        // onScaleUpdate: (details) async {
        //   // print(scale.scale);
        //   var scaleFactor =
        //       ((_baseScaleFactor * details.scale * 10).round() / 10);
        //   var maxFactor = await _controller.getMaxZoomLevel();
        //   if (scaleFactor > maxFactor) scaleFactor = maxFactor;
        //   if (scaleFactor != _scaleFactor) {
        //     await updateScaleFactor(scaleFactor);
        //   }
        // },
        onTap: () {},
        onDoubleTap: () {
          setState(() {
            _selectedCameraIdx = (_selectedCameraIdx + 1) % 2;
            updateController();
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 60, bottom: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        var height = constraints.maxHeight;
                        var width = constraints.maxWidth;

                        return OverflowBox(
                          maxHeight: getImageSize(height, width)[0],
                          maxWidth: getImageSize(height, width)[1],
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(isFront ? pi : 0),
                            child: Transform.scale(
                                scale: _minimumScaleFactor +
                                    (_scaleFactor > 1 ? _scaleFactor : 1) -
                                    1,
                                child: CameraPreview(_controller)),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 50,
                      child: Column(
                        children: [
                          CameraZoomButtons(
                            key: widget.key,
                            isFront: isFront,
                            scaleFactor: _scaleFactor,
                            updateScaleFactor: updateScaleFactor,
                            controller: _controller,
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              await takePicture();
                            },
                            onLongPress: () async {},
                            child: Container(
                              height: 100,
                              width: 100,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 7,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CameraZoomButtons extends StatefulWidget {
  const CameraZoomButtons(
      {super.key,
      required this.isFront,
      required this.controller,
      required this.updateScaleFactor,
      required this.scaleFactor});

  final bool isFront;
  final CameraController controller;
  final double scaleFactor;
  final Function updateScaleFactor;

  @override
  State<CameraZoomButtons> createState() => _CameraZoomButtonsState();
}

String beautifulZoomScale(double scale) {
  var tmp = scale.toStringAsFixed(1);
  if (tmp[0] == "0") {
    tmp = tmp.substring(1, tmp.length);
  }
  return tmp;
}

class _CameraZoomButtonsState extends State<CameraZoomButtons> {
  @override
  Widget build(BuildContext context) {
    final zoomButtonStyle = TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
        minimumSize: Size(40, 40),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap);

    final zoomTextStyle = TextStyle(fontSize: 13);
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.0),
      child: Container(
        color: const Color.fromARGB(90, 0, 0, 0),
        child: Row(
          children: widget.isFront
              ? []
              : [
                  TextButton(
                    style: zoomButtonStyle,
                    onPressed: () async {
                      var level = await widget.controller.getMinZoomLevel();
                      widget.updateScaleFactor(level);
                    },
                    child: FutureBuilder(
                        future: widget.controller.getMinZoomLevel(),
                        builder: (context, snap) {
                          if (snap.hasData) {
                            var minLevel =
                                beautifulZoomScale(snap.data!.toDouble());
                            var currentLevel =
                                beautifulZoomScale(widget.scaleFactor);
                            return Text(
                              widget.scaleFactor < 1
                                  ? "${currentLevel}x"
                                  : "${minLevel}x",
                              style: zoomTextStyle,
                            );
                          } else {
                            return Text("");
                          }
                        }),
                  ),
                  TextButton(
                      style: zoomButtonStyle,
                      onPressed: () {
                        widget.updateScaleFactor(1.0);
                      },
                      child: Text(
                        widget.scaleFactor >= 1
                            ? "${beautifulZoomScale(widget.scaleFactor)}x"
                            : "1.0x",
                        style: zoomTextStyle,
                      )),
                  TextButton(
                    style: zoomButtonStyle,
                    onPressed: () async {
                      var level = await widget.controller.getMaxZoomLevel();
                      widget.updateScaleFactor(level);
                    },
                    child: FutureBuilder(
                        future: widget.controller.getMaxZoomLevel(),
                        builder: (context, snap) {
                          if (snap.hasData) {
                            var maxLevel = snap.data?.toInt();
                            return Text("${maxLevel}x", style: zoomTextStyle);
                          } else {
                            return Text("");
                          }
                        }),
                  )
                ],
        ),
      ),
    );
  }
}
