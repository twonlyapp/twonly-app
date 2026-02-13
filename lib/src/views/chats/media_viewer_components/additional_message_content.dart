import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdditionalMessageContent extends StatelessWidget {
  const AdditionalMessageContent(this.message, {super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    if (message.additionalMessageData == null) return Container();
    try {
      final data =
          AdditionalMessageData.fromBuffer(message.additionalMessageData!);

      switch (data.type) {
        case AdditionalMessageData_Type.LINK:
          if (!data.link.startsWith('http://') &&
              !data.link.startsWith('https://')) {
            return Container();
          }
          return Positioned(
            bottom: 150,
            right: 0,
            left: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.shareFromSquare),
                  onPressed: () => launchUrlString(data.link),
                  label: Text(
                    substringBy(
                      data.link
                          .replaceAll('http://', '')
                          .replaceAll('https://', ''),
                      30,
                    ),
                  ),
                ),
              ],
            ),
          );
        // ignore: no_default_cases
        default:
      }
      // ignore: empty_catches
    } catch (e) {}
    return Container();
  }
}
