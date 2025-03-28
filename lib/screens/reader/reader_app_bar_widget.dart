import 'package:flutter/material.dart';
import 'package:akashic_records/screens/reader/reader_settings_modal_widget.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ReaderSettings readerSettings;
  final VoidCallback onSettingsPressed;

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.readerSettings,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: readerSettings.backgroundColor,
      foregroundColor: readerSettings.textColor,
      title: Text(
        title ?? "Carregando...",
        style: TextStyle(color: readerSettings.textColor),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: readerSettings.textColor),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
