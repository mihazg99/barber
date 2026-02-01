import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/inventory/presentation/widgets/search_type_toggle.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchNotifier extends BaseNotifier<SearchType, String> {
  final Ref _ref;
  SearchType _currentSearchType = SearchType.items;
  String _currentQuery = '';

  SearchNotifier(this._ref);

  SearchType get currentSearchType => _currentSearchType;
  String get currentQuery => _currentQuery;

  void setSearchType(SearchType searchType) {
    _currentSearchType = searchType;
    _currentQuery = '';
    setData(searchType);
    _clearSearch();
  }

  void setSearchQuery(String query) {
    _currentQuery = query;
    _performSearch();
  }

  void _performSearch() {
    if (_currentQuery.isEmpty) {
      _clearSearch();
      return;
    }

    switch (_currentSearchType) {
      case SearchType.items:
        Future.microtask(() {
          _ref.read(itemNotifierProvider.notifier).searchItemsByName(_currentQuery);
        });
        break;
      case SearchType.boxes:
        Future.microtask(() {
          _ref.read(boxNotifierProvider.notifier).searchBoxesByLabel(_currentQuery);
        });
        break;
      case SearchType.locations:
        Future.microtask(() {
          _ref.read(locationNotifierProvider.notifier).searchLocationsByName(_currentQuery);
        });
        break;
    }
  }

  void _clearSearch() {
    switch (_currentSearchType) {
      case SearchType.items:
        Future.microtask(() {
          _ref.read(itemNotifierProvider.notifier).getAllItems();
        });
        break;
      case SearchType.boxes:
        Future.microtask(() {
          _ref.read(boxNotifierProvider.notifier).getAllBoxes();
        });
        break;
      case SearchType.locations:
        Future.microtask(() {
          _ref.read(locationNotifierProvider.notifier).getAllLocations();
        });
        break;
    }
  }

  void clear() {
    _currentQuery = '';
    _currentSearchType = SearchType.items;
    setInitial();
  }
} 