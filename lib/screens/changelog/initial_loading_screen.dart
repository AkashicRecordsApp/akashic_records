import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class InitialLoadingScreen extends StatefulWidget {
  const InitialLoadingScreen({
    super.key,
    this.updateAvailable = false,
    this.downloadUrl,
    required this.onDone,
    required this.showChangelog,
  });

  final bool updateAvailable;
  final String? downloadUrl;
  final Future<void> Function() onDone;
  final bool showChangelog;

  @override
  State<InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<InitialLoadingScreen> {
  String _body = 'Carregando...'.translate;
  String _uploader = 'Carregando...'.translate;
  String _avatarUrl = '';
  bool _isLoading = true;
  String _loadingMessage = 'Carregando dados do GitHub...'.translate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/AkashicRecordsApp/akashic_records/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final body = data['body'] as String;
        final author = data['author'];
        final uploaderLogin = author['login'] as String;
        final avatarUrl = author['avatar_url'] as String;

        setState(() {
          _body = body;
          _uploader = uploaderLogin;
          _avatarUrl = avatarUrl;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'status ${response.statusCode}.'.translate;
          _uploader = 'Erro ao carregar'.translate;
          _isLoading = false;
          _loadingMessage = 'Erro ao carregar dados'.translate;
        });
        debugPrint('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Falha ao carregar o changelog. Erro: $e. Verifique sua conexão com a internet e tente novamente.'
                .translate;
        _uploader = 'Erro ao carregar'.translate;
        _isLoading = false;
        _loadingMessage = 'Erro ao carregar dados'.translate;
      });
      debugPrint('Erro: $e');
    }
  }

  Future<void> _setInitialScreenShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownInitialScreen', true);
  }

  Future<void> _downloadAndInstall() async {
    if (widget.downloadUrl != null) {
      try {
        final Uri uri = Uri.parse(widget.downloadUrl!);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          setState(() {
            _errorMessage =
                'Não foi possível abrir o link de download. Verifique se você tem um aplicativo padrão configurado para abrir links.'
                    .translate;
          });
          throw Exception('Could not launch ${widget.downloadUrl}');
        }
      } catch (e) {
        setState(() {
          _errorMessage =
              'Erro ao abrir o link de download: $e. Verifique o link ou tente novamente mais tarde.'
                  .translate;
        });
        debugPrint('Erro ao abrir link: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Changelog da Versão'.translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _isLoading
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                          strokeWidth: 5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    backgroundColor: colorScheme.surface,
                    color: colorScheme.primary,
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                if (widget.showChangelog)
                                  Card(
                                    elevation: 4,
                                    shadowColor: colorScheme.shadow,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: colorScheme.surfaceVariant,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: MarkdownBody(
                                        data: _body,
                                        onTapLink: (text, url, title) {
                                          if (url != null) {
                                            launchUrl(Uri.parse(url));
                                          }
                                        },
                                        styleSheet:
                                            MarkdownStyleSheet.fromTheme(
                                              theme,
                                            ).copyWith(
                                              p: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontSize: 18,
                                                    height: 1.6,
                                                  ),
                                              h1: theme.textTheme.headlineMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              h2: theme.textTheme.headlineSmall
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              h3: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              listBullet: theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontSize: 18,
                                                  ),
                                              code: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
                                                    backgroundColor:
                                                        colorScheme
                                                            .surfaceVariant,
                                                  ),
                                              blockquoteDecoration:
                                                  BoxDecoration(
                                                    border: Border(
                                                      left: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 3.0,
                                                      ),
                                                    ),
                                                    color: colorScheme
                                                        .surfaceVariant
                                                        .withOpacity(0.3),
                                                  ),
                                            ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Text(
                                  'Enviado por:'.translate,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(_avatarUrl),
                                    radius: 30,
                                  ),
                                  title: Text(
                                    _uploader,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                if (widget.updateAvailable)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.system_update_alt,
                                        ),
                                        label: Text(
                                          'Atualizar Aplicativo'.translate,
                                        ),
                                        onPressed: () {
                                          _downloadAndInstall();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 32),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _setInitialScreenShown();
                                        widget.onDone();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.secondary,
                                        foregroundColor:
                                            colorScheme.onSecondary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text('Continuar'.translate),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      ),
    );
  }
}
