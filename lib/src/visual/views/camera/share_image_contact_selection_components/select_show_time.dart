import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class SelectShowTime extends StatefulWidget {
  const SelectShowTime({
    required this.initialItem,
    required this.setMaxShowTime,
    required this.options,
    super.key,
  });

  final int initialItem;
  final void Function(int?, bool) setMaxShowTime;
  final List<int?> options;

  @override
  State<SelectShowTime> createState() => _SelectShowTimeState();
}

class _SelectShowTimeState extends State<SelectShowTime> {
  bool _storeAsDefault = false;
  int? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 6),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey,
              ),
              height: 3,
              width: 60,
            ),
            Expanded(
              child: CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: widget.initialItem,
                ),
                onSelectedItemChanged: (selectedItem) {
                  _selectedItem = selectedItem;
                  widget.setMaxShowTime(
                    widget.options[selectedItem],
                    _storeAsDefault,
                  );
                },
                children: widget.options.map((e) {
                  return Center(
                    child: Text(e == null ? '∞' : '${e ~/ 1000}s'),
                  );
                }).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _storeAsDefault,
                  onChanged: (value) => setState(() {
                    _storeAsDefault = !_storeAsDefault;
                    if (_selectedItem != null) {
                      widget.setMaxShowTime(
                        widget.options[_selectedItem!],
                        _storeAsDefault,
                      );
                    }
                  }),
                ),
                Text(context.lang.storeAsDefault),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
