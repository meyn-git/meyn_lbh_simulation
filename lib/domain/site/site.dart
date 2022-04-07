import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';
import 'package:meyn_lbh_simulation/domain/site/site_5021_ha_kylling_as.dart';

import 'site_5674_drobrimex.dart';
import 'site_7324_fileni.dart';
import 'site_8052_indrol.dart';

/// A ISO88/ISO99 A [Site] is a production location/plant of one of out customers

abstract class Site {
  final int meynLayoutNumber;
  final String organizationName;
  final String city;
  final String country;
  final List<ProductDefinition> productDefinitions;

  Site({
    required this.meynLayoutNumber,
    required this.organizationName,
    required this.city,
    required this.country,
    required this.productDefinitions,
  });

  List<Scenario> get scenarios {
    List<Scenario> scenarios = [];
    for (var productDefinition in productDefinitions) {
      for (var area in productDefinition.areas) {
        var scenario = Scenario(
          site: this,
          productDefinition: productDefinition,
          area: area,
        );
        scenarios.add(scenario);
      }
    }
    return scenarios;
  }

  /// converts the [meynLayoutNumber] to a 4 digit string
  /// (with optional leading 0's)
  get meynLayoutCode => meynLayoutNumber.toString().padLeft(4, '0');

  @override
  String toString() {
    return '$meynLayoutNumber-$organizationName-$city-$country';
  }
}

class Sites extends DelegatingList<Site> {
  Sites()
      : super([
          DobrimexSite(),
          IndrolSite(),
          FileniSite(),
          HaKyllingAsSite(),
        ]);
}
