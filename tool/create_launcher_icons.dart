import 'package:process_run/shell.dart';

void main() async {
  var shell = Shell(commentVerbose: true);
  await shell.run('''
    # Create launcher icons
    dart run flutter_launcher_icons
  ''');
}
