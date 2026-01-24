import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';

class ShowTitleText extends StatelessWidget {
  const ShowTitleText({
    required this.desc,
    required this.title,
    this.isLink = false,
    super.key,
  });
  final String title;
  final String desc;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: isLink ? 14 : 24,
      decoration: TextDecoration.none,
      shadows: const [
        Shadow(
          color: Color.fromARGB(122, 0, 0, 0),
          blurRadius: 5,
        ),
      ],
    );

    final boldTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.normal,
      fontSize: isLink ? 17 : 28,
    );

    return Positioned(
      right: 0,
      left: 0,
      top: 50,
      child: Column(
        children: [
          Text(
            desc,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
          Text(
            substringBy(title, isLink ? 30 : 20),
            textAlign: TextAlign.center,
            style: boldTextStyle, // Use the bold text style here
          ),
        ],
      ),
    );
  }
}
