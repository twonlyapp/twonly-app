import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hand_signature/signature.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/utils/misc.dart';

class DrawLayer extends StatefulWidget {
  final DrawLayerData layerData;
  final VoidCallback? onUpdate;

  const DrawLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });
  @override
  createState() => _DrawLayerState();
}

class _DrawLayerState extends State<DrawLayer> {
  Color currentColor = Colors.red;

  var screenshotController = ScreenshotController();

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;
  bool showMagnifyingGlass = false;

  @override
  void initState() {
    widget.layerData.control.addListener(() {
      if (widget.layerData.control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        setState(() {});
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  double _sliderValue = 0.125;

  final colors = [
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.indigo,
    Colors.blue,
    Colors.black,
  ];

  Color _getColorFromSliderValue(double value) {
    // Calculate the index based on the slider value
    int index = (value * (colors.length - 1)).floor();
    int nextIndex = (index + 1).clamp(0, colors.length - 1);

    // Calculate the interpolation factor
    double factor = value * (colors.length - 1) - index;

    // Interpolate between the two colors
    return Color.lerp(colors[index], colors[nextIndex], factor)!;
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
      currentColor = _getColorFromSliderValue(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Screenshot(
              controller: screenshotController,
              child: HandSignature(
                control: widget.layerData.control,
                color: currentColor,
                width: 1.0,
                maxWidth: 7.0,
                type: SignatureDrawType.shape,
              ),
            ),
          ),
        ),
        if (widget.layerData.isEditing && widget.layerData.showCustomButtons)
          Positioned(
            top: 5,
            left: 5,
            right: 50,
            child: Row(
              children: [
                ActionButton(
                  FontAwesomeIcons.check,
                  tooltipText: context.lang.imageEditorDrawOk,
                  onPressed: () async {
                    widget.layerData.isEditing = false;
                    if (widget.onUpdate != null) {
                      widget.onUpdate!();
                    }
                    setState(() {});
                  },
                ),
                Expanded(child: Container()),
                ActionButton(
                  FontAwesomeIcons.arrowRotateLeft,
                  tooltipText: context.lang.undo,
                  color: widget.layerData.control.paths.isNotEmpty
                      ? Colors.white
                      : Colors.white.withAlpha(80),
                  onPressed: () {
                    if (widget.layerData.control.paths.isEmpty) return;
                    skipNextEvent = true;
                    undoList.add(widget.layerData.control.paths.last);
                    widget.layerData.control.stepBack();
                    setState(() {});
                  },
                ),
                ActionButton(
                  tooltipText: context.lang.redo,
                  FontAwesomeIcons.arrowRotateRight,
                  color: undoList.isNotEmpty
                      ? Colors.white
                      : Colors.white.withAlpha(80),
                  onPressed: () {
                    if (undoList.isEmpty) return;

                    widget.layerData.control.paths.add(undoList.removeLast());
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (widget.layerData.isEditing && widget.layerData.showCustomButtons)
          Positioned(
            right: 20,
            top: 50,
            child: Stack(
              children: <Widget>[
                Container(
                  height: 240,
                  width: 40,
                  color: Colors.transparent,
                ),
                SizedBox(
                  height: 240,
                  width: 40,
                  child: Center(
                    child: Container(
                      alignment: Alignment.center,
                      width: 10,
                      height: 195,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: colors,
                          stops: List.generate(colors.length,
                              (index) => index / (colors.length - 1)),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Slider(
                      value: _sliderValue,
                      thumbColor: currentColor,
                      activeColor: Colors.transparent,
                      inactiveColor: Colors.transparent,
                      onChanged: _onSliderChanged,
                      onChangeStart: (value) => {
                        setState(() {
                          showMagnifyingGlass = true;
                        })
                      },
                      onChangeEnd: (value) => {
                        setState(() {
                          showMagnifyingGlass = false;
                        })
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (showMagnifyingGlass)
          Positioned(
            right: 80,
            top: 50 + (185 * _sliderValue),
            child: MagnifyingGlass(color: currentColor),
          ),
        if (!widget.layerData.isEditing)
          Positioned.fill(
              child: Container(
            color: Colors.transparent,
          ))
      ],
    );
  }
}

class MagnifyingGlass extends StatelessWidget {
  final Color color;

  const MagnifyingGlass({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }
}
