import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/authorization/authorization.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';

import 'site.dart';

class Scenario {
  final Site site;
  final ProductDefinition productDefinition;
  final LiveBirdHandlingArea area;
  late MachineLayout layout = MachineLayout(
    machines: area.machines,
  );

  Scenario(
      {required this.site,
      required this.productDefinition,
      required this.area});

  Scenario.first()
      : this(
          site: firstSite,
          productDefinition: firstSite.productDefinitions.first,
          area: firstSite.productDefinitions.first.areas.first,
        );

  static Site get firstSite =>
      GetIt.instance<AuthorizationService>().sitesThatCanBeViewed.first;

  Scenario withNewArea() {
    var newAreas = productDefinition.areaFactory(productDefinition);
    var newArea = newAreas
        .firstWhere((newArea) => newArea.runtimeType == area.runtimeType);
    return Scenario(
        site: site, productDefinition: productDefinition, area: newArea);
  }
}
