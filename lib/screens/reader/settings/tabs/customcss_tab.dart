import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/css.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomCssTab extends StatefulWidget {
  const CustomCssTab({super.key});

  @override
  State<CustomCssTab> createState() => _CustomCssTabState();
}

class _CustomCssTabState extends State<CustomCssTab> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _codeController = CodeController(
      language: css,
      text: appState.readerSettings.customCss ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final readerSettings = appState.readerSettings;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSS Customizado:'.translate,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Classes e tags úteis: .reader-content, p, h1, h2, a, b, strong'
                      .translate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                CodeField(
                  controller: _codeController,
                  textStyle: GoogleFonts.sourceCodePro(
                    textStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newSettings = ReaderSettings(
                        theme: readerSettings.theme,
                        fontSize: readerSettings.fontSize,
                        fontFamily: readerSettings.fontFamily,
                        lineHeight: readerSettings.lineHeight,
                        textAlign: readerSettings.textAlign,
                        backgroundColor: readerSettings.backgroundColor,
                        textColor: readerSettings.textColor,
                        fontWeight: readerSettings.fontWeight,
                        customColors: readerSettings.customColors,
                        customJs: readerSettings.customJs,
                        customCss: _codeController.text,
                      );
                      appState.setReaderSettings(newSettings);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'CSS customizado salvo!'.translate,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('Salvar CSS Customizado'.translate),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
