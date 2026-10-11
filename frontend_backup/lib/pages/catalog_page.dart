import 'package:flutter/material.dart';

import '../services/api.dart';
import '../widgets/app_drawer.dart';
import 'book_form_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final query = TextEditingController();
  List books = [];
  String sort = 'title';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final response = await Api.request(
        'GET',
        '/books?q=${Uri.encodeComponent(query.text)}&sort=$sort',
      );
      if (mounted) setState(() => books = response['books'] ?? []);
    } catch (error) {
      if (mounted) _message(error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _favorite(dynamic book) async {
    try {
      await Api.request('POST', '/books/${book['id']}/favorite');
      await load();
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _borrow(dynamic book) async {
    try {
      final response = await Api.request(
        'POST',
        '/books/${book['id']}/borrow',
      );
      if (mounted) {
        _message(response['message'] ?? 'Book borrowed successfully.');
        await load();
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _return(dynamic book) async {
    try {
      final response = await Api.request(
        'POST',
        '/books/${book['id']}/return',
      );
      if (mounted) {
        _message(response['message'] ?? 'Book returned successfully.');
        await load();
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _reserve(dynamic book) async {
    try {
      final response =
          await Api.request('POST', '/books/${book['id']}/reserve');
      if (mounted) {
        _message(
          '${response['message']} Position: ${response['queue_position']}',
        );
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Explore the library'),
          actions: [
            IconButton(
              tooltip: 'Add a book',
              onPressed: () =>
                  Navigator.pushNamed(context, '/add-book').then((_) => load()),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              _introCard(),
              const SizedBox(height: 14),
              TextField(
                controller: query,
                onSubmitted: (_) => load(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by title, author, or genre',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            query.clear();
                            load();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    '${books.length} books to discover',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sort,
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(
                          value: 'title',
                          child: Text('Title'),
                        ),
                        DropdownMenuItem(
                          value: 'rating',
                          child: Text('Top rated'),
                        ),
                        DropdownMenuItem(
                          value: 'year',
                          child: Text('Newest'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => sort = value);
                        load();
                      },
                    ),
                  ),
                ],
              ),
              if (loading) const LinearProgressIndicator(minHeight: 3),
              if (!loading && books.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 46),
                        SizedBox(height: 10),
                        Text(
                          'No stories found yet',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try another search or add the first book to the shelf.',
                        ),
                      ],
                    ),
                  ),
                ),
              ...books.map(
                (book) => _BookCard(
                  book: book,
                  onFavorite: () => _favorite(book),
                  onBorrow: () => _borrow(book),
                  onReturn: () => _return(book),
                  onReserve: () => _reserve(book),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookFormPage(book: book),
                    ),
                  ).then((_) => load()),
                  onDelete: () async {
                    try {
                      await Api.request(
                        'DELETE',
                        '/books/${book['id']}',
                      );
                      await load();
                    } catch (error) {
                      if (mounted) _message(error);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _introCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF211A12), Color(0xFF72521F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a story\nthat stays with you.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search by feeling, favorite author, or genre.',
                    style: TextStyle(color: Color(0xFFFFE8B0)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.explore_rounded,
              color: Color(0xFFFFD982),
              size: 58,
            ),
          ],
        ),
      );
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onFavorite,
    required this.onBorrow,
    required this.onReturn,
    required this.onReserve,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic book;
  final VoidCallback onFavorite;
  final VoidCallback onBorrow;
  final VoidCallback onReturn;
  final VoidCallback onReserve;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final copies = book['available_copies'] ?? book['copies'] ?? 0;
    final available = copies is num && copies > 0;
    final isBorrowed = book['is_borrowed'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFFF0C7),
                  child: Text(
                    '${book['rating'] ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF8B641E),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']?.toString() ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book['author'] ?? 'Unknown author'}',
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(
                              '${book['genre'] ?? 'Uncategorised'}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            isBorrowed && available
                                ? '$copies available • You borrowed this'
                                : (isBorrowed
                                    ? 'You borrowed this'
                                    : (available
                                        ? '$copies available'
                                        : 'Currently unavailable')),
                            style: TextStyle(
                              color: isBorrowed
                                  ? const Color(0xFF8B641E)
                                  : (available
                                      ? const Color(0xFF47754E)
                                      : Theme.of(context).colorScheme.error),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Favorite',
                  onPressed: onFavorite,
                  icon: Icon(
                    book['is_favorite'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        book['is_favorite'] == true ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Text(
                  '${book['published_year'] ?? 'Year unknown'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: available ? onBorrow : null,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Borrow'),
                ),
                TextButton.icon(
                  onPressed: isBorrowed ? onReturn : null,
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('Return'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit book'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete book'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
