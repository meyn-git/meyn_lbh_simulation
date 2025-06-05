import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/site/scenario.domain.dart';
import 'package:meyn_lbh_simulation/site/site_0000_keskinoglu.domain.dart';
import 'package:meyn_lbh_simulation/site/site_1112_senpilic_gida_santic.domain.dart';
import 'package:meyn_lbh_simulation/site/site_1203_abalioglu.domain.dart';
import 'package:meyn_lbh_simulation/site/site_4054_taravis_sarvar.domain.dart';
import 'package:meyn_lbh_simulation/site/site_4649_gut_bergmark.domain.dart';
import 'package:meyn_lbh_simulation/site/site_5021_ha_kylling_as.domain.dart';
import 'package:meyn_lbh_simulation/site/site_5246_nortura_haerland.domain.dart';
import 'package:meyn_lbh_simulation/site/site_5836_van_der_linden.domain.dart';
import 'package:meyn_lbh_simulation/site/site_5959_schildermans.dart';
import 'package:meyn_lbh_simulation/site/site_7524_florida_spain.domain.dart';
import 'package:meyn_lbh_simulation/site/site_7696_dabe.domain.dart';
import 'package:meyn_lbh_simulation/site/site_0000_berika.domain.dart';
import 'package:meyn_lbh_simulation/site/site_8199_borgmeier.domain.dart';
import 'package:meyn_lbh_simulation/site/site_8395_lopez.domain.dart';
import 'package:meyn_lbh_simulation/site/site_9110_indykpol_ldc.domain.dart';
import 'package:meyn_lbh_simulation/site/site_9164_micarna.dart';
import 'package:meyn_lbh_simulation/site/site_9423_wech.domain.dart';

import 'site_5674_drobrimex.domain.dart';
import 'site_7324_fileni.domain.dart';
import 'site_8052_indrol.domain.dart';

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
        AbaliogluSite(),
        IndrolSite(),
        FloridaSite(),
        WechSite(),
        IndykpolLdcSite(),
        SchildermansSite(),
        BerikaSite(),
        MicarnaSite(),
        KeskinogluSite(),
        SenpelicSite(),
        HaKyllingAsSite(),
        BorgmeierSite(),
        GutBergmarkSite(),
        VanDerLindenSite(),
        LopezSite(),
        HaerlandSite(),
        TaravisSite(),
        FileniSite(),
        DobrimexSite(),
        DabeSite(),
      ]);
}
