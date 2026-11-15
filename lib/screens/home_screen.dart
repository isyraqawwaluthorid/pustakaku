import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/extensions.dart';
import '../models/book.dart';
import '../providers/providers.dart';
import '../widgets/async_value_widget.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_state.dart';
import 'book_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Infinite scroll: muat halaman berikutnya saat mendekati bawah.
      if (_scroll.position.extentAfter < 400) {
        ref.read(bookSearchProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _open(Book book) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
      );

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(bookSearchProvider);
    final appUser = ref.watch(appUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${appUser?.displayName.split(' ').first ?? 'Pembaca'} 👋'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _controller,
              hintText: 'Cari judul, penulis, atau ISBN…',
              leading: const Icon(Icons.search),
              trailing: [
                if (search is! SearchIdle)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      ref.read(bookSearchProvider.notifier).clear();
                    },
                  ),
              ],
              onChanged: ref.read(bookSearchProvider.notifier).onQueryChanged,
              onSubmitted: ref.read(bookSearchProvider.notifier).search,
            ),
          ),
        ),
      ),
      // Pattern matching pada sealed class: semua kasus wajib ditangani.
      body: switch (search) {
        SearchIdle() => _TrendingList(onTap: _open),
        SearchLoading() => const Center(child: CircularProgressIndicator()),
        SearchError(:final query, :final message) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Gagal mencari "$query"',
            message: message,
            action: FilledButton.tonal(
              onPressed: () => ref.read(bookSearchProvider.notifier).search(query),
              child: const Text('Coba lagi'),
            ),
          ),
        SearchLoaded(books: []) => const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada hasil',
            message: 'Coba kata kunci lain.',
          ),
        SearchLoaded(:final books, :final totalFound, :final isLoadingMore) =>
          ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: books.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('$totalFound hasil ditemukan',
                      style: context.text.labelLarge
                          ?.copyWith(color: context.colors.outline)),
                );
              }
              if (i == books.length + 1) {
                return isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()))
                    : const SizedBox(height: 24);
              }
              final book = books[i - 1];
              return BookCard(book: book, onTap: () => _open(book));
            },
          ),
      },
    );
  }
}

class _TrendingList extends ConsumerWidget {
  const _TrendingList({required this.onTap});
  final ValueChanged<Book> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingBooksProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(trendingBooksProvider.future),
      child: AsyncValueWidget(
        value: trending,
        onRetry: () => ref.invalidate(trendingBooksProvider),
        data: (books) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: context.colors.error),
                const SizedBox(width: 8),
                Text('Sedang tren hari ini', style: context.text.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final book in books) BookCard(book: book, onTap: () => onTap(book)),
          ],
        ),
      ),
    );
  }
}
