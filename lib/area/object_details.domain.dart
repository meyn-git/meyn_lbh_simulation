import 'package:meyn_lbh_simulation/area/name.domain.domain.dart';

class ObjectDetails {
  final String name;
  final Map<String, dynamic> properties = {};
  static const indentation = '    ';
  ObjectDetails(this.name) {
    validateName(name);
  }

  ObjectDetails appendProperty(String name, dynamic value) {
    validateName(name);
    properties[name] = value;
    return this;
  }

  void validateName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('May not be empty', 'name');
    }
  }

  @override
  String toString() {
    return objectToString(1);
  }

  String objectToString(int indentations) {
    String string = name;
    string += '\n';
    string += propertiesToString(indentations);
    return string;
  }

  String propertiesToString(int indentations) {
    //TODO fix endless loop when child property value points to its parent.
    var string = '';
    for (var propertyEntry in properties.entries) {
      if (propertyEntry.value != null) {
        if (string.isNotEmpty) {
          string += '\n';
        }
        string += propertyToString(propertyEntry, indentations);
      }
    }
    return string;
  }

  String propertyToString(
    MapEntry<String, dynamic> propertyEntry,
    int indentations,
  ) {
    return '${indentation * indentations}${propertyEntry.key}: '
        '${_multilineFormattedPropertyValue(propertyEntry.value, indentations + 1)}';
  }

  /// Converts the property value to a string and indents this value
  /// if the value has multiple lines (e.g. a nested object)
  String _multilineFormattedPropertyValue(
    dynamic propertyValue,
    int indentations,
  ) {
    var lines = _formattedPropertyValue(propertyValue).split('\n');
    if (lines.length == 1) {
      return lines.first;
    } else {
      String string = '';
      for (String line in lines) {
        string += '\n${indentation * indentations}$line';
      }
      return string;
    }
  }

  String _formattedPropertyValue(dynamic propertyValue) {
    if (propertyValue is Iterable) {
      return propertyValue
          .map((element) => _formattedPropertyValue(element))
          .join('\n');
    }
    if (propertyValue is Duration) {
      return _formattedDuration(propertyValue);
    }
    if (propertyValue is Detailable) {
      return propertyValue.objectDetails.toString();
    }
    if (propertyValue is Enum) {
      return _formatedEnum(propertyValue);
    }
    return propertyValue.toString();
  }

  String _formattedDuration(Duration duration) {
    var durationString = duration.toString();
    return '${durationString.substring(0, durationString.length - 5)}s';
  }

  String _formatedEnum(Enum propertyValue) =>
      propertyValue.toString().split('.').last;
}

abstract class Detailable implements Namable {
  ObjectDetails get objectDetails;
}
