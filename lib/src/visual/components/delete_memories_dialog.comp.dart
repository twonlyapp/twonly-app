import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

Future<bool?> showDeleteMemoriesDialog({
  required BuildContext context,
  required int count,
  required bool hasCloudBackup,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteMemoriesDialog(
      count: count,
      hasCloudBackup: hasCloudBackup,
    ),
  );
}

class DeleteMemoriesDialog extends StatelessWidget {
  const DeleteMemoriesDialog({
    required this.count,
    required this.hasCloudBackup,
    super.key,
  });

  final int count;
  final bool hasCloudBackup;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.deleteImageTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.lang.deleteMemoriesBody(count),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            if (hasCloudBackup) ...[
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.secondaryMiddle,
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.lang.deleteMemoriesLocalOnly),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.errorMiddle,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.lang.deleteMemoriesCompletely),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MyButton(
                variant: MyButtonVariant.text,
                onPressed: () => Navigator.pop(context),
                child: Text(context.lang.galleryCancel),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.secondaryMiddle,
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.lang.galleryCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.errorMiddle,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.lang.delete),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
