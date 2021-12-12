/// A ISO88/ISO99 A [Site] is a production location/plant of one of out customers

class Site {
  final int meynLayoutNumber;
  final String organizationName;
  final String city;
  final String country;

  Site(
      {required this.meynLayoutNumber,
      required this.organizationName,
      required this.city,
      required this.country});

  @override
  String toString() {
    return '$meynLayoutNumber-$organizationName-$city-$country';
  }
}
