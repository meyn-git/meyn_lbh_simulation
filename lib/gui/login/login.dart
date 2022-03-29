import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/authorization/authorization.dart';
import 'package:meyn_lbh_simulation/gui/area/player.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  String loginException='';

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Please login"),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (loginException.isNotEmpty) Text(loginException, style: TextStyle(color: Theme.of(context).errorColor),),
                  if (loginException.isNotEmpty) const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: nameController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Name',
                          hintText: 'Enter your given login name'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, right: 15.0, top: 15, bottom: 0),
                    //padding: EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: passwordController,
                      textInputAction: TextInputAction.go,
                      onSubmitted:(_)  {
                        _login(context);
                      },
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                          hintText: 'Enter your given password'),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _login(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: 25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _login(BuildContext context) {
     setState(() {
      var authorizationService =
      GetIt.instance<AuthorizationService>();
      try {
        authorizationService.login(
            name: nameController.text,
            passWord: passwordController.text);
        loginException='';
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const PlayerPage()));
      } on LoginException catch (e) {
        loginException=e.message;
      }
    });
  }
}
