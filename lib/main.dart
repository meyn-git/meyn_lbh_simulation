import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/authorization/authorization.dart';
import 'package:meyn_lbh_simulation/gui/login/login.dart';

import 'domain/site/site.dart';
import 'gui/area/player.dart';

void main() {
  GetIt.instance.registerSingleton<Sites>(Sites());
  GetIt.instance.registerSingleton<AuthorizationService>(AuthorizationService());
  GetIt.instance.registerSingleton<Player>(Player());

  runApp(const MyApp());
}

const title = 'Meyn Live Bird Handling Simulator';
const meynColor = Color.fromRGBO(0, 118, 90, 1);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: _createThemeData(),
      home: const LoginPage(),
      // const PlayerPage(),
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
