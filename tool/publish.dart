import 'package:process_run/process_run.dart';
import 'package:process_run/shell.dart';

main() async {
  var shell = Shell();
  await shell.run('''
    # Build web files
    flutter build web
  
    # Remove old directories in: ..\\meyn_lbh_simulation_web
    FOR /d %a IN ("..\\meyn_lbh_simulation_web\\*.*") DO IF /i NOT "%~nxa"==".git" RD /S /Q "%a"
 
    # Remove old files in: ..\\meyn_lbh_simulation_web
    DEL "..\\meyn_lbh_simulation_web\\*.*" /Q

    # Copy build files to: ..\\meyn_lbh_simulation_web
    XCOPY ".\\build\\web" "..\\meyn_lbh_simulation_web" /S
  ''');

  shell=Shell(workingDirectory: '..\\meyn_lbh_simulation_web');
  await shell.run('''
    # Add all files to git
    git add .
  
    # Commit to git
    git commit -m "Generated by meyn_lbh_simulation/tool/publish.dart"
 
    # Push to git
    git push

    @echo Published on: https://meyn-git.github.io/meyn_lbh_simulation_web
  ''');

}
