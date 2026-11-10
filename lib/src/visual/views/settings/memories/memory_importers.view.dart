import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/memory_importers.comp.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

/// Settings → Memories → Import from other apps.
class MemoryImportersView extends StatelessWidget {
  const MemoryImportersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.memoryImporterFromOtherApps)),
      body: const SettingsList(
        padding: EdgeInsets.all(24),
        children: [MemoryImportersSection()],
      ),
    );
  }
}
