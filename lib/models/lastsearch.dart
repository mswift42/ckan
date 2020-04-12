import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// TODO Save and restore from both sources separately.

class LastSearchModel extends ChangeNotifier {
  final String lastSearchesFileCK = 'lastsearches.txt';
  final String lastSearchesFileBBCGF = 'lastSearchesbbcgf.txt';
  Set<String> _savedSearches = {};

  LastSearchModel() {
    lastSearches();
  }

  Future<void> lastSearches() async {
    readSearches().then((value) => _savedSearches = value.toSet());
  }

  Set<String> get searches => _savedSearches;

  void add(String search) {
    _savedSearches.add(search);
    writeSearches(_savedSearches.toList());
    notifyListeners();
  }

  void remove(String search) {
    _savedSearches.remove(search);
    writeSearches(_savedSearches.toList());
    notifyListeners();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$lastSearchesFileCK');
  }

  Future<File> writeSearches(List<String> searches) async {
    final file = await _localFile;
    return file.writeAsString(searches.join(','));
  }

  Future<List<String>> readSearches() async {
    try {
      final file = await _localFile;

      String contents = await file.readAsString();
      return contents.split(',');
    } catch (e) {
      print(e);
    }
    return null;
  }
}
