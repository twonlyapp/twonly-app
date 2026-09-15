import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/utils/qr.utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invalid QR profile links return a visible failure status', () async {
    final result = await QrCodeUtils.handleQrCodeLink(
      '${QrCodeUtils.linkPrefix}not-a-valid-profile',
    );

    expect(result.status, QrCodeLinkStatus.invalid);
    expect(result.profile, isNull);
    expect(result.contact, isNull);
  });

  testWidgets('shared URLs are awaited by the common URL handler', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    Uri? receivedUri;
    var callbackFinished = false;
    await handleIntentSharedFile(
      context,
      [
        SharedFile(
          value: 'https://me.twonly.eu/alice#public-key',
          type: SharedMediaType.URL,
        ),
      ],
      (uri) async {
        receivedUri = uri;
        await Future<void>.value();
        callbackFinished = true;
      },
      (_, _) {},
    );

    expect(receivedUri, Uri.parse('https://me.twonly.eu/alice#public-key'));
    expect(callbackFinished, isTrue);
  });
}
