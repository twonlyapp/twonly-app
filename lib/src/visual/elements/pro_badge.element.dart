import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.appColor(AppColor.premium),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.star,
            size: 10,
            color: context.appColor(AppColor.onWarning),
          ),
          const SizedBox(width: 4),
          Text(
            context.lang.backupCloudProBadge,
            style: TextStyle(
              fontSize: 10,
              color: context.appColor(AppColor.onWarning),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
