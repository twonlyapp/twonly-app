import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/services/avatars.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/memories/sticker_source_picker.view.dart';

class ModifyAvatarView extends StatefulWidget {
  const ModifyAvatarView({super.key});

  @override
  State<ModifyAvatarView> createState() => _ModifyAvatarViewState();
}

class _ModifyAvatarViewState extends State<ModifyAvatarView> {
  CustomAvatarInfo? _customAvatar;
  bool _loadingCustomAvatar = true;
  bool _processingCustomAvatar = false;
  bool _updatingAudience = false;

  @override
  void initState() {
    super.initState();
    _loadCustomAvatar();
  }

  Future<void> _loadCustomAvatar() async {
    try {
      final avatar = await RustApi.getCustomAvatar();
      if (mounted) setState(() => _customAvatar = avatar);
    } finally {
      if (mounted) setState(() => _loadingCustomAvatar = false);
    }
  }

  Future<void> _chooseCustomAvatar() async {
    if (_processingCustomAvatar) return;
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const StickerSourcePickerView(forAvatar: true),
      ),
    );
    if (!mounted || path == null) return;
    setState(() => _processingCustomAvatar = true);
    try {
      final avatar = await RustApi.createCustomAvatar(
        imagePath: path,
        acceptedContactsOnly: _customAvatar?.acceptedContactsOnly ?? true,
      );
      if (!mounted) return;
      setState(() => _customAvatar = avatar);
      userService.triggerUserUpdate();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.customAvatarCreateFailed)),
      );
    } finally {
      if (mounted) setState(() => _processingCustomAvatar = false);
    }
  }

  Future<void> _removeCustomAvatar() async {
    if (_processingCustomAvatar) return;
    setState(() => _processingCustomAvatar = true);
    try {
      final avatar = await RustApi.removeCustomAvatar();
      if (!mounted) return;
      setState(() => _customAvatar = avatar);
      userService.triggerUserUpdate();
    } finally {
      if (mounted) setState(() => _processingCustomAvatar = false);
    }
  }

  Future<void> _setCustomAvatarAudience(bool acceptedContactsOnly) async {
    if (_updatingAudience) return;
    setState(() => _updatingAudience = true);
    try {
      final avatar = await RustApi.setCustomAvatarAudience(
        acceptedContactsOnly: acceptedContactsOnly,
      );
      if (mounted) setState(() => _customAvatar = avatar);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.errorInternalError)),
      );
    } finally {
      if (mounted) setState(() => _updatingAudience = false);
    }
  }

  Future<void> _openAvatarMaker() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const _SvgAvatarEditorView()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsProfileCustomizeAvatar),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAvatarMakerCard(context),
              const SizedBox(height: 16),
              _buildPhotoAvatarCard(context),
              const SizedBox(height: 30),
            ],
          ),
          if (_processingCustomAvatar)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: ThreeRotatingDots(size: 36)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarMakerCard(BuildContext context) {
    final svg = userService.currentUser.avatarSvg;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.customAvatarSvgTab,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 150,
                  child: ColoredBox(
                    color: context.color.surfaceContainerHigh,
                    child: svg != null && svg.isNotEmpty
                        ? SvgPicture.string(svg)
                        : const Icon(Icons.person_outline, size: 72),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: MyButton(
                variant: MyButtonVariant.secondaryMiddle,
                onPressed: _openAvatarMaker,
                child: Text(context.lang.customAvatarCustomize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoAvatarCard(BuildContext context) {
    if (_loadingCustomAvatar) {
      return const Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 220,
          child: Center(child: ThreeRotatingDots(size: 32)),
        ),
      );
    }
    final avatar = _customAvatar;
    final hasPhoto = avatar?.webp != null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.customAvatarPhotoTab,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.lang.customAvatarExplanation,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.color.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 220,
                  child: ColoredBox(
                    color: context.color.surfaceContainerHigh,
                    child: hasPhoto
                        ? Image.memory(avatar!.webp!, fit: BoxFit.contain)
                        : const Icon(Icons.person_outline, size: 100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.lang.customAvatarAudience,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Center(
              child: DropdownButton<bool>(
                value: avatar?.acceptedContactsOnly ?? true,
                alignment: AlignmentDirectional.center,
                items: [
                  DropdownMenuItem(
                    value: true,
                    child: Center(
                      child: Text(
                        context.lang.customAvatarAcceptedOnly,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Center(
                      child: Text(
                        context.lang.customAvatarEveryone,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                onChanged: _updatingAudience
                    ? null
                    : (acceptedContactsOnly) {
                        if (acceptedContactsOnly != null) {
                          _setCustomAvatarAudience(acceptedContactsOnly);
                        }
                      },
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                MyButton(
                  variant: MyButtonVariant.secondaryMiddle,
                  onPressed: _processingCustomAvatar
                      ? null
                      : _chooseCustomAvatar,
                  child: Text(
                    hasPhoto
                        ? context.lang.customAvatarReplace
                        : context.lang.customAvatarCreate,
                  ),
                ),
                if (hasPhoto)
                  MyButton(
                    variant: MyButtonVariant.errorMiddle,
                    onPressed: _processingCustomAvatar
                        ? null
                        : _removeCustomAvatar,
                    child: Text(context.lang.customAvatarRemove),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SvgAvatarEditorView extends StatefulWidget {
  const _SvgAvatarEditorView();

  @override
  State<_SvgAvatarEditorView> createState() => _SvgAvatarEditorViewState();
}

class _SvgAvatarEditorViewState extends State<_SvgAvatarEditorView> {
  late final _CustomAvatarMakerController _avatarMakerController;

  @override
  void initState() {
    super.initState();
    final svg = userService.currentUser.avatarSvg;
    _avatarMakerController = svg != null && svg.isNotEmpty
        ? _CustomAvatarMakerController(svg: svg)
        : _CustomAvatarMakerController.defaultAvatar();
  }

  @override
  void dispose() {
    _avatarMakerController.dispose();
    super.dispose();
  }

  Future<void> _updateUserAvatar(String svg) async {
    await UserService.update(
      (user) => user
        ..avatarSvg = svg
        ..avatarCounter = user.avatarCounter + 1,
    );
  }

  Future<void> _storeAvatarAndExit() async {
    await _avatarMakerController.saveAvatarSVG();
    final svg = _avatarMakerController.getAvatarSVGSync();
    await _updateUserAvatar(svg);
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.avatarSaveChanges),
        actions: [
          FilledButton(
            onPressed: _storeAvatarAndExit,
            child: Text(context.lang.avatarSaveChangesStore),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.lang.avatarSaveChangesDiscard),
          ),
        ],
      ),
    );
  }

  AvatarMakerThemeData _theme(BuildContext context) {
    final colors = context.color;
    return AvatarMakerThemeData(
      boxDecoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
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

  @override
  Widget build(BuildContext context) {
    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_avatarMakerController.getAvatarSVGSync() !=
            userService.currentUser.avatarSvg) {
          final shouldPop = await _showBackDialog() ?? false;
          if (context.mounted && shouldPop) Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.lang.customAvatarSvgTab)),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AvatarMakerAvatar(
                  radius: 130,
                  backgroundColor: Colors.transparent,
                  controller: _avatarMakerController,
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
                        onPressed: _storeAvatarAndExit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.floppyDisk,
                              size: 16,
                            ),
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
                        onLongPress: _avatarMakerController.clearCustomizations,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.rotateLeft,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(context.lang.avatarCustomizeReset),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: AvatarMakerCustomizer(
                    scaffoldWidth: min(
                      600,
                      MediaQuery.of(context).size.width * 0.95,
                    ),
                    theme: _theme(context),
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
