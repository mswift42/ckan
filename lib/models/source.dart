import 'package:ckan/recipe_service.dart';
import 'package:flutter/material.dart';

class Source {
  static const _sources = [
    RecipeSource('Chefkoch'),
    RecipeSource('BBCGF'),
  ];

  static get sources => _sources;
}
