import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/painters/face_filters/beard_filter_painter.dart';
import 'package:twonly/src/views/camera/painters/face_filters/dog_filter_painter.dart';

enum FaceFilterType {
  none,
  dogBrown,
  beardUpperLip,
}

extension FaceFilterTypeExtension on FaceFilterType {
  FaceFilterType goRight() {
    final nextIndex = (index + 1) % FaceFilterType.values.length;
    return FaceFilterType.values[nextIndex];
  }

  FaceFilterType goLeft() {
    final prevIndex = (index - 1 + FaceFilterType.values.length) %
        FaceFilterType.values.length;
    return FaceFilterType.values[prevIndex];
  }

  Widget get preview {
    switch (this) {
      case FaceFilterType.none:
        return Container();
      case FaceFilterType.dogBrown:
        return DogFilterPainter.getPreview();
      case FaceFilterType.beardUpperLip:
        return BeardFilterPainter.getPreview();
    }
  }
}
