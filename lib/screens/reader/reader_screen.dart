import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/reader/reader_settings_modal_widget.dart';
import 'package:akashic_records/screens/reader/chapter_display_widget.dart';
import 'package:akashic_records/screens/reader/chapter_navigation_widget.dart';
import 'package:akashic_records/screens/reader/reader_app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/plugin_service.dart';

class ReaderScreen extends StatefulWidget {
  final String novelId;

  const ReaderScreen({super.key, required this.novelId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Novel? novel;
  Chapter? currentChapter;
  int currentChapterIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  late SharedPreferences _prefs;
  String? _lastReadChapterId;
  bool _mounted = false;
  ReaderSettings _readerSettings = ReaderSettings();
  final bool _isFetchingNextChapter = false;

  bool _isUiVisible = true;

  Timer? _hideUiTimer;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();

    _startUiHideTimer();
  }

  @override
  void dispose() {
    _mounted = false;
    _hideUiTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReaderSettings();
    await _loadLastReadChapter();
  }

  Future<void> _loadReaderSettings() async {
    final settingsMap = _prefs.getKeys().fold<Map<String, dynamic>>(
      {},
      (previousValue, key) => {
        ...previousValue,
        if (key.startsWith('reader_')) key.substring(7): _prefs.get(key),
      },
    );

    if (settingsMap.isNotEmpty) {
      setState(() {
        _readerSettings = ReaderSettings.fromMap(settingsMap);
      });
    }
  }

  Future<void> _saveReaderSettings() async {
    final settingsMap = _readerSettings.toMap();
    settingsMap.forEach((key, value) {
      if (value is int) {
        _prefs.setInt('reader_$key', value);
      } else if (value is double) {
        _prefs.setDouble('reader_$key', value);
      } else if (value is String) {
        _prefs.setString('reader_$key', value);
      } else if (value is int?) {
        if (value != null) {
          _prefs.setInt('reader_$key', value);
        }
      }
    });
  }

  Future<void> _loadLastReadChapter() async {
    _lastReadChapterId = _prefs.getString('lastRead_${widget.novelId}');
    await _loadNovel();
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    await _prefs.setString('lastRead_${widget.novelId}_$timestamp', chapterId);
  }

  Future<void> _loadNovel() async {
    setState(() {
      _mounted = true;
      isLoading = true;
      errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      PluginService? plugin;

      for (final pluginName in appState.pluginServices.keys) {
        final p = appState.pluginServices[pluginName];
        try {
          final tempNovel = await p?.parseNovel(widget.novelId);
          if (tempNovel != null) {
            plugin = p;
            novel = tempNovel;
            break;
          }
        } catch (e) {
          print(
            'Erro ao carregar detalhes da novel com o plugin ${p?.name}: $e',
          );
        }
      }

      if (plugin != null && novel != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        final plugin = appState.pluginServices[novel!.pluginId];
        if (plugin != null) {
          if (_lastReadChapterId != null) {
            currentChapterIndex = novel!.chapters.indexWhere(
              (chapter) => chapter.id == _lastReadChapterId,
            );
            if (currentChapterIndex == -1) {
              currentChapterIndex = 0;
            }
          } else {
            currentChapterIndex = 0;
          }

          if (novel!.chapters.isNotEmpty) {
            currentChapter = novel!.chapters[currentChapterIndex];
            await _loadChapterContent();
          } else {
            setState(() {
              if (!_mounted) return;
              errorMessage = 'Erro: Nenhum capítulo encontrado.';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            if (!_mounted) return;
            errorMessage = 'Erro: Plugin inválido.';
            isLoading = false;
          });
        }
      } else {
        errorMessage = 'Novel não encontrada em nenhum plugin selecionado.';
      }
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar novel: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent() async {
    if (novel == null || currentChapter == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[novel!.pluginId];
      if (plugin != null) {
        final content = await plugin.parseChapter(currentChapter!.id);

        setState(() {
          currentChapter = Chapter(
            id: currentChapter!.id,
            title: currentChapter!.title,
            content: content,
            releaseDate: '',
            chapterNumber: null,
            order: 0,
          );
          isLoading = false;
        });
        _saveLastReadChapter(currentChapter!.id);
        _addToHistory();
      } else {
        setState(() {
          if (!_mounted) return;
          errorMessage = 'Erro: Plugin inválido.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar capítulo: $e';
        isLoading = false;
      });
    }
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ReaderSettingsModal(
          readerSettings: _readerSettings,
          onSettingsChanged: (newSettings) {
            if (!_mounted) return;
            setState(() {
              _readerSettings = newSettings;
            });
          },
          onSave: _saveReaderSettings,
        );
      },
    );
  }

  void _goToPreviousChapter() {
    if (novel != null && currentChapterIndex > 0) {
      setState(() {
        isLoading = true;
        currentChapterIndex--;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      _loadChapterContent();
    }
  }

  void _goToNextChapter() {
    if (novel != null && currentChapterIndex < novel!.chapters.length - 1) {
      setState(() {
        isLoading = true;
        currentChapterIndex++;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      _loadChapterContent();
    }
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;

      if (_isUiVisible) {
        _startUiHideTimer();
      } else {
        _hideUiTimer?.cancel();
      }
    });
  }

  void _startUiHideTimer() {
    _hideUiTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isUiVisible = false;
      });
    });
  }

  Future<void> _addToHistory() async {
    if (novel == null || currentChapter == null) return;

    final historyKey = 'history_${widget.novelId}';
    final historyString = _prefs.getString(historyKey) ?? '[]';
    List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

    final newItem = {
      'novelId': widget.novelId,
      'novelTitle': novel!.title,
      'chapterId': currentChapter!.id,
      'chapterTitle': currentChapter!.title,
      'pluginId': novel!.pluginId,
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

    await _prefs.setString(historyKey, jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleUiVisibility,
      child: Scaffold(
        backgroundColor: _readerSettings.backgroundColor,
        appBar:
            _isUiVisible
                ? ReaderAppBar(
                  title:
                      isLoading ||
                              errorMessage != null ||
                              currentChapter == null
                          ? null
                          : currentChapter!.title,
                  readerSettings: _readerSettings,
                  onSettingsPressed: () => _showSettingsModal(context),
                )
                : null,
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Column(
                  children: [
                    Expanded(
                      child: ChapterDisplay(
                        chapterContent: currentChapter?.content,
                        readerSettings: _readerSettings,
                      ),
                    ),

                    if (_isUiVisible)
                      ChapterNavigation(
                        onPreviousChapter: _goToPreviousChapter,
                        onNextChapter: _goToNextChapter,
                        isLoading: isLoading || _isFetchingNextChapter,
                        readerSettings: _readerSettings,
                      ),
                  ],
                ),
      ),
    );
  }
}
