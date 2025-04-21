import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/zoom_selector.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/components/image_editor/action_button.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/components/permissions_view.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera_to_share/share_image_editor_view.dart';

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({super.key, this.sendTo});
  final Contact? sendTo;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  double scaleFactor = 1;
  bool sharePreviewIsShown = false;
  bool galleryLoadedImageIsShown = false;
  bool isFlashOn = false;
  bool showSelfieFlash = false;
  int cameraId = 0;
  bool isZoomAble = false;
  double basePanY = 0;
  double baseScaleFactor = 0;
  bool cameraLoaded = false;
  bool useHighQuality = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late CameraController controller;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    selectCamera(0, init: true);

    FlutterVolumeController.addListener(
      (volume) {
        if (!cameraLoaded) {
          // there is a bug, this is called at the start
          return;
        }
        if (sharePreviewIsShown) return;
        if (controller.value.isInitialized) takePicture();
      },
    );
    initAsync();
  }

  void initAsync() async {
    final user = await getUser();
    if (user == null) return;
    if (user.useHighQuality != null) {
      setState(() {
        useHighQuality = user.useHighQuality!;
      });
    }
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    if (cameraId < gCameras.length) {
      controller.dispose();
    }
    super.dispose();
  }

  void selectCamera(int sCameraId, {bool init = false}) {
    if (sCameraId >= gCameras.length) return;
    if (init) {
      for (; sCameraId < gCameras.length; sCameraId++) {
        if (gCameras[sCameraId].lensDirection == CameraLensDirection.back) {
          break;
        }
      }
    }
    setState(() {
      isZoomAble = false;
    });
    controller = CameraController(gCameras[sCameraId], ResolutionPreset.high,
        enableAudio: false);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);

      isZoomAble = await controller.getMinZoomLevel() !=
          await controller.getMaxZoomLevel();
      setState(() {
        cameraLoaded = true;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    setState(() {
      cameraId = sCameraId;
    });
  }

  Future<void> updateScaleFactor(double newScale) async {
    if (scaleFactor == newScale) return;
    var minFactor = await controller.getMinZoomLevel();
    var maxFactor = await controller.getMaxZoomLevel();
    if (newScale < minFactor) {
      newScale = minFactor;
    }
    if (newScale > maxFactor) {
      newScale = maxFactor;
    }

    await controller.setZoomLevel(newScale);
    setState(() {
      scaleFactor = newScale;
    });
  }

  Future<Uint8List?> loadAndDeletePictureFromFile(XFile picture) async {
    try {
      // Load the image into bytes
      final Uint8List imageBytes = await picture.readAsBytes();
      // Remove the image file
      await File(picture.path).delete();
      return imageBytes;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading picture: $e'),
          duration: Duration(seconds: 3),
        ),
      );
      return null;
    }
  }

  Future takePicture() async {
    if (sharePreviewIsShown) return;
    late Future<Uint8List?> imageBytes;

    setState(() {
      sharePreviewIsShown = true;
    });

    if (useHighQuality && !isFront) {
      if (Platform.isIOS) {
        await controller.pausePreview();
        if (!context.mounted) return;
      }
      try {
        // Take the picture
        final XFile picture = await controller.takePicture();
        imageBytes = loadAndDeletePictureFromFile(picture);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      if (isFlashOn) {
        if (isFront) {
          setState(() {
            showSelfieFlash = true;
          });
        } else {
          controller.setFlashMode(FlashMode.torch);
        }
        await Future.delayed(Duration(milliseconds: 1000));
      }

      await controller.pausePreview();
      if (!context.mounted) return;

      controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);

      imageBytes = screenshotController.capture(pixelRatio: 1);
    }

    if (await pushImageEditor(imageBytes)) {
      return;
    }

    // does not work??
    // if (Platform.isIOS) {
    //   await controller.resumePreview();
    // } else {
    selectCamera(cameraId);
    // }
    if (context.mounted) {
      setState(() {
        sharePreviewIsShown = false;
        showSelfieFlash = false;
      });
    }
  }

  Future<bool> pushImageEditor(Future<Uint8List?> imageBytes) async {
    bool? shoudReturn = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) =>
            ShareImageEditorView(imageBytes: imageBytes, sendTo: widget.sendTo),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (!context.mounted) return true;
    if (shoudReturn != null && shoudReturn) {
      if (!context.mounted) return true;
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  bool get isFront =>
      controller.description.lensDirection == CameraLensDirection.front;

  Future onPanUpdate(details) async {
    if (isFront) {
      return;
    }
    var diff = basePanY - details.localPosition.dy;
    if (diff > 200) diff = 200;
    if (diff < -200) diff = -200;
    var tmp = (diff / 200 * (7 * 2)).toInt() / 2;
    tmp = baseScaleFactor + tmp;
    if (tmp < 1) tmp = 1;
    updateScaleFactor(tmp);
  }

  @override
  Widget build(BuildContext context) {
    if (cameraId >= gCameras.length) {
      return Center(
        child: Text("No camera found."),
      );
    }
    return MediaViewSizing(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                if (!galleryLoadedImageIsShown)
                  CameraPreviewWidget(
                    controller: controller,
                    screenshotController: screenshotController,
                    isFront: isFront,
                  ),
                if (galleryLoadedImageIsShown)
                  Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 1, color: context.color.primary),
                    ),
                  ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) async {
                      if (isFront) {
                        return;
                      }
                      setState(() {
                        basePanY = details.localPosition.dy;
                        baseScaleFactor = scaleFactor;
                      });
                    },
                    onPanUpdate: onPanUpdate,
                    onDoubleTap: () async {
                      selectCamera((cameraId + 1) % 2);
                    },
                  ),
                ),
                if (!sharePreviewIsShown && widget.sendTo != null)
                  SendToWidget(sendTo: getContactDisplayName(widget.sendTo!)),
                if (!sharePreviewIsShown)
                  Positioned(
                    right: 5,
                    top: 0,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ActionButton(
                              FontAwesomeIcons.repeat,
                              tooltipText:
                                  context.lang.switchFrontAndBackCamera,
                              onPressed: () async {
                                selectCamera((cameraId + 1) % 2);
                              },
                            ),
                            ActionButton(
                              isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              tooltipText: context.lang.toggleFlashLight,
                              color: isFlashOn
                                  ? Colors.white
                                  : Color.fromARGB(158, 255, 255, 255),
                              onPressed: () async {
                                if (isFlashOn) {
                                  controller.setFlashMode(FlashMode.off);
                                  isFlashOn = false;
                                } else {
                                  controller.setFlashMode(FlashMode.always);
                                  isFlashOn = true;
                                }
                                setState(() {});
                              },
                            ),
                            if (!isFront)
                              ActionButton(
                                Icons.hd_rounded,
                                tooltipText: context.lang.toggleHighQuality,
                                color: useHighQuality
                                    ? Colors.white
                                    : const Color.fromARGB(158, 255, 255, 255),
                                onPressed: () async {
                                  useHighQuality = !useHighQuality;
                                  setState(() {});
                                  var user = await getUser();
                                  if (user != null) {
                                    user.useHighQuality = useHighQuality;
                                    updateUser(user);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!sharePreviewIsShown)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        children: [
                          if (controller.value.isInitialized &&
                              isZoomAble &&
                              !isFront)
                            SizedBox(
                              width: 120,
                              child: CameraZoomButtons(
                                key: widget.key,
                                scaleFactor: scaleFactor,
                                updateScaleFactor: updateScaleFactor,
                                controller: controller,
                              ),
                            ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    galleryLoadedImageIsShown = true;
                                    sharePreviewIsShown = true;
                                  });
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery);

                                  if (pickedFile != null) {
                                    File imageFile = File(pickedFile.path);
                                    if (await pushImageEditor(
                                        imageFile.readAsBytes())) {
                                      return;
                                    }
                                  } else {
                                    print('No image selected.');
                                  }
                                  setState(() {
                                    galleryLoadedImageIsShown = false;
                                    sharePreviewIsShown = false;
                                  });
                                },
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    height: 50,
                                    width: 80,
                                    padding: const EdgeInsets.all(2),
                                    child: Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.photoFilm,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  takePicture();
                                },
                                onLongPress: () async {},
                                child: Align(
                                  alignment: Alignment.center,
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
                              ),
                              SizedBox(width: 80)
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!sharePreviewIsShown && widget.sendTo != null)
            Positioned(
              left: 5,
              top: 10,
              child: ActionButton(
                FontAwesomeIcons.xmark,
                tooltipText: context.lang.close,
                onPressed: () async {
                  Navigator.pop(context);
                },
              ),
            ),
          if (showSelfieFlash)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SendToWidget extends StatelessWidget {
  final String sendTo;

  const SendToWidget({
    super.key,
    required this.sendTo,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      decoration: TextDecoration.none,
      shadows: [
        Shadow(
          color: const Color.fromARGB(122, 0, 0, 0),
          blurRadius: 5.0,
        ),
      ],
    );

    TextStyle boldTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.normal,
      fontSize: 28,
    );

    return Positioned(
      right: 0,
      left: 0,
      top: 50,
      child: Column(
        children: [
          Text(
            context.lang.cameraPreviewSendTo,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
          Text(
            sendTo,
            textAlign: TextAlign.center,
            style: boldTextStyle, // Use the bold text style here
          ),
        ],
      ),
    );
  }

  String getContactDisplayName(String contact) {
    // Replace this with your actual logic to get the contact display name
    return contact; // Placeholder implementation
  }
}

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final ScreenshotController screenshotController;
  final bool isFront;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.screenshotController,
    required this.isFront,
  });

  @override
  Widget build(BuildContext context) {
    return (controller.value.isInitialized)
        ? Positioned.fill(
            child: Screenshot(
              controller: screenshotController,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.previewSize!.height,
                      height: controller.value.previewSize!.width,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(
                            (isFront && Platform.isAndroid) ? 3.14 : 0),
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }
}

class CameraPreviewViewPermission extends StatefulWidget {
  const CameraPreviewViewPermission({super.key, this.sendTo});
  final Contact? sendTo;

  @override
  State<CameraPreviewViewPermission> createState() =>
      _CameraPreviewViewPermission();
}

class _CameraPreviewViewPermission extends State<CameraPreviewViewPermission> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkPermissions(),
        builder: (context, snap) {
          if (snap.hasData) {
            if (snap.data!) {
              return CameraPreviewView(sendTo: widget.sendTo);
            } else {
              return PermissionHandlerView(onSuccess: () {
                setState(() {});
              });
            }
          } else {
            return Container();
          }
        });
  }
}
