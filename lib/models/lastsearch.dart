import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../recipe_service.dart';

// TODO Save and restore from both sources separately.

class LastSearchModel with ChangeNotifier {
  final RecipeSource activeSoruce = sources[0];
  final String lastSearchesFileCK = 'lastsearches.txt';
  final String lastSearchesFileBBCGF = 'lastSearchesbbcgf.txt';
  Set<String> _savedSearches = {};

  LastSearchModel() {
    lastSearches(activeSoruce);
  }

  Future<void> lastSearches(RecipeSource source) async {
    readSearches(source).then((value) => _savedSearches = value.toSet());
  }

  Set<String> get searches => _savedSearches;

  void add(String search, RecipeSource source) {
    _savedSearches.add(search);
    writeSearches(_savedSearches.toList(), source);
    notifyListeners();
  }

  void remove(String search) {
    _savedSearches.remove(search);
    writeSearches(_savedSearches.toList(), activeSoruce);
    notifyListeners();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFileCK async {
    final path = await _localPath;
    return File('$path/$lastSearchesFileCK');
  }

  Future<File> get _localFileBBCGF async {
    final path = await _localPath;
    return File('$path/$lastSearchesFileBBCGF');
  }

  Future<File> writeSearches(List<String> searches, RecipeSource source) async {
    switch (source.name) {
      case 'Chefkoch':
        final file = await _localFileBBCGF;
        return file.writeAsString(searches.join(','));
        break;
      default:
        final file = await _localFileCK;
        return file.writeAsString(searches.join(','));
    }
  }

  Future<List<String>> readSearches(RecipeSource source) async {
    try {
      switch (source.name) {
        case 'Chefkoch':
          final file = await _localFileBBCGF;
          String contents = await file.readAsString();
          return contents?.split(',') ?? [];
          break;
        default:
          final file = await _localFileCK;
          String contents = await file.readAsString();
          return contents?.split(',') ?? [];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}
