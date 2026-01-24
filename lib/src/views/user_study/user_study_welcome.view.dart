import 'package:flutter/material.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/user_study/user_study_questionnaire.view.dart';

class UserStudyWelcomeView extends StatefulWidget {
  const UserStudyWelcomeView({super.key, this.wasOpenedAutomatic = false});

  final bool wasOpenedAutomatic;

  @override
  State<UserStudyWelcomeView> createState() => _UserStudyWelcomeViewState();
}

class _UserStudyWelcomeViewState extends State<UserStudyWelcomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teilnahme an Nutzerstudie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Es dauert nur ein paar Minuten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Im Rahmen meiner Masterarbeit möchte ich die Benutzerfreundlichkeit von anonymen und dezentralen Messenger-Diensten verbessern.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Zu diesem Zweck werden in den nächsten Monaten verschiedene Änderungen an der App vorgenommen. Um die Wirksamkeit der Änderungen zu messen, möchte ich einige Daten über deine Nutzung der App sammeln sowie eine kurze Befragung durchführen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Die Daten bestehen ausschließlich aus Zahlen, z. B. Anzahl deiner Kontakte. Alle Daten werden anonym übermittelt und können nicht mit deinem Benutzerkonto verknüpft werden.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Die Masterarbeit und damit die Nutzerstudie wird bis September durchgeführt. Nach Abschluss erhältst du eine Benachrichtigung und wirst über die Ergebnisse informiert.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const UserStudyQuestionnaire();
                      },
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  child: Text(
                    'Weiter zur Befragung',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (widget.wasOpenedAutomatic)
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Frag mich später noch mal',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (widget.wasOpenedAutomatic)
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await updateUserdata((u) {
                      u.askedForUserStudyPermission = true;
                      return u;
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Nicht mehr anzeigen',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'PS: twonly ist Open Source, wenn du also genau wissen willst, welche Daten übertragen werden, schau dir einfach die Datei "lib/src/views/user_study/user_study_data_collection.dart" im Repository an :).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
