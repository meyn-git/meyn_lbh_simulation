import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';
import 'package:meyn_lbh_simulation/domain/site/site.dart';

class AuthorizationService {
  final List<User> _users = UserFactory().createAll();
  User? _loggedInUser;

  get isAdmin => _loggedInUser == null ? false : _loggedInUser!.isAdmin;

  void login({
    required String name,
    required String passWord,
  }) {
    /// TODO add delay after 3 failed attempts to protect against [brute force attack](https://en.wikipedia.org/wiki/Brute-force_attack)
    var foundUser = _users.firstWhereOrNull(
        (user) => _nameMatches(user, name) && _passwordMatches(user, passWord));
    if (foundUser == null) {
      if (!_users.any((user) => _nameMatches(user, name))) {
        throw LoginException('Login failed: Invalid user name.');
      }
      if (!_users.any((user) => _passwordMatches(user, passWord))) {
        throw LoginException('Login failed: Invalid password.');
      }
      if (sitesThatCanBeViewed.isNotEmpty) {
        throw LoginException(
            'Login failed: You are not allowed to view anything.');
      }
    } else {
      _loggedInUser = foundUser;
      var player = GetIt.instance<Player>();
      player.scenario = Scenario.first();
      player.play();
    }
  }

  bool _passwordMatches(User user, String passWord) =>
      user.password == passWord;

  bool _nameMatches(User user, String name) =>
      user.name.toLowerCase() == name.toLowerCase();

  List<Site> get sitesThatCanBeViewed =>
      _loggedInUser == null ? [] : _loggedInUser!.sitesThatCanBeViewed;

  void logout() {
    _loggedInUser = null;
    var player = GetIt.instance<Player>();
    player.pause();
    player.scenario = null;
  }
}

class LoginException implements Exception {
  String message;

  LoginException(this.message);
}

class User {
  final String name;
  final String password;
  final List<Site> sitesThatCanBeViewed;
  final bool isAdmin;

  User({
    required this.name,
    required this.password,
    required this.isAdmin,
    required this.sitesThatCanBeViewed,
  });
}

class UserFactory {
  List<User> createAll() {
    List<User> _users = [];

    _users.add(_createAdminUser(name: 'massimoz', password: 'Maxiload'));
    _users.add(_createAdminUser(name: 'nilsth', password: 'Maxiload'));
    _users.add(_createAdminUser(name: 'wietsel', password: 'Maxiload'));
    _users.addAll(_createSiteUsers());
    return _users;
  }

  Sites get sites => GetIt.instance<Sites>();

  User _createAdminUser({
    required String name,
    required String password,
  }) =>
      User(
        name: name,
        password: password,
        isAdmin: true,
        sitesThatCanBeViewed: sites,
      );

  Iterable<User> _createSiteUsers() => sites.map((site) => User(
      name: site.organizationName.trim().toLowerCase(),
      password: site.meynLayoutCode,
      isAdmin: false,
      sitesThatCanBeViewed: [site]));
}
