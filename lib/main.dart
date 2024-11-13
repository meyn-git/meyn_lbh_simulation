import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/area/player.domain.dart';
import 'package:meyn_lbh_simulation/authorization/authorization.domain.dart';
import 'package:meyn_lbh_simulation/area/player.presentation.dart';
import 'package:meyn_lbh_simulation/authorization/login.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/site/site.dart';

void main() {
  GetIt.instance.registerSingleton<Sites>(Sites());
  GetIt.instance
      .registerSingleton<AuthorizationService>(AuthorizationService());
  GetIt.instance.registerSingleton<Player>(Player());

  runApp(const MyApp());
}

const applicationTitle = 'Meyn Live Bird Handling Simulator';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      var authorizationService = GetIt.instance<AuthorizationService>();
      authorizationService.login(name: 'nilsth', passWord: 'Maxiload');
    }
    return MaterialApp(
      title: applicationTitle,
      theme: createTheme(Brightness.light),
      darkTheme: createTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: kDebugMode ? const PlayerPage() : const LoginPage(),
    );
  }
}
