import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';

void main() {
  runApp(MyApp());
}

const title = 'Meyn Live Bird Handling Simulator';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutWidget(),
    );
}


