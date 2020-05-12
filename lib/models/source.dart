import 'package:ckan/recipe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SourceModel with ChangeNotifier {
  RecipeSource _activeSource;

  RecipeSource get active => _activeSource ?? sources[0];

  set active(RecipeSource newSource) {
    _activeSource = newSource;
    notifyListeners();
  }
}
