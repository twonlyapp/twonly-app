import 'package:twonly/src/model/contacts_model.dart';
import 'package:flutter/material.dart';

class ContactVerifyView extends StatefulWidget {
  const ContactVerifyView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ContactVerifyView> createState() => _ContactVerifyViewState();
}

class _ContactVerifyViewState extends State<ContactVerifyView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify ${widget.contact.displayName}"),
      ),
      body: ListView(
        children: [
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
