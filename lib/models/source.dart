import 'package:ckan/recipe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Source extends ChangeNotifier {
  RecipeSource _activeSource;

  RecipeSource get source => _activeSource;

  set source(RecipeSource newSource) {
    _activeSource = newSource;
    notifyListeners();
  }

  static const _sources = [
    RecipeSource('Chefkoch'),
    RecipeSource('BBCGF'),
  ];

  static get sources => _sources;
}
