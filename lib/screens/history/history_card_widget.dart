import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryCardWidget extends StatelessWidget {
  final String novelTitle;
  final String chapterTitle;
  final String pluginId;
  final DateTime lastRead;
  final VoidCallback onTap;

  const HistoryCardWidget({
    super.key,
    required this.novelTitle,
    required this.chapterTitle,
    required this.pluginId,
    required this.lastRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(lastRead);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];
    final pluginTextColor = isDarkMode ? Colors.grey[500] : Colors.grey[700];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                novelTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "Capítulo: $chapterTitle",
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Plugin: $pluginId",
                style: TextStyle(fontSize: 12, color: pluginTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
