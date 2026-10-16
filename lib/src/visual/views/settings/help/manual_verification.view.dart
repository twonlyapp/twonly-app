import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_success_dialog.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class ManualVerificationView extends StatefulWidget {
  const ManualVerificationView({required this.contact, super.key});

  final Contact contact;

  @override
  State<ManualVerificationView> createState() => _ManualVerificationViewState();
}

class _ManualVerificationViewState extends State<ManualVerificationView> {
  late Future<String?> _safetyNumber;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSafetyNumber();
  }

  void _loadSafetyNumber() {
    _safetyNumber = RustSignal.getSafetyNumber(
      contactId: widget.contact.userId,
    );
  }

  Future<void> _markAsVerified() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    await twonlyDB.keyVerificationDao.addKeyVerification(
      widget.contact.userId,
      VerificationType.manual,
    );

    if (!mounted) return;
    final displayName = getContactDisplayName(widget.contact);
    await VerificationSuccessDialog.show(
      context,
      widget.contact,
      message: context.lang.manualVerificationSuccess(displayName),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = getContactDisplayName(widget.contact);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manualVerificationTitle),
      ),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _safetyNumber,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _SafetyNumberError(
                message: context.lang.manualVerificationLoadFailed,
                onRetry: () => setState(_loadSafetyNumber),
              );
            }

            final safetyNumber = snapshot.data;
            if (safetyNumber == null) {
              return _SafetyNumberError(
                title: context.lang.manualVerificationMissingKeyTitle,
                message: context.lang.manualVerificationMissingKeyDescription(
                  displayName,
                ),
                onRetry: () => setState(_loadSafetyNumber),
              );
            }

            return _SafetyNumberContent(
              safetyNumber: safetyNumber,
              description: context.lang.manualVerificationDescription(
                displayName,
              ),
              isSaving: _isSaving,
              onVerify: _markAsVerified,
            );
          },
        ),
      ),
    );
  }
}

class _SafetyNumberContent extends StatelessWidget {
  const _SafetyNumberContent({
    required this.safetyNumber,
    required this.description,
    required this.isSaving,
    required this.onVerify,
  });

  final String safetyNumber;
  final String description;
  final bool isSaving;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final groups = <String>[
      for (var offset = 0; offset < safetyNumber.length; offset += 5)
        safetyNumber.substring(offset, offset + 5),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.fingerprint,
                      size: 42,
                      color: context.color.onPrimaryContainer,
                    ),
                    const SizedBox(height: 28),
                    for (var row = 0; row < 3; row++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final group in groups.skip(row * 4).take(4))
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  group,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.color.onPrimaryContainer,
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.8,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (row < 2) const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 28),
                    IntrinsicWidth(
                      child: MyButton(
                        variant: MyButtonVariant.primaryMiddle,
                        onPressed: isSaving ? null : onVerify,
                        child: isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.lang.manualVerificationMarkVerified,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.color.onSurfaceVariant,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SafetyNumberError extends StatelessWidget {
  const _SafetyNumberError({
    required this.message,
    required this.onRetry,
    this.title,
  });

  final String? title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.key_off_rounded,
                size: 54,
                color: context.color.onSurfaceVariant,
              ),
              if (title != null) ...[
                const SizedBox(height: 20),
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.color.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              MyButton(
                variant: MyButtonVariant.secondaryMiddle,
                onPressed: onRetry,
                child: Text(context.lang.manualVerificationRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
