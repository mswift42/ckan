import 'package:ckan/recipe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SourceModel extends ChangeNotifier {
  RecipeSource _activeSource;

  RecipeSource get active => _activeSource ?? _sources[0];

  set active(RecipeSource newSource) {
    _activeSource = newSource;
    notifyListeners();
  }

  final List<RecipeSource> _sources = [
    RecipeSource('Chefkoch'),
    RecipeSource('BBCGF'),
  ];

  List<RecipeSource> get sources => _sources;
}
