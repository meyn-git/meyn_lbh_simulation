import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/site.dart';

class Scenario {
  final Site site;
  final ProductDefinition productDefinition;
  final LiveBirdHandlingArea area;

  Scenario(
      {required this.site,
      required this.productDefinition,
      required this.area});

  Scenario.first()
      : this(
          site: Sites()[0],
          productDefinition: Sites()[0].productDefinitions[0],
          area: Sites()[0].productDefinitions[0].areas[0],
        );

  Scenario withNewArea() {
    var newAreas=productDefinition.areaFactory(productDefinition);
    var newArea=newAreas.firstWhere((newArea) => newArea.runtimeType == area.runtimeType);
    return Scenario(site: site, productDefinition: productDefinition, area: newArea);
  }

  String get nameWithoutSite => '$area-$productDefinition';

  String get nameWithSite => '$site-$nameWithoutSite';
}