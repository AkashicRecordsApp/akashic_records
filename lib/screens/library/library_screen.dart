import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/library/novel_filter_sort_widget.dart';
import 'dart:async';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Novel> novels = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  String _searchTerm = "";
  Map<String, dynamic> _filters = {};
  List<Novel> allNovels = [];
  Set<String> _previousPlugins = {};
  Timer? _debounce;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _initializeFilters();
    _scrollController.addListener(_scrollListener);
    _loadNovels();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);

    if (_previousPlugins != appState.selectedPlugins) {
      _previousPlugins = Set<String>.from(appState.selectedPlugins);
      _refreshNovels();
    }
  }

  Future<void> _initializeFilters() async {
    Map<String, dynamic> initialFilters = {};
    final appState = Provider.of<AppState>(context, listen: false);

    for (final pluginName in appState.selectedPlugins) {
      final plugin = appState.pluginServices[pluginName];
      if (plugin != null) {
        initialFilters.addAll(plugin.filters);
      }
    }

    if (_mounted) {
      setState(() {
        _filters = initialFilters;
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMore &&
        !isLoading) {
      _loadMoreNovels();
    }
  }

  Future<void> _loadNovels({bool search = false}) async {
    if (isLoading) return;

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      List<Novel> newNovels = [];
      final appState = Provider.of<AppState>(context, listen: false);

      for (final pluginName in appState.selectedPlugins) {
        final plugin = appState.pluginServices[pluginName];
        if (plugin != null) {
          final pluginNovels = await plugin.popularNovels(
            currentPage,
            filters: _filters,
          );
          for (final novel in pluginNovels) {
            novel.pluginId = pluginName;
          }
          newNovels.addAll(pluginNovels);
        }
      }

      final Set<String> seenNovelIds = {};
      for (final novel in newNovels) {
        final novelId = "${novel.id}-${novel.pluginId}";
        if (!seenNovelIds.contains(novelId)) {
          allNovels.add(novel);
          seenNovelIds.add(novelId);
        }
      }

      List<Novel> filteredNovels = allNovels;
      if (search && _searchTerm.isNotEmpty) {
        filteredNovels =
            allNovels
                .where(
                  (novel) => novel.title.toLowerCase().contains(
                    _searchTerm.toLowerCase(),
                  ),
                )
                .toList();
      }

      if (_mounted) {
        setState(() {
          novels = filteredNovels;
          hasMore = newNovels.isNotEmpty;
          isLoading = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar novels: $e';
          hasMore = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNovels() async {
    if (isLoading || !hasMore) return;
    currentPage++;
    await _loadNovels(search: _searchTerm.isNotEmpty);
  }

  Future<void> _refreshNovels() async {
    if (_mounted) {
      setState(() {
        allNovels.clear();
        novels.clear();
        currentPage = 1;
        hasMore = true;
        isLoading = false;
      });
    }
    await _loadNovels(search: _searchTerm.isNotEmpty);
  }

  Future<void> _onFilterChanged(Map<String, dynamic> newFilters) async {
    if (_mounted) {
      setState(() {
        _filters = newFilters;
        novels.clear();
        allNovels.clear();
        currentPage = 1;
        hasMore = true;
      });
    }
    await _loadNovels();
  }

  void _handleNovelTap(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NovelFilterSortWidget(
            filters: _filters,
            onFilterChanged: _onFilterChanged,
          ),
        );
      },
    );
  }

  void _onSearchChanged(String term) {
    _searchTerm = term;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_mounted) {
        setState(() {
          currentPage = 1;
          novels.clear();
          hasMore = true;
          allNovels.clear();
        });
      }
      _loadNovels(search: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBarWidget(
              onSearch: _onSearchChanged,
              onFilterPressed: () => _showFilterModal(context),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNovels,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: NovelGridWidget(
                novels: novels,
                isLoading: isLoading,
                errorMessage: errorMessage,
                scrollController: _scrollController,
                onNovelTap: _handleNovelTap,
              ),
            ),
          ),
          if (isLoading && novels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
