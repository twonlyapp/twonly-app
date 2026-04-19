import 'package:flutter/material.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/themes/light.dart';
import 'package:twonly/src/utils/misc.dart';

class UserDiscoveryDisabledComponent extends StatefulWidget {
  const UserDiscoveryDisabledComponent({required this.onUpdate, super.key});

  final VoidCallback onUpdate;

  @override
  State<UserDiscoveryDisabledComponent> createState() =>
      _UserDiscoveryDisabledComponentState();
}

class _UserDiscoveryDisabledComponentState
    extends State<UserDiscoveryDisabledComponent> {
  Future<void> initializeUserDiscoveryWithDefaultSettings() async {
    await UserDiscoveryService.initializeOrUpdate(
      threshold: 2,
      minimumRequiredImagesExchanged: 4,
    );
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ListView(
        children: [
          const SizedBox(height: 45),
          const Text(
            'twonly verzichten auf Telefonnummern, daher schlagen wir dir Freunde stattdessen über gemeinsame Kontakte vor – sicher und privat.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          RichText(
            text: TextSpan(
              children: formattedText(
                'Deine Freundesliste ist für *Fremde komplett unsichtbar*. Nur deine Freunde können Teile davon sehen – und zwar nur die Personen, mit denen sie selbst *gemeinsame Freunde* haben.',
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          const Text(
            'Du hast die Kontrolle',
            style: TextStyle(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Entscheide selbst, wer deine Freunde sehen darf. Du kannst deine Meinung jederzeit ändern oder bestimmte Personen verstecken.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 50),

          FilledButton(
            onPressed: initializeUserDiscoveryWithDefaultSettings,
            style: primaryColorButtonStyle.merge(
              FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              ),
            ),
            child: const Text('Mit Standardeinstellungen aktivieren'),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              onPressed: () {},
              style: secondaryGreyButtonStyle(context),
              child: const Text('Einstellungen anpassen'),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              onPressed: () {},
              style: secondaryGreyButtonStyle(context),
              child: const Text('Mehr erfahren'),
            ),
          ),
        ],
      ),
    );
  }
}
