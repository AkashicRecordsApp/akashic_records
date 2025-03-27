import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/models/chapter.dart';
import 'package:akashic_records/models/novel_status.dart';

class IllusiaService {
  final String id = 'illusia';
  final String name = 'illusia';
  final String baseUrl = 'https://illusia.com.br';
  final String browsePage = '/historias';
  final String searchPage = '/';
  final String version = '1.0.3';

  Map<String, dynamic> filters = {
    'order': {
      'label': 'Ordenar por',
      'value': 'default',
      'options': [
        {'label': 'Padrão', 'value': 'default'},
        {'label': 'A-Z', 'value': 'a-z'},
        {'label': 'Z-A', 'value': 'z-a'},
        {'label': 'Últ. Att', 'value': 'update'},
        {'label': 'Últ. Add', 'value': 'latest'},
      ],
    },
  };

  Future<String> _fetchApi(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to fetch data from $url. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching $url: $e');
      rethrow;
    }
  }

  String _cleanUrl(String url) {
    return url.replaceAll(baseUrl, '').replaceFirst(RegExp(r'^/'), '');
  }

  String _expandUrl(String path) {
    return '$baseUrl$path';
  }

  Future<List<Novel>> popularNovels(
    int page, {
    required Map<String, dynamic> filters,
  }) async {
    final url = _expandUrl('$browsePage/${page == 1 ? '' : 'page/$page'}');
    try {
      final html = await _fetchApi(url);
      final document = parser.parse(html);

      final novelElements = document.querySelectorAll(
        'div.list-story > div.bs-item > div.bs-content',
      );

      return novelElements.map((element) {
        final titleElement = element.querySelector('h3 > a');
        final coverElement = element.querySelector('img');
        final urlElement = element.querySelector('h3 > a');
        final String? novelPath = urlElement?.attributes['href'];

        String cleanedPath = '';
        if (novelPath != null) {
          if (novelPath.startsWith(baseUrl)) {
            cleanedPath = _cleanUrl(novelPath);
          } else if (novelPath.startsWith('/story/')) {
            cleanedPath = novelPath.substring(0, novelPath.length);
          }
        }

        return Novel(
          id: cleanedPath,
          title: titleElement?.text.trim() ?? '',
          coverImageUrl: coverElement?.attributes['src'] ?? '',
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
      }).toList();
    } catch (e) {
      print('Error parsing popular novels: $e');
      return [];
    }
  }

  Future<Novel> parseNovel(String novelPath) async {
    if (!novelPath.startsWith('/story/')) {
      print('Invalid novel path: $novelPath. Must start with /story/');
      return Novel(
        id: novelPath,
        title: 'Error: Invalid Path',
        coverImageUrl: '',
        author: '',
        description: '',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
      );
    }
    final url = _expandUrl(novelPath);
    try {
      final html = await _fetchApi(url);
      final document = parser.parse(html);

      final novel = Novel(
        id: novelPath,
        title: document.querySelector('div.post-title > h1')?.text.trim() ?? '',
        coverImageUrl:
            document
                .querySelector('div.summary_image > a > img')
                ?.attributes['src'] ??
            '',
        author:
            document.querySelector('div.author-content > a')?.text.trim() ?? '',
        description:
            document.querySelector('div.summary__content > p')?.text.trim() ??
            '',
        genres:
            document
                .querySelectorAll('div.genres-content > a')
                .map((e) => e.text.trim())
                .toList(),
        chapters: [],
        artist: '',
        statusString: '',
      );

      final statusText =
          document
              .querySelector('div.post-status > div > div.summary-content')
              ?.text
              .trim() ??
          '';

      if (statusText.contains('Em andamento')) {
        novel.status = NovelStatus.ongoing;
      } else if (statusText.contains('Completo')) {
        novel.status = NovelStatus.completed;
      } else if (statusText.contains('Hiatus')) {
        novel.status = NovelStatus.onHiatus;
      }

      final chapterElements = document.querySelectorAll(
        'ul.list-chapter > li > a',
      );
      for (var element in chapterElements) {
        final chapterName =
            element.querySelector('span.chapter-text')?.text.trim() ?? '';
        final chapterPath = _cleanUrl(element.attributes['href'] ?? '');
        novel.chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterName,
            content: '',
            order: chapterElements.toList().indexOf(element) + 1,
          ),
        );
      }

      return novel;
    } catch (e) {
      print('Error parsing novel details: $e');
      rethrow;
    }
  }

  Future<String> parseChapter(String chapterPath) async {
    if (!chapterPath.startsWith('/story/')) {
      print('Invalid chapter path: $chapterPath. Must start with /story/');
      return "Error: Invalid Chapter Path";
    }
    final url = _expandUrl(chapterPath);
    try {
      final html = await _fetchApi(url);
      final document = parser.parse(html);
      final chapterContentElement = document.querySelector(
        'div.reading-content',
      );
      return chapterContentElement?.innerHtml ?? '';
    } catch (e) {
      print('Error parsing chapter: $e');
      rethrow;
    }
  }

  Future<List<Novel>> searchNovels(String searchTerm, int page) async {
    final encodedSearchTerm = Uri.encodeComponent(searchTerm);
    final url = _expandUrl(
      '$searchPage?s=$encodedSearchTerm&post_type=wp-manga&page=$page',
    );
    try {
      final html = await _fetchApi(url);
      final document = parser.parse(html);

      final novelElements = document.querySelectorAll(
        'div.c-tabs-item__content > div.bs-item',
      );

      return novelElements.map((element) {
        final titleElement = element.querySelector('h3 > a');
        final coverElement = element.querySelector('img');
        final urlElement = element.querySelector('h3 > a');

        final String? novelPath = urlElement?.attributes['href'];

        String cleanedPath = '';
        if (novelPath != null) {
          if (novelPath.startsWith(baseUrl)) {
            cleanedPath = _cleanUrl(novelPath);
          }
        }

        return Novel(
          id: cleanedPath,
          title: titleElement?.text.trim() ?? '',
          coverImageUrl: coverElement?.attributes['src'] ?? '',
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
      }).toList();
    } catch (e) {
      print('Error searching novels: $e');
      return [];
    }
  }

  String resolveUrl(String path) {
    return _expandUrl(path);
  }
}
