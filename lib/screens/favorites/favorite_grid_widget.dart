import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/novel_card.dart';
import 'package:akashic_records/i18n/i18n.dart';

class FavoriteGridWidget extends StatelessWidget {
  final List<Novel> favoriteNovels;
  final Function(Novel) onNovelTap;
  final Future<void> Function() onRefresh;
  final Function(Novel) onNovelLongPress;

  const FavoriteGridWidget({
    super.key,
    required this.favoriteNovels,
    required this.onNovelTap,
    required this.onRefresh,
    required this.onNovelLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (favoriteNovels.isEmpty) {
      return Center(
        child: Text(
          "Você não possui favoritos!".translate,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 4);

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: favoriteNovels.length,
          itemBuilder: (context, index) {
            final novel = favoriteNovels[index];
            return NovelCard(
              novel: novel,
              onTap: () => onNovelTap(novel),
              onLongPress: () => onNovelLongPress(novel),
            );
          },
        );
      },
    );
  }
}
