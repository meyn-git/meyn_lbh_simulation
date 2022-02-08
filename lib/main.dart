import 'package:flutter/material.dart';

import 'gui/player.dart';

void main() {
  runApp(MyApp());
}

const title = 'Meyn Live Bird Handling Simulator (no rights)';
const meynColor = Color.fromRGBO(0, 118, 90, 1);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: _createThemeData(),
      home: PlayerWidget(),
    );
  }

  ThemeData _createThemeData() {
    return ThemeData(
      primarySwatch: _createMeynMaterialColor(),
    );
  }

  MaterialColor _createMeynMaterialColor() {
    return MaterialColor(meynColor.value, {
      50: meynColor.withOpacity(0.05),
      100: meynColor.withOpacity(0.1),
      200: meynColor.withOpacity(0.2),
      300: meynColor.withOpacity(0.3),
      400: meynColor.withOpacity(0.4),
      500: meynColor.withOpacity(0.5),
      600: meynColor.withOpacity(0.6),
      700: meynColor.withOpacity(0.7),
      800: meynColor.withOpacity(0.8),
      900: meynColor.withOpacity(0.9),
    });
  }
}

