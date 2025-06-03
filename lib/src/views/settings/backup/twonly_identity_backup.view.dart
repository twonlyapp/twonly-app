import 'package:flutter/material.dart';

class TwonlyIdentityBackupView extends StatefulWidget {
  const TwonlyIdentityBackupView({super.key});

  @override
  State<TwonlyIdentityBackupView> createState() =>
      _TwonlyIdentityBackupViewState();
}

class _TwonlyIdentityBackupViewState extends State<TwonlyIdentityBackupView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("twonly-Identity Backup"),
      ),
      body: ListView(children: [
        Text(
            'Backup of your twonly-Identity. As twonly does not have any second factor like your phone number or email, this backup contains your twonly-Identity. If you lose your device, the only option to recover is with the twonly-ID Backup. This backup will be protected by a password chosen by you in the next step and anonymously uploaded to the twonly servers. Read more [here](https://twonly.eu/s/backup).'),
      ]),
    );
  }
}
