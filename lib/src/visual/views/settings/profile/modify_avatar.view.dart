import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class ModifyAvatarView extends StatefulWidget {
  const ModifyAvatarView({super.key});

  @override
  State<ModifyAvatarView> createState() => _ModifyAvatarViewState();
}

class _ModifyAvatarViewState extends State<ModifyAvatarView> {
  late final _CustomAvatarMakerController _avatarMakerController;

  @override
  void initState() {
    super.initState();
    final svg = userService.currentUser.avatarSvg;
    if (svg != null && svg.isNotEmpty) {
      _avatarMakerController = _CustomAvatarMakerController(
        svg: svg,
      );
    } else {
      _avatarMakerController = _CustomAvatarMakerController.defaultAvatar();
    }
  }

  Future<void> updateUserAvatar(String json, String svg) async {
    await UserService.update(
      (u) => u
        ..avatarJson = json
        ..avatarSvg = svg
        ..avatarCounter = u.avatarCounter + 1,
    );
  }

  AvatarMakerThemeData getAvatarMakerTheme(BuildContext context) {
    final colors = context.color;
    final isDark = isDarkMode(context);
    return AvatarMakerThemeData(
      boxDecoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      unselectedTileDecoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      selectedTileDecoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        border: Border.all(color: colors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      selectedIconColor: colors.primary,
      unselectedIconColor: colors.onSurfaceVariant.withValues(alpha: 0.6),
      primaryBgColor: colors.surface,
      secondaryBgColor: colors.surfaceContainerLow,
      labelTextStyle: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.lang.avatarSaveChanges,
          ),
          actions: [
            FilledButton(
              child: Text(context.lang.avatarSaveChangesStore),
              onPressed: () async {
                await storeAvatarAndExit();
              },
            ),
            TextButton(
              child: Text(context.lang.avatarSaveChangesDiscard),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> storeAvatarAndExit() async {
    await _avatarMakerController.saveAvatarSVG();
    final json = _avatarMakerController.getJsonOptionsSync();
    final svg = _avatarMakerController.getAvatarSVGSync();
    await updateUserAvatar(json, svg);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_avatarMakerController.getJsonOptionsSync() !=
            userService.currentUser.avatarJson) {
          // there where changes
          final shouldPop = await _showBackDialog() ?? false;
          if (context.mounted && shouldPop) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsProfileCustomizeAvatar),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: AvatarMakerAvatar(
                    radius: 130,
                    backgroundColor: Colors.transparent,
                    controller: _avatarMakerController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      MyButton(
                        variant: MyButtonVariant.primaryDense,
                        onPressed: storeAvatarAndExit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                            const SizedBox(width: 6),
                            Text(context.lang.avatarSaveChangesStore),
                          ],
                        ),
                      ),
                      MyButton(
                        variant: MyButtonVariant.secondaryDense,
                        onPressed:
                            _avatarMakerController.randomizedSelectedOptions,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.shuffle, size: 16),
                            const SizedBox(width: 6),
                            Text(context.lang.avatarCustomizeRandomize),
                          ],
                        ),
                      ),
                      MyButton(
                        variant: MyButtonVariant.secondaryDense,
                        onPressed: _avatarMakerController.restoreState,
                        onLongPress: () {
                          _avatarMakerController.clearCustomizations();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.rotateLeft, size: 16),
                            const SizedBox(width: 6),
                            Text(context.lang.avatarCustomizeReset),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                  ),
                  child: AvatarMakerCustomizer(
                    scaffoldWidth: min(
                      600,
                      MediaQuery.of(context).size.width * 0.95,
                    ),
                    theme: getAvatarMakerTheme(context),
                    controller: _avatarMakerController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAvatarMakerController extends NonPersistentAvatarMakerController {
  _CustomAvatarMakerController({
    required super.svg,
  }) : _initialSvg = svg,
       super.fromSvg() {
    _initialOptions = Map.from(selectedOptions);
  }

  _CustomAvatarMakerController.defaultAvatar() : _initialSvg = '', super() {
    _initialOptions = Map.from(defaultSelectedOptions);
  }

  final String _initialSvg;
  late final Map<PropertyCategoryIds, PropertyItem> _initialOptions;
  List<CustomizedPropertyCategory>? _customPropertyCategories;

  void clearCustomizations() {
    selectedOptions = Map.from(defaultSelectedOptions);
    updatePreview();
  }

  @override
  List<CustomizedPropertyCategory> get propertyCategories {
    var list = _customPropertyCategories;
    if (list == null) {
      list = super.propertyCategories.map((category) {
        return CustomizedPropertyCategory(
          id: category.id,
          name: category.name,
          iconFile: category.iconFile,
          properties: category.properties,
          defaultValue: category.defaultValue,
        );
      }).toList();
      _customPropertyCategories = list;
    }
    return list;
  }

  @override
  List<CustomizedPropertyCategory> get displayedPropertyCategories {
    final order = [
      PropertyCategoryIds.SkinColor,
      PropertyCategoryIds.EyeType,
      PropertyCategoryIds.EyebrowType,
      PropertyCategoryIds.Nose,
      PropertyCategoryIds.MouthType,
      PropertyCategoryIds.HairStyle,
      PropertyCategoryIds.HairColor,
      PropertyCategoryIds.FacialHairType,
      PropertyCategoryIds.FacialHairColor,
      PropertyCategoryIds.OutfitType,
      PropertyCategoryIds.OutfitColor,
      PropertyCategoryIds.Accessory,
    ];
    return (propertyCategories.where((c) => order.contains(c.id)).toList()
      ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id))));
  }

  @override
  Future<RestoredData> performRestore() async {
    final restoredSvg = _initialSvg.isNotEmpty ? _initialSvg : drawAvatarSVG();
    return RestoredData(
      svg: restoredSvg,
      options: Map.from(_initialOptions),
    );
  }
}
