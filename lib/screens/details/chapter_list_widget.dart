import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChapterListWidget extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;
  final Set<String> readChapterIds;
  final Function(String) onMarkAsRead;
  final String novelId;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    this.lastReadChapterId,
    this.readChapterIds = const {},
    required this.onMarkAsRead,
    required this.novelId,
  });

  @override
  _ChapterListWidgetState createState() => _ChapterListWidgetState();
}

class _ChapterListWidgetState extends State<ChapterListWidget> {
  List<Chapter> _chapters = [];
  List<Chapter> _displayedChapters = [];
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  int _firstItemIndex = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _chapters = List.from(widget.chapters);
    _sortChapters();
    _loadInitialChapters();

    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChapterListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapters != oldWidget.chapters ||
        widget.readChapterIds != oldWidget.readChapterIds) {
      _chapters = List.from(widget.chapters);
      _sortChapters();
      _searchChapters();
      _resetPagination();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _firstItemIndex = 0;
    _displayedChapters.clear();
    _loadInitialChapters();
  }

  void _loadInitialChapters() {
    if (!_mounted) return;

    _displayedChapters = _chapters.sublist(
      0,
      _pageSize.clamp(0, _chapters.length),
    );
    if (_mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore) {
      _loadMoreChapters();
    }
  }

  void _loadMoreChapters() async {
    if (_isLoadingMore || !_mounted) return;
    _isLoadingMore = true;

    await Future.delayed(const Duration(milliseconds: 200));

    _firstItemIndex += _pageSize;
    final int endIndex = (_firstItemIndex + _pageSize).clamp(
      0,
      _chapters.length,
    );

    if (_firstItemIndex < _chapters.length) {
      if (_mounted) {
        setState(() {
          _displayedChapters.addAll(
            _chapters.sublist(_firstItemIndex, endIndex),
          );
          _isLoadingMore = false;
        });
      }
    } else {
      _isLoadingMore = false;
    }
  }

  void _sortChapters() {
    if (!_mounted) return;

    _displayedChapters = List.from(_chapters);

    _displayedChapters.sort((a, b) {
      final comparison =
          _isAscending
              ? (a.chapterNumber ?? double.infinity).compareTo(
                b.chapterNumber ?? double.infinity,
              )
              : (b.chapterNumber ?? double.infinity).compareTo(
                a.chapterNumber ?? double.infinity,
              );
      return comparison;
    });

    if (_mounted) {
      setState(() {});
    }
  }

  void _toggleSortOrder() {
    if (!_mounted) return;
    setState(() {
      _isAscending = !_isAscending;
      _sortChapters();
    });
  }

  void _searchChapters() {
    if (!_mounted) return;

    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _sortChapters();
    } else {
      if (_mounted) {
        setState(() {
          _displayedChapters =
              _chapters.where((chapter) {
                return chapter.title.toLowerCase().contains(query) ||
                    (chapter.chapterNumber != null &&
                        chapter.chapterNumber!.toString().contains(query));
              }).toList();

          _displayedChapters.sort((a, b) {
            if (_isAscending) {
              return (a.chapterNumber ?? double.infinity).compareTo(
                b.chapterNumber ?? double.infinity,
              );
            } else {
              return (b.chapterNumber ?? double.infinity).compareTo(
                a.chapterNumber ?? double.infinity,
              );
            }
          });
        });
      }
    }
  }

  Future<void> _addToHistory(Chapter chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'history_${widget.novelId}';
    final historyString = prefs.getString(historyKey) ?? '[]';
    List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

    final newItem = {
      'novelId': widget.novelId,
      'novelTitle': '',
      'chapterId': chapter.id,
      'chapterTitle': chapter.title,
      'pluginId': '',
      'chapterNumber': chapter.chapterNumber,
    };

    int existingIndex = history.indexWhere(
      (item) => item['chapterId'] == newItem['chapterId'],
    );

    if (existingIndex != -1) {
      history[existingIndex] = {
        ...newItem,
        'lastRead': history[existingIndex]['lastRead'],
      };
    } else {
      history.insert(0, {
        ...newItem,
        'lastRead': DateTime.now().toIso8601String(),
      });
    }

    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    await prefs.setString(historyKey, jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = screenHeight * 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar Capítulo'.translate,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (_) => _searchChapters(),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  onPressed: _toggleSortOrder,
                  tooltip:
                      _isAscending
                          ? 'Ordenar Decrescente'.translate
                          : 'Ordenar Crescente'.translate,
                ),
              ],
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _displayedChapters.length + (_isLoadingMore ? 1 : 0),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  if (index < _displayedChapters.length) {
                    final chapter = _displayedChapters[index];
                    final isLastRead = chapter.id == widget.lastReadChapterId;
                    final isRead = widget.readChapterIds.contains(chapter.id);
                    final isUnread = !isRead;

                    FontWeight fontWeight = FontWeight.normal;
                    if (isUnread) {
                      fontWeight = FontWeight.bold;
                    }
                    String chapterDisplay = chapter.title;
                    if (chapter.chapterNumber != null) {
                      chapterDisplay =
                          "${chapter.chapterNumber}: ${chapter.title}";
                    }
                    return Card(
                      elevation: 1.5,
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onChapterTap(chapter.id);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chapterDisplay,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: fontWeight,
                                      color:
                                          isLastRead
                                              ? theme.colorScheme.secondary
                                              : isRead
                                              ? theme.disabledColor
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isLastRead)
                                  Icon(
                                    Icons.bookmark,
                                    color: theme.colorScheme.secondary,
                                  ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(24.0),
                                  onTap: () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          widget.onMarkAsRead(chapter.id);
                                          if (!isRead) {
                                            _addToHistory(chapter);
                                          }
                                        });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      isRead
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color:
                                          isRead
                                              ? Colors.green
                                              : theme.disabledColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
