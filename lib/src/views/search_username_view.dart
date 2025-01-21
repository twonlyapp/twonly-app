import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/utils.dart';
import 'package:twonly/src/views/register_view.dart';

class SearchUsernameView extends StatefulWidget {
  const SearchUsernameView({super.key});

  @override
  State<SearchUsernameView> createState() => _SearchUsernameView();
}

class _SearchUsernameView extends State<SearchUsernameView> {
  final TextEditingController searchUserName = TextEditingController();

  bool _isLoading = false;

  Future _addNewUser(BuildContext context) async {
    Timer timer = Timer(Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = true;
      });
    });

    final status = await addNewUser(searchUserName.text);

    timer.cancel();
    // loaderDelay.timeout(Duration(microseconds: 0));
    setState(() {
      _isLoading = false;
    });
    Logger("search_user_name").warning("Replace instead of pop");

    if (context.mounted) {
      if (status) {
        Navigator.pop(context);
      } else if (context.mounted) {
        showAlertDialog(
            context,
            AppLocalizations.of(context)!.searchUsernameNotFound,
            AppLocalizations.of(context)!
                .searchUsernameNotFoundLong(searchUserName.text));
      }
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(hintText) {
      final primaryColor =
          Theme.of(context).colorScheme.primary; // Get the primary color
      return InputDecoration(
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: BorderSide(color: primaryColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchUsernameTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                    onSubmitted: (_) {
                      _addNewUser(context);
                    },
                    controller: searchUserName,
                    decoration: getInputDecoration(
                        AppLocalizations.of(context)!.searchUsernameInput))),
            const SizedBox(height: 40),
            if (_isLoading) const Center(child: CircularProgressIndicator())
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
          onPressed: () {
            _addNewUser(context);
          },
          child: const Icon(Icons.arrow_right_rounded),
        ),
      ),
    );
  }
}
