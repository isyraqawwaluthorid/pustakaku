import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/extensions.dart';
import '../models/book.dart';
import '../models/review.dart';
import '../providers/providers.dart';
import '../widgets/book_cover.dart';
import '../widgets/rating_stars.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookDetailProvider(book.workId));
    final isFav = ref.watch(isFavoriteProvider(book.workId));
    final reviews = ref.watch(reviewsProvider(book.workId));
    final avg = ref.watch(averageRatingProvider(book.workId));
    final me = ref.watch(appUserProvider).value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: isFav ? 'Hapus dari favorit' : 'Simpan ke favorit',
                icon: Icon(isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
                onPressed: () async {
                  final r = await ref.read(toggleFavoriteProvider)(book);
                  if (!context.mounted) return;
                  r.when(
                    success: (_) => context.showSnack(
                        isFav ? 'Dihapus dari favorit' : 'Disimpan ke favorit'),
                    failure: (m) => context.showSnack(m, error: true),
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(
                      url: book.coverUrl(CoverSize.large),
                      width: 120,
                      height: 176,
                      heroTag: 'cover-${book.workId}',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.authorLabel, style: context.text.titleMedium),
                          const SizedBox(height: 8),
                          if (book.firstPublishYear case final y?)
                            Text('Terbit pertama: $y', style: context.text.bodyMedium),
                          if (book.pages case final p?)
                            Text('± $p halaman', style: context.text.bodyMedium),
                          const SizedBox(height: 8),
                          if (avg != null)
                            Row(children: [
                              RatingStars(rating: avg),
                              const SizedBox(width: 6),
                              Text('${avg.toStringAsFixed(1)} · '
                                  '${reviews.value?.length ?? 0} ulasan'),
                            ])
                          else if (book.rating case final r?)
                            Row(children: [
                              RatingStars(rating: r),
                              const SizedBox(width: 6),
                              Text('${r.toStringAsFixed(1)} (Open Library)'),
                            ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Deskripsi', style: context.text.titleMedium),
                const SizedBox(height: 8),
                detail.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e', style: TextStyle(color: context.colors.error)),
                  data: (d) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpandableText(d.description),
                      if (d.subjects.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Subjek', style: context.text.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in d.subjects)
                              Chip(label: Text(s.truncate(28)), visualDensity: VisualDensity.compact),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Ulasan pembaca', style: context.text.titleMedium)),
                    FilledButton.tonalIcon(
                      onPressed: me == null
                          ? null
                          : () => _showReviewSheet(context, ref, me.uid, me.displayName),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Tulis ulasan'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                reviews.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e'),
                  data: (list) => list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('Belum ada ulasan. Jadilah yang pertama!',
                              style: TextStyle(color: context.colors.outline)),
                        )
                      : Column(
                          children: [
                            for (final r in list)
                              _ReviewTile(
                                review: r,
                                // Authorization: pemilik ulasan ATAU admin boleh menghapus.
                                canDelete: me != null && (me.uid == r.uid || me.isAdmin),
                                onDelete: () async {
                                  final res = await ref
                                      .read(firestoreServiceProvider)
                                      .deleteReview(r.id);
                                  if (!context.mounted) return;
                                  res.when(
                                    success: (_) => context.showSnack('Ulasan dihapus'),
                                    failure: (m) => context.showSnack(m, error: true),
                                  );
                                },
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewSheet(
      BuildContext context, WidgetRef ref, String uid, String name) async {
    var rating = 5;
    final text = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ulas "${book.title.truncate(40)}"', style: ctx.text.titleMedium),
              const SizedBox(height: 12),
              Center(
                child: RatingStars(
                  rating: rating.toDouble(),
                  size: 36,
                  onChanged: (v) => setState(() => rating = v),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Bagaimana pendapatmu tentang buku ini?'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Kirim ulasan'),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || text.text.trim().isEmpty) return;

    final res = await ref.read(firestoreServiceProvider).addReview(Review(
          id: '',
          bookId: book.workId,
          uid: uid,
          authorName: name,
          rating: rating,
          text: text.text.trim(),
        ));
    if (!context.mounted) return;
    res.when(
      success: (_) => context.showSnack('Terima kasih atas ulasanmu!'),
      failure: (m) => context.showSnack(m, error: true),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.canDelete, required this.onDelete});
  final Review review;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(child: Text(review.authorName.initials)),
          title: Row(children: [
            Expanded(child: Text(review.authorName, style: context.text.titleSmall)),
            RatingStars(rating: review.rating.toDouble(), size: 16),
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(review.text),
              const SizedBox(height: 4),
              Text(review.createdAt?.timeAgo ?? 'mengirim…',
                  style: context.text.labelSmall?.copyWith(color: context.colors.outline)),
            ],
          ),
          trailing: canDelete
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus ulasan',
                  onPressed: onDelete,
                )
              : null,
          isThreeLine: true,
        ),
      );
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_expanded || !long ? widget.text : widget.text.truncate(300)),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Lebih sedikit' : 'Selengkapnya'),
          ),
      ],
    );
  }
}
