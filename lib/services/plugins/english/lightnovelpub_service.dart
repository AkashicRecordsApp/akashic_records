import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class LightNovelPub implements PluginService, CloudflareBypass {
  @override
  String get name => 'LightNovelPub';
  @override
  String get lang => 'en';
  @override
  String get version => '2.2.0';
  @override
  bool get cloudflare => true;

  String get id => 'lightnovelpub';

  final String baseURL = 'https://www.lightnovelpub.com/';

  final Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Referer': 'https://www.lightnovelpub.com/',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
  };

  final Dio dio = Dio();
  final CookieJar cookieJar = CookieJar();

  LightNovelPub() {
    dio.interceptors.add(CookieManager(cookieJar));
  }

  @override
  Map<String, dynamic> get filters => {
    'order': {
      'type': FilterTypes.picker,
      'label': 'Order by',
      'value': 'popular',
      'options': [
        {'label': 'New', 'value': 'new'},
        {'label': 'Popular', 'value': 'popular'},
        {'label': 'Updates', 'value': 'updated'},
      ],
    },
    'status': {
      'type': FilterTypes.picker,
      'label': 'Status',
      'value': 'all',
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Completed', 'value': 'completed'},
        {'label': 'Ongoing', 'value': 'ongoing'},
      ],
    },
    'genres': {
      'type': FilterTypes.picker,
      'label': 'Genre',
      'value': 'all',
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Action', 'value': 'action'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Fantasy', 'value': 'fantasy'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Martial Arts', 'value': 'martial-arts'},
        {'label': 'Mature', 'value': 'mature'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Tragedy', 'value': 'tragedy'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Mystery', 'value': 'mystery'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {'label': 'Psychological', 'value': 'psychological'},
        {'label': 'Sci-fi', 'value': 'sci-fi'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'School Life', 'value': 'school-life'},
        {'label': 'Josei', 'value': 'josei'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Historical', 'value': 'historical'},
        {'label': 'Shoujo', 'value': 'shoujo'},
        {'label': 'Adult', 'value': 'adult'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Lolicon', 'value': 'lolicon'},
        {'label': 'Gender Bender', 'value': 'gender-bender'},
        {'label': 'Shounen Ai', 'value': 'shounen-ai'},
        {'label': 'Yaoi', 'value': 'yaoi'},
        {'label': 'Video Games', 'value': 'video-games'},
        {'label': 'Smut', 'value': 'smut'},
        {'label': 'Magical Realism', 'value': 'magical-realism'},
        {'label': 'Eastern Fantasy', 'value': 'eastern-fantasy'},
        {'label': 'Contemporary Romance', 'value': 'contemporary-romance'},
        {'label': 'Fantasy Romance', 'value': 'fantasy-romance'},
        {'label': 'Shoujo Ai', 'value': 'shoujo-ai'},
        {'label': 'Yuri', 'value': 'yuri'},
      ],
    },
  };

  Future<String> _fetchApi(String url, {BuildContext? context}) async {
    try {
      final storedCookies = await cookieJar.loadForRequest(Uri.parse(baseURL));
      String cookieString = storedCookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');
      headers['Cookie'] = cookieString;

      final response = await dio.get(
        url,
        options: Options(
          headers: headers,
          validateStatus:
              (status) => status != null && status >= 200 && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else if (response.statusCode == 403 || response.statusCode == 503) {
        print('Cloudflare detected on $url. Launching WebView bypass.');
        if (context != null) {
          final cookies = await _showWebViewAndCaptureCookies(
            safeContext: context,
            url: url,
          );

          return await _fetchApi(url, context: context);
        } else {
          print('Context is null. Cannot launch WebView.');
          return '';
        }
      } else {
        throw Exception(
          'Falha ao carregar dados de: $url - Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return '';
    }
  }

  @override
  Future<void> captureCloudflareCookies(
    BuildContext context,
    String url,
  ) async {
    await _showWebViewAndCaptureCookies(safeContext: context, url: url);
  }

  Future<List<Cookie>> _showWebViewAndCaptureCookies({
    required BuildContext safeContext,
    required String url,
  }) async {
    List<Cookie> capturedCookies = [];
    final cookieManager = WebviewCookieManager();
    await Navigator.push(
      safeContext,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text("webview")),
            body: CaptureCookies(url: url),
          );
        },
      ),
    );
    capturedCookies = await cookieJar.loadForRequest(Uri.parse(baseURL));
    return capturedCookies;
  }

  Future<List<Novel>> _parseNovels(String html) async {
    final novels = <Novel>[];

    final document = parse(html);
    final novelItems = document.querySelectorAll('li.novel-item');

    for (final item in novelItems) {
      try {
        final novelLink = item.querySelector('a');
        final coverImage = item.querySelector('img');

        if (novelLink != null && coverImage != null) {
          String novelPath = novelLink.attributes['href']?.substring(1) ?? '';
          String novelName = novelLink.attributes['title'] ?? '';
          String coverImageUrl =
              coverImage.attributes['data-src'] ??
              coverImage.attributes['src'] ??
              '';

          novels.add(
            Novel(
              id: novelPath,
              title: novelName,
              coverImageUrl: coverImageUrl,
              author: '',
              description: '',
              genres: [],
              chapters: [],
              artist: '',
              statusString: '',
              pluginId: 'lightnovelpub',
            ),
          );
        }
      } catch (e) {
        print('Erro ao analisar item do romance: $e');
      }
    }

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    filters ??= this.filters;

    final genres = filters['genres']['value'];
    final order = filters['order']['value'];
    final status = filters['status']['value'];

    final url = '${baseURL}browse/$genres/$order/$status/$pageNo';
    final body = await _fetchApi(url, context: context);

    if (body.isEmpty) {
      return [];
    }

    return _parseNovels(body);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi(baseURL + novelPath);
    final document = parse(body);

    final novel = Novel(
      id: novelPath,
      title: '',
      coverImageUrl: '',
      description: '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      author: '',
      pluginId: 'lightnovelpub',
    );

    novel.title = document.querySelector('h1.novel-title')?.text.trim() ?? '';
    novel.coverImageUrl =
        document.querySelector('figure.cover img')?.attributes['data-src'] ??
        document.querySelector('figure.cover img')?.attributes['src'] ??
        '';
    novel.author =
        document.querySelector('[itemprop="author"]')?.text.trim() ?? '';

    String statusText =
        document.querySelector('div.header-stats strong[class]')?.text.trim() ??
        '';
    novel.status = _parseNovelStatus(statusText);

    novel.description =
        document.querySelector('div.content')?.text.trim() ?? '';
    novel.genres = document.querySelector('div.categories')?.text.trim() ?? '';

    List<String> summaryParts = [];
    document.querySelectorAll('div.content p').forEach((element) {
      summaryParts.add(element.text);
    });
    novel.description = summaryParts.join('\n\n');

    List<String> genreArray = [];
    document.querySelectorAll('div.categories a').forEach((element) {
      genreArray.add(element.text);
    });
    novel.genres = genreArray.join(', ');

    return novel;
  }

  NovelStatus _parseNovelStatus(String statusText) {
    switch (statusText.toLowerCase()) {
      case 'ongoing':
        return NovelStatus.Andamento;
      case 'completed':
        return NovelStatus.Completa;
      default:
        return NovelStatus.Desconhecido;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi(baseURL + chapterPath);
    final document = parse(body);

    String chapterContent = '';
    final chapterContainer = document.querySelector('#chapter-container');

    if (chapterContainer != null) {
      chapterContent = chapterContainer.innerHtml;
    }

    return chapterContent;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '${baseURL}lnsearchlive';
    final link = '${baseURL}search';

    final body = await _fetchApi(link);
    final document = parse(body);

    String verifytoken = '';
    document.querySelectorAll('input').forEach((element) {
      if (element.attributes['name']?.contains('LNRequestVerifyToken') ==
          true) {
        verifytoken = element.attributes['value'] ?? '';
      }
    });

    final formData = {'inputContent': searchTerm};

    final responseSearch = await dio.post(
      url,
      options: Options(
        headers: {
          ...headers,
          'LNRequestVerifyToken': verifytoken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
      data: formData,
    );

    final jsonResponse = jsonDecode(responseSearch.data);

    return _parseNovels(jsonResponse['resultview']);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    throw UnimplementedError();
  }
}

enum FilterTypes { textInput, excludableCheckboxGroup, picker }

abstract class CloudflareBypass {
  Future<void> captureCloudflareCookies(BuildContext context, String url);
}

enum ParsingState {
  Idle,
  Novel,
  HeaderStats,
  Status,
  Stopped,
  Chapter,
  ChapterItem,
  ChapterList,
  TotalChapters,
  NovelName,
  AuthorName,
  Summary,
  Genres,
  Tags,
  Cover,
}

class CaptureCookies extends StatefulWidget {
  const CaptureCookies({super.key, required this.url});
  final String url;

  @override
  State<CaptureCookies> createState() => _CaptureCookiesState();
}

class _CaptureCookiesState extends State<CaptureCookies> {
  WebViewController controller = WebViewController();

  @override
  void initState() {
    super.initState();
    _loadHTML();
  }

  Future<void> _loadHTML() async {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String finishedUrl) async {
            print('Page finished loading: $finishedUrl');
            Navigator.pop(context, finishedUrl);
          },
          onWebResourceError: (WebResourceError error) {
            print('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
