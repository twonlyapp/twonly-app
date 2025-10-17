import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

List<Widget> parseMarkdown(BuildContext context, String markdown) {
  final widgets = <Widget>[];
  // Split the string into lines
  final lines = markdown.split('\n');

  for (var line in lines) {
    line = line.trim();

    // Check for headers
    if (line.startsWith('# ')) {
      // widgets.add(Padding(
      //   padding: const EdgeInsets.all(8),
      //   child: Text(
      //     line.substring(2), // Remove the '# ' part
      //     textAlign: TextAlign.center,
      //     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      //   ),
      // ));
    } else if (line.startsWith('## ')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            line.substring(3), // Remove the '## ' part
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    // Check for bullet points
    else if (line.startsWith('- ')) {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Icon(
                Icons.brightness_1,
                size: 7,
                color: context.color.onSurface,
              ),
            ), // Bullet point icon
            const SizedBox(width: 8), // Space between bullet and text
            Expanded(child: Text(line.substring(2))), // Remove the '- ' part
          ],
        ),
      );
    } else {
      widgets.add(Text(line));
    }
  }

  return widgets;
}

class ChangeLogView extends StatefulWidget {
  const ChangeLogView({super.key, this.changeLog});

  final String? changeLog;

  @override
  State<ChangeLogView> createState() => _ChangeLogViewState();
}

class _ChangeLogViewState extends State<ChangeLogView> {
  String changeLog = '';
  bool hideChangeLog = false;

  @override
  void initState() {
    super.initState();
    if (widget.changeLog != null) {
      changeLog = widget.changeLog!;
    } else {
      unawaited(initAsync());
    }
  }

  Future<void> initAsync() async {
    changeLog = await rootBundle.loadString('CHANGELOG.md');
    final user = await getUser();
    if (user != null) {
      hideChangeLog = user.hideChangeLog;
    }
    setState(() {});
  }

  Future<void> _toggleAutoOpen(bool value) async {
    await updateUserdata((u) {
      u.hideChangeLog = !hideChangeLog;
      return u;
    });
    setState(() {
      hideChangeLog = !value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: parseMarkdown(context, changeLog),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.lang.openChangeLog),
            Switch(
              value: !hideChangeLog,
              onChanged: _toggleAutoOpen,
            ),
          ],
        ),
      ),
    );
  }
}
