import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';

class AvatarCreator extends StatefulWidget {
  const AvatarCreator({super.key});

  @override
  State<AvatarCreator> createState() => _AvatarCreatorState();
}

class _AvatarCreatorState extends State<AvatarCreator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Avatar"),
        centerTitle: true,
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 25,
          ),
          SizedBox(
            height: 25,
          ),
          AvatarMakerAvatar(
            backgroundColor: Colors.grey[200],
            radius: 100,
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            children: [
              Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: Container(
                  height: 35,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text("Customize"),
                    onPressed: () => Navigator.push(context,
                        new MaterialPageRoute(builder: (context) => NewPage())),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}

class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    var _width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: AvatarMakerAvatar(
                  radius: 100,
                  backgroundColor: Colors.transparent,
                ),
              ),
              SizedBox(
                width: min(600, _width * 0.85),
                child: Row(
                  children: [
                    Text(
                      "Customize:",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Spacer(),
                    AvatarMakerSaveWidget(),
                    AvatarMakerRandomWidget(),
                    AvatarMakerResetWidget(),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 30),
                child: AvatarMakerCustomizer(
                  scaffoldWidth: min(600, _width * 0.85),
                  autosave: false,
                  theme: AvatarMakerThemeData(
                    boxDecoration: BoxDecoration(
                      boxShadow: [BoxShadow()],
                    ),
                    // primaryBgColor:
                    //     Theme.of(context).colorScheme.surfaceContainerLowest,
                    // secondaryBgColor:
                    //     const Color.fromARGB(255, 203, 203, 203),
                    // labelTextStyle: TextStyle(
                    //     color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
