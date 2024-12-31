// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
// import 'package:example/widgets/demo_build_stickers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Package imports:
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/designs/frosted_glass/frosted_glass.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
// import '../../utils/example_helper.dart';

/// The frosted glass design example
class CameraEditorView extends StatefulWidget {
  /// Creates a new [CameraEditorView] widget.
  const CameraEditorView({
    super.key,
    required this.imagePath,
  });

  /// The URL of the image to display.
  final String imagePath;

  @override
  State<CameraEditorView> createState() => _CameraEditorViewState();
}

class _CameraEditorViewState extends State<CameraEditorView> {
  final bool _useMaterialDesign =
      platformDesignMode == ImageEditorDesignModeE.material;

  /// Opens the sticker/emoji editor.
  void _openStickerEditor(ProImageEditorState editor) async {
    Layer? layer = await editor.openPage(FrostedGlassStickerPage(
      configs: editor.configs,
      callbacks: editor.callbacks,
    ));

    if (layer == null || !mounted) return;

    if (layer.runtimeType != StickerLayerData) {
      layer.scale = editor.configs.emojiEditorConfigs.initScale;
    }

    editor.addLayer(layer);
  }

  /// Calculates the number of columns for the EmojiPicker.
  int _calculateEmojiColumns(BoxConstraints constraints) =>
      max(1, (_useMaterialDesign ? 6 : 10) / 400 * constraints.maxWidth - 1)
          .floor();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ProImageEditor.file(
        File(widget.imagePath),
        // key: editorKey,
        callbacks: ProImageEditorCallbacks(
            onImageEditingStarted: () {},
            onImageEditingComplete: (image) async {
              Navigator.pop(context);
            },
            onCloseEditor: () {},
            stickerEditorCallbacks: StickerEditorCallbacks(
              onSearchChanged: (value) {
                /// Filter your stickers
                debugPrint(value);
              },
            )),
        configs: ProImageEditorConfigs(
          designMode: platformDesignMode,
          theme: Theme.of(context).copyWith(
              iconTheme:
                  Theme.of(context).iconTheme.copyWith(color: Colors.white)),
          icons: const ImageEditorIcons(
            paintingEditor: IconsPaintingEditor(
              bottomNavBar: Icons.edit,
            ),
          ),
          imageEditorTheme: ImageEditorTheme(
            textEditor: TextEditorTheme(
                textFieldMargin: const EdgeInsets.only(top: kToolbarHeight),
                bottomBarBackgroundColor: Colors.transparent,
                bottomBarMainAxisAlignment: !_useMaterialDesign
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.start),
            paintingEditor: const PaintingEditorTheme(
              initialStrokeWidth: 5,
            ),
            // filterEditor: const FilterEditorTheme(
            //   filterListSpacing: 7,
            //   filterListMargin: EdgeInsets.fromLTRB(8, 15, 8, 10),
            // ),
            emojiEditor: EmojiEditorTheme(
              backgroundColor: Colors.transparent,
              textStyle: DefaultEmojiTextStyle.copyWith(
                fontFamily:
                    !kIsWeb ? null : GoogleFonts.notoColorEmoji().fontFamily,
                fontSize: _useMaterialDesign ? 48 : 30,
              ),
              emojiViewConfig: EmojiViewConfig(
                gridPadding: EdgeInsets.zero,
                horizontalSpacing: 0,
                verticalSpacing: 0,
                recentsLimit: 40,
                backgroundColor: Colors.transparent,
                buttonMode: !_useMaterialDesign
                    ? ButtonMode.CUPERTINO
                    : ButtonMode.MATERIAL,
                loadingIndicator:
                    const Center(child: CircularProgressIndicator()),
                columns: _calculateEmojiColumns(constraints),
                emojiSizeMax: !_useMaterialDesign ? 32 : 64,
                replaceEmojiOnLimitExceed: false,
              ),
              bottomActionBarConfig:
                  const BottomActionBarConfig(enabled: false),
            ),
            layerInteraction: const ThemeLayerInteraction(
              removeAreaBackgroundInactive: Colors.black12,
            ),
          ),
          textEditorConfigs: TextEditorConfigs(
            customTextStyles: [
              GoogleFonts.roboto(),
              GoogleFonts.averiaLibre(),
              GoogleFonts.lato(),
              GoogleFonts.comicNeue(),
              GoogleFonts.actor(),
              GoogleFonts.odorMeanChey(),
              GoogleFonts.nabla(),
            ],
          ),
          emojiEditorConfigs: const EmojiEditorConfigs(
            checkPlatformCompatibility: !kIsWeb,
          ),
          customWidgets: ImageEditorCustomWidgets(
            loadingDialog: (message, configs) => FrostedGlassLoadingDialog(
              message: message,
              configs: configs,
            ),
            mainEditor: CustomWidgetsMainEditor(
              closeWarningDialog: (editor) async {
                if (!context.mounted) return false;
                return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) =>
                          FrostedGlassCloseDialog(editor: editor),
                    ) ??
                    false;
              },
              appBar: (editor, rebuildStream) => null,
              bottomBar: (editor, rebuildStream, key) => null,
              bodyItems: _buildMainBodyWidgets,
            ),
            paintEditor: CustomWidgetsPaintEditor(
              appBar: (paintEditor, rebuildStream) => null,
              bottomBar: (paintEditor, rebuildStream) => null,
              colorPicker:
                  (paintEditor, rebuildStream, currentColor, setColor) => null,
              bodyItems: _buildPaintEditorBody,
            ),
            textEditor: CustomWidgetsTextEditor(
              appBar: (textEditor, rebuildStream) => null,
              colorPicker:
                  (textEditor, rebuildStream, currentColor, setColor) => null,
              bottomBar: (textEditor, rebuildStream) => null,
              bodyItems: _buildTextEditorBody,
            ),
            cropRotateEditor: CustomWidgetsCropRotateEditor(),
          ),
        ),
      );
    });
  }

  List<ReactiveCustomWidget> _buildMainBodyWidgets(
    ProImageEditorState editor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      if (editor.selectedLayerIndex < 0)
        ReactiveCustomWidget(
          stream: rebuildStream,
          builder: (_) => FrostedGlassActionBar(
            editor: editor,
            openStickerEditor: () => _openStickerEditor(editor),
          ),
        ),
    ];
  }

  List<ReactiveCustomWidget> _buildPaintEditorBody(
    PaintingEditorState paintEditor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      /// Appbar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) {
          return paintEditor.activePainting
              ? const SizedBox.shrink()
              : FrostedGlassPaintingAppbar(paintEditor: paintEditor);
        },
      ),

      /// Bottombar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) => FrostedGlassPaintBottomBar(paintEditor: paintEditor),
      ),
    ];
  }

  List<ReactiveCustomWidget> _buildTuneEditorBody(
    TuneEditorState tuneEditor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      /// Appbar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) {
          return FrostedGlassTuneAppbar(tuneEditor: tuneEditor);
        },
      ),

      /// Bottombar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) => FrostedGlassTuneBottombar(tuneEditor: tuneEditor),
      ),
    ];
  }

  List<ReactiveCustomWidget> _buildTextEditorBody(
    TextEditorState textEditor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      /// Background
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) => const FrostedGlassEffect(
          radius: BorderRadius.zero,
          child: SizedBox.expand(),
        ),
      ),

      /// Slider Text size
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) => Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight),
          child: FrostedGlassTextSizeSlider(textEditor: textEditor),
        ),
      ),

      /// Appbar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) {
          return FrostedGlassTextAppbar(textEditor: textEditor);
        },
      ),

      /// Bottombar
      ReactiveCustomWidget(
        stream: rebuildStream,
        builder: (_) => FrostedGlassTextBottomBar(
          configs: textEditor.configs,
          initColor: textEditor.primaryColor,
          onColorChanged: (color) {
            textEditor.primaryColor = color;
          },
          selectedStyle: textEditor.selectedTextStyle,
          onFontChange: textEditor.setTextStyle,
        ),
      ),
    ];
  }
}
