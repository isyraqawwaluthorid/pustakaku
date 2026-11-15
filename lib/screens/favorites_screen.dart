import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/async_value_widget.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_state.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit saya')),
      body: AsyncValueWidget(
        value: favorites,
        onRetry: () => ref.invalidate(favoritesProvider),
        data: (books) => books.isEmpty
            ? const EmptyState(
                icon: Icons.bookmark_add_outlined,
                title: 'Belum ada favorit',
                message: 'Tekan ikon bookmark pada buku untuk menyimpannya di sini. '
                    'Data tersimpan di Cloud Firestore dan tersinkron di semua perangkatmu.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                itemBuilder: (_, i) => BookCard(
                  book: books[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookDetailScreen(book: books[i])),
                  ),
                ),
              ),
      ),
    );
  }
}
