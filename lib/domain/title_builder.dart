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
        string += _propertyValueToString(propertyName);
      }
    }
    return string;
  }

  String _propertyValueToString(String propertyName) {
    String string='';
    var lines = properties[propertyName].toString().split('\n');
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
}
