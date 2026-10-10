import 'package:flutter/material.dart';

String mapStyleForBrightness(Brightness brightness) =>
    brightness == Brightness.dark
    ? 'https://tiles.openfreemap.org/styles/fiord'
    : 'https://tiles.openfreemap.org/styles/positron';
