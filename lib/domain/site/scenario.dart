import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';

import 'site.dart';

class Scenario {
  final Site site;
  final ProductDefinition productDefinition;
  final LiveBirdHandlingArea area;

  Scenario(
      {required this.site,
      required this.productDefinition,
      required this.area});

  Scenario.first(List<Site> sites)
      : this(
          site: sites.first,
          productDefinition: sites.first.productDefinitions.first,
          area: sites.first.productDefinitions.first.areas.first,
        );

  Scenario withNewArea() {
    var newAreas = productDefinition.areaFactory(productDefinition);
    var newArea = newAreas
        .firstWhere((newArea) => newArea.runtimeType == area.runtimeType);
    return Scenario(
        site: site, productDefinition: productDefinition, area: newArea);
  }
}
