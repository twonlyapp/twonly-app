import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/userdata.dart';

class ContactAvatar extends StatelessWidget {
  final Contact? contact;
  final UserData? userData;
  final double? fontSize;

  const ContactAvatar(
      {super.key, this.contact, this.userData, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    String displayName = "";
    String? avatarSvg;

    if (contact != null) {
      displayName = getContactDisplayName(contact!);
      avatarSvg = contact!.avatarSvg;
    } else if (userData != null) {
      displayName = userData!.displayName;
      avatarSvg = userData!.avatarSvg;
    } else {
      return Container();
    }

    double proSize = (fontSize == null) ? 40 : (fontSize! * 2);

    if (avatarSvg != null) {
      return Container(
        constraints: BoxConstraints(
          minHeight: 2 * (fontSize ?? 20),
          minWidth: 2 * (fontSize ?? 20),
          maxWidth: 2 * (fontSize ?? 20),
          maxHeight: 2 * (fontSize ?? 20),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: SizedBox(
              height: proSize,
              width: proSize,
              child: Center(
                child: SvgPicture.string(
                  avatarSvg,
                  errorBuilder: (context, error, stackTrace) {
                    Logger("ui.avater").shout("$error");
                    return Container();
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Extract initials from the displayName
    List<String> nameParts = displayName.split(' ');
    String initials = nameParts.map((part) => part[0]).join().toUpperCase();

    if (initials.length > 2) {
      initials = initials[0] + initials[1];
    } else if (initials.length == 1) {
      initials = displayName[0] + displayName[1];
    }

    initials = initials.toUpperCase();

    // Generate a color based on the initials (you can customize this logic)
    Color avatarColor = _getColorFromUsername(
        displayName, Theme.of(context).brightness == Brightness.dark);

    Widget child = Text(
      initials,
      style: TextStyle(
        color: _getTextColor(avatarColor),
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ),
    );

    bool isPro = initials[0] == "T";

    return isPro
        ? //or 15.0
        Container(
            constraints: BoxConstraints(
              minHeight: 2 * (fontSize ?? 20),
              minWidth: 2 * (fontSize ?? 20),
              maxWidth: 2 * (fontSize ?? 20),
              maxHeight: 2 * (fontSize ?? 20),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  height: proSize,
                  width: proSize,
                  //padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: avatarColor,
                  child: Center(child: child),
                ),
              ),
            ),
          )
        : CircleAvatar(
            backgroundColor: avatarColor,
            radius: fontSize,
            child: child,
          );
  }

  Color _getTextColor(Color color) {
    double value = 100.0;
    // Ensure the value does not exceed the RGB limits
    int newRed = ((color.r * 255) - value).clamp(0, 255).round();
    int newGreen = (color.g * 255 - value).clamp(0, 255).round();
    int newBlue = (color.b * 255 - value).clamp(0, 255).round();

    return Color.fromARGB((color.a * 255).round(), newRed, newGreen, newBlue);
  }

  Color _getColorFromUsername(String displayName, bool isDarkMode) {
    // Define color lists for light and dark themes
    List<Color> lightColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    List<Color> darkColors = [
      const Color.fromARGB(255, 246, 227, 254), // Light Lavender
      const Color.fromARGB(255, 246, 216, 215), // Light Pink
      const Color.fromARGB(255, 226, 236, 235), // Light Teal
      const Color.fromARGB(255, 255, 224, 178), // Light Yellow
      const Color.fromARGB(255, 255, 182, 193), // Light Pink (Hot Pink)
      const Color.fromARGB(255, 173, 216, 230), // Light Blue
      const Color.fromARGB(255, 221, 160, 221), // Plum
      const Color.fromARGB(255, 255, 228, 196), // Bisque
      const Color.fromARGB(255, 240, 230, 140), // Khaki
      const Color.fromARGB(255, 255, 192, 203), // Pink
      const Color.fromARGB(255, 255, 218, 185), // Peach Puff
      const Color.fromARGB(255, 255, 160, 122), // Light Salmon
      const Color.fromARGB(255, 135, 206, 250), // Light Sky Blue
      const Color.fromARGB(255, 255, 228, 225), // Misty Rose
      const Color.fromARGB(255, 240, 248, 255), // Alice Blue
      const Color.fromARGB(255, 255, 250, 205), // Lemon Chiffon
      const Color.fromARGB(255, 255, 218, 185), // Peach Puff
    ];

    // Simple logic to generate a hash from initials
    int hash = displayName.codeUnits.fold(0, (prev, element) => prev + element);

    // Select the appropriate color list based on the current theme brightness
    List<Color> colors = isDarkMode ? darkColors : lightColors;

    // Use the hash to select a color from the list
    return colors[hash % colors.length];
  }
}
