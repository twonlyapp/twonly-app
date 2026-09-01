import 'package:flutter/material.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/image_item.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

/// Owns the layer stack of the image editor together with its undo/redo
/// history.
///
/// The stack always starts with the [BackgroundLayerData] (the photo itself)
/// followed by the [FilterLayerData]; everything the user adds (text, drawings,
/// emojis, link previews) is stacked on top of those two.
///
/// Layers are not removed immediately when the user deletes them. They are
/// flagged via [Layer.isDeleted] by the layer widgets and only collected later,
/// which is what makes restoring them through [undo] possible.
class EditorLayerStack {
  List<Layer> _layers = [];
  final List<Layer> _undone = [];
  final List<Layer> _removed = [];

  /// All layers including the ones flagged as deleted.
  List<Layer> get all => _layers;

  /// The layers that should actually be painted and exported.
  List<Layer> get visible => _layers.where((x) => !x.isDeleted).toList();

  bool get isEmpty => _layers.isEmpty;

  bool get anyIsEditing => _layers.any((x) => x.isEditing);

  /// While a layer takes over the whole screen (cropping the background or a
  /// layer bringing its own action buttons) the editor toolbars are hidden.
  bool get takesOverScreen =>
      _layers.isNotEmpty &&
      (_layers.first.isEditing ||
          (_layers.last.isEditing && _layers.last.hasCustomActionButtons));

  /// Whether the user added anything on top of the background and the filter.
  bool get hasUserAddedLayers => _layers.any(
    (x) => x is! BackgroundLayerData && x is! FilterLayerData,
  );

  bool get canUndo => visible.length > 2;

  bool get canRedo => _undone.isNotEmpty;

  bool get isBackgroundLoaded {
    final first = _layers.firstOrNull;
    return first is BackgroundLayerData && first.imageLoaded;
  }

  /// The untouched background image, but only when nothing was drawn on top of
  /// it. In that case the editor can skip taking a screenshot and export the
  /// original image instead.
  ScreenshotImageHelper? get unmodifiedBackgroundImage {
    final background = _layers.firstOrNull;
    if (background is! BackgroundLayerData) return null;
    if (_layers.length == 1) return background.image.image;
    if (_layers.length == 2) {
      final filter = _layers[1];
      // page == 1 is the "no filter selected" page.
      if (filter is FilterLayerData && filter.page == 1) {
        return background.image.image;
      }
    }
    return null;
  }

  void addFilterLayer() => _layers.add(FilterLayerData(key: GlobalKey()));

  void addLinkPreviewLayer(Uri link) =>
      _layers.add(LinkPreviewLayerData(key: GlobalKey(), link: link));

  void insertBackgroundLayer(ImageItem image) => _layers.insert(
    0,
    BackgroundLayerData(key: GlobalKey(), image: image),
  );

  /// Adds a new layer on top and drops the redo history.
  void add(Layer layer) {
    _undone.clear();
    _removed.clear();
    _layers.add(layer);
  }

  /// Adds an empty text layer at [offset]. Does nothing while another layer is
  /// still being edited.
  void addTextLayer({Offset offset = Offset.zero}) {
    _layers = visible;
    if (anyIsEditing) return;
    add(
      TextLayerData(
        key: GlobalKey(),
        offset: offset,
        textLayersBefore: _layers.whereType<TextLayerData>().length,
      ),
    );
  }

  void addDrawLayer() => add(DrawLayerData(key: GlobalKey()));

  /// Toggles the crop/rotate mode of the background layer.
  void toggleBackgroundEditing() {
    final background = _layers.firstOrNull;
    if (background is BackgroundLayerData) {
      background.isEditing = !background.isEditing;
    }
  }

  /// Restores the last deleted layer, or removes the topmost one.
  void undo() {
    if (_removed.isNotEmpty) {
      _layers.add(
        _removed.removeLast()
          ..isDeleted = false
          ..isEditing = false,
      );
      return;
    }
    _layers = visible;
    if (_layers.length <= 2) {
      // never remove the background and the filter layer
      return;
    }
    _undone.add(_layers.removeLast());
  }

  void redo() {
    if (_undone.isEmpty) return;
    _layers.add(_undone.removeLast());
  }

  /// Called after the user finished interacting with a layer: stop editing all
  /// layers and move the ones flagged as deleted into the undo history.
  void commitPendingEdits() {
    for (final layer in _layers) {
      layer.isEditing = false;
      if (layer.isDeleted) {
        _removed.add(layer);
      }
    }
    _layers = visible;
  }

  /// The per-layer action buttons must not end up on the exported screenshot.
  void setCustomButtonsVisible({required bool visible}) {
    for (final layer in _layers) {
      layer.showCustomButtons = visible;
    }
  }

  void clear() {
    _layers.clear();
    _undone.clear();
    _removed.clear();
  }
}
