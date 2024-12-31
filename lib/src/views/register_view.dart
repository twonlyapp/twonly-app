import '../utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.callbackOnSuccess});

  final Function callbackOnSuccess;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(hintText) {
      return InputDecoration(hintText: hintText, fillColor: Colors.grey[400]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Connect!"),
      ),
      body: Padding(
          padding: EdgeInsets.all(10),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "You made the right decision using Connect which is like SnXpchat but encrypted using the Signal protocol.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Choice wisely, this username can't be changed. Only lowercase and numbers are allowed!",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: usernameController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                        12), // Limit to 12 characters
                    FilteringTextInputFormatter.allow(RegExp(
                        r'[a-z0-9]')), // Allow only lowercase letters and numbers
                  ],
                  decoration: getInputDecoration("Username")),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "To protect this small experimental project you need an invitation code! To get one just ask the right person!",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: inviteCodeController,
                  decoration: getInputDecoration("Invitation code")),
              const SizedBox(height: 25),
              Center(
                child: Text(
                  "Where is the password? There is none! So make a backup of your Connect identity in the settings or you will lose your access if you lose your device!",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                icon: Icon(Icons.group),
                onPressed: () async {
                  final success = await createNewUser(
                      usernameController.text, inviteCodeController.text);
                  if (success == null) {
                    widget.callbackOnSuccess();
                    return;
                  }
                  showAlertDialog(context, "Oh no!", success);
                },
                label: Text("Komm in die Gruppe!"),
              ),
              OutlinedButton.icon(
                  onPressed: () {
                    showAlertDialog(context, "Coming soon",
                        "This feature is not yet implemented! Just create a new account :/");
                  },
                  label: Text("Restore identity")),
              // MyButton(onTap: () {}, text: "Komm in die Gruppe!")
            ],
          )),
    );
  }
}

showAlertDialog(BuildContext context, String title, String content) {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
