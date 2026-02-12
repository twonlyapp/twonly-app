// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/user_study/user_study_data_collection.dart';

class UserStudyQuestionnaireView extends StatefulWidget {
  const UserStudyQuestionnaireView({super.key});

  @override
  State<UserStudyQuestionnaireView> createState() =>
      _UserStudyQuestionnaireViewState();
}

class _UserStudyQuestionnaireViewState
    extends State<UserStudyQuestionnaireView> {
  final Map<String, dynamic> _responses = {
    'age': null,
    'education': null,
    'education_free': '',
    'vocational': null,
    'vocational_free': '',
    'enrolled': null,
    'study_program': '',
    'working': null,
    'work_field': '',
    'smartphone_2years': null,
    'comp_knowledge': null,
    'security_knowledge': null,
    'messengers': [],
    'is_release_mode': kReleaseMode,
  };

  final List<String> _messengerOptions = [
    'WhatsApp',
    'Signal',
    'Telegram',
    'Facebook Messenger',
    'iMessage',
    'Teams',
    'Viber',
    'Element',
    'Andere',
  ];

  Future<void> _submitData() async {
    await KeyValueStore.put(userStudySurveyKey, _responses);

    await updateUserdata((u) {
      // generate a random participants id to identify data send later while keeping the user anonym
      u
        ..userStudyParticipantsToken = getRandomString(25)
        ..askedForUserStudyPermission = true;
      return u;
    });

    await handleUserStudyUpload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vielen Dank für deine Teilnahme!')),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Befragung')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Demografische Daten'),
            _questionText('Wie alt bist du?'),
            _buildRadioList(
              [
                '18-22',
                '23-27',
                '28-32',
                '33-37',
                '38-42',
                '43-47',
                '48-52',
                '53-57',
                '58-62',
                '63-67',
                '68-72',
                '73-77',
                '77 oder älter',
                'Keine Angabe',
              ],
              'age',
            ),
            _questionText('Was ist dein höchster Schulabschluss?'),
            _buildRadioList(
              [
                'Noch in der Schule',
                'Hauptschulabschluss',
                'POS (Polytechnische Oberschule)',
                'Realschulabschluss',
                'Abitur / Hochschulreife',
                'Kein Abschluss',
                'Keine Angabe',
              ],
              'education',
            ),
            _buildTextField(
              'Freitext (optional)',
              (val) => _responses['education_free'] = val,
            ),
            _questionText('Was ist dein höchster beruflicher Abschluss?'),
            _buildRadioList(
              [
                'Berufsausbildung / Duales System',
                'Fachschulabschluss',
                'Fachschulabschluss (ehem. DDR)',
                'Bachelor',
                'Master',
                'Diplom',
                'Promotion (PhD)',
                'Kein beruflicher Abschluss',
                'Keine Angabe',
              ],
              'vocational',
            ),
            _buildTextField(
              'Freitext (optional)',
              (val) => _responses['vocational_free'] = val,
            ),
            _questionText(
              'Bist du derzeit in einem Studiengang eingeschrieben? (Bachelor, Master, Diplom, Staatsexamen, Magister)',
            ),
            _buildRadioList(['Ja', 'Nein', 'Keine Angabe'], 'enrolled'),
            _questionText('Wenn ja, welcher Studiengang?'),
            _buildTextField(
              'Studiengang eingeben',
              (val) => _responses['study_program'] = val,
            ),
            _questionText('Bist du derzeit berufstätig?'),
            _buildRadioList(['Ja', 'Nein', 'Keine Angabe'], 'working'),
            _questionText('Wenn ja, in welchem Bereich arbeiten Sie?'),
            _buildTextField(
              'Arbeitsbereich eingeben',
              (val) => _responses['work_field'] = val,
            ),
            const SizedBox(height: 30),
            // const Divider(),
            _sectionTitle('Technisches Wissen'),
            _questionText(
              'Nutzt du seit mehr als zwei Jahren ein Smartphone?',
            ),
            _buildRadioList(['Ja', 'Nein'], 'smartphone_2years'),
            _questionText(
              'Wie schätzt du deine allgemeinen Computerkenntnisse ein?',
            ),
            _buildRadioList(
              ['Anfänger', 'Mittel', 'Fortgeschritten'],
              'comp_knowledge',
            ),
            _questionText(
              'Wie schätzt du dein Wissen im Bereich IT-Sicherheit ein?',
            ),
            _buildRadioList(
              ['Anfänger', 'Mittel', 'Fortgeschritten'],
              'security_knowledge',
            ),
            _questionText(
              'Welche der folgenden Messenger hast du schon einmal benutzt?',
            ),
            ..._messengerOptions.map(
              (m) => CheckboxListTile(
                title: Text(m),
                visualDensity: const VisualDensity(vertical: -4),
                value: (_responses['messengers'] as List<dynamic>).contains(m),
                onChanged: (value) {
                  setState(() {
                    value!
                        ? _responses['messengers'].add(m)
                        : _responses['messengers'].remove(m);
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: FilledButton(
                onPressed: _submitData,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  child:
                      Text('Jetzt teilnehmen', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Hilfsmethoden für das UI
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _questionText(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 5),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildRadioList(List<String> options, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelText: 'Bitte wählen...',
        ),
        initialValue: _responses[key] as String?,
        items: options.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _responses[key] = val;
          });
        },
      ),
    );
  }

  Widget _buildTextField(String hint, void Function(String) onChanged) {
    return TextField(
      decoration:
          InputDecoration(hintText: hint, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }
}
