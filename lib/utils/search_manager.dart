import 'dart:async';

class SearchState {
  final String query;
  final List<Map<String, dynamic>> results;

  SearchState({required this.query, required this.results});
}

class SearchManager {
  final _searchController = StreamController<SearchState>.broadcast();

  Stream<SearchState> get searchStream => _searchController.stream;

  void updateSearch(String query, List<Map<String, dynamic>> results) {
    _searchController.add(SearchState(query: query, results: results));
  }

  void dispose() {
    _searchController.close();
  }
}
