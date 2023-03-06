import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/authorization/authorization.dart';
import 'package:meyn_lbh_simulation/domain/site/site.dart';
import 'package:shouldly/shouldly.dart';
import 'package:given_when_then_unit_test/given_when_then_unit_test.dart';

void main() {
  given('AuthorizationService and initialized GetIt', () {
    GetIt.instance.registerSingleton<Sites>(Sites());
    GetIt.instance
        .registerSingleton<AuthorizationService>(AuthorizationService());
    GetIt.instance.registerSingleton<Player>(Player());
    var service = AuthorizationService();
    service.logout;
    when('calling login() with a trimmed password', () {
      then('login should be successful', () {
        service.login(name: 'nilsth', passWord: 'Maxiload');
      });
    });

    when('calling login() with a password starting with a space', () {
      then('login should be successful', () {
        Should.notThrowException(
            () => service.login(name: 'erikc', passWord: ' Maxiload'));
      });
    });

    when('calling login() with a password ending with a space', () {
      then('login should be successful', () {
        Should.notThrowException(
            () => service.login(name: 'erikc', passWord: 'Maxiload '));
      });
    });

    when('calling login() with a password ending with a spaces', () {
      then('login should be successful', () {
        Should.notThrowException(
            () => service.login(name: 'erikc', passWord: 'Maxiload  '));
      });
    });

    when('calling login() with a password surrounded with spaces', () {
      then('login should be successful', () {
        Should.notThrowException(
            () => service.login(name: 'erikc', passWord: ' Maxiload  '));
      });
    });
  });
}
