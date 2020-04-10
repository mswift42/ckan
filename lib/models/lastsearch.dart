import 'package:ckan/last_search_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LastSearchModel extends ChangeNotifier {
  List<String> _savedSearches = [];
  var _searchService = LastSearchService();
  LastSearchModel() {
    lastSearches();
  }

  Future<void> lastSearches() async {
    _searchService.readSearches().then((value) => _savedSearches = value);
  }

  List<String> get searches => _savedSearches;

  void add(String search) {
    _savedSearches.add(search);
    _searchService.writeSearches(_savedSearches);
    notifyListeners();
  }

  void remove(String search) {
    _savedSearches.remove(search);
    _searchService.writeSearches(_savedSearches);
    notifyListeners();
  }
}
