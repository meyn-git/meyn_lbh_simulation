class TitleBuilder {
  final String name;
  final Map<String, dynamic> properties = {};
static final  indentation='    ';
  TitleBuilder(this.name) {
    validateName(name);
  }

  TitleBuilder appendProperty(String name, dynamic value) {
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
    //TODO fix endless loop when child property value points to its parent.
    String string = name;
    for (String propertyName in properties.keys) {
      var propertyValue = properties[propertyName];
      if (propertyValue != null) {
        string += '\n$indentation$propertyName: ';
        string += _multilineFormattedPropertyValue(propertyValue);
      }
    }
    return string;
  }

  /// Converts the property value to a string and indents this value
  /// if the value has multiple lines (e.g. a nested object)
  String _multilineFormattedPropertyValue(dynamic propertyValue) {
    String string='';
    var lines = _formattedPropertyValue(propertyValue).split('\n');
      for (String line in lines) {
        if (line==lines.first) {
          string += lines.first;
        } else {
          string += '\n$indentation$indentation$line';
        }
      }
    // }
    return string;
  }

  String _formattedPropertyValue(dynamic propertyValue) {
    if (propertyValue is Duration) {
      return _formattedDuration(propertyValue);
    } else {
      return propertyValue.toString();
    }
  }

  String _formattedDuration(Duration duration) {
    var durationString = duration.toString();
    return durationString.substring(0,durationString.length-5)+'s';
  }
}
