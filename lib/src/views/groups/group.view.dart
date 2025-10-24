import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';

class GroupView extends StatefulWidget {
  const GroupView(this.group, {super.key});

  final Group group;

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
