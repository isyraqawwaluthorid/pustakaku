import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/extensions.dart';
import '../models/book.dart';
import '../providers/providers.dart';
import 'book_cover.dart';

class BookCard extends ConsumerWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(book.workId));

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(url: book.coverUrl(), heroTag: 'cover-${book.workId}'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: context.text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorLabel,
                      style: context.text.bodyMedium?.copyWith(color: context.colors.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (book.firstPublishYear case final year?)
                          _Meta(Icons.calendar_today_outlined, '$year'),
                        if (book.pages case final pages?)
                          _Meta(Icons.auto_stories_outlined, '$pages hlm'),
                        if (book.rating case final rating?)
                          _Meta(Icons.star_rounded, rating.toStringAsFixed(1),
                              color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFav ? 'Hapus dari favorit' : 'Simpan ke favorit',
                icon: Icon(
                  isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isFav ? context.colors.primary : null,
                ),
                onPressed: () async {
                  final result = await ref.read(toggleFavoriteProvider)(book);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {},
                    failure: (m) => context.showSnack(m, error: true),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label, {this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? context.colors.outline),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelSmall),
        ],
      );
}
