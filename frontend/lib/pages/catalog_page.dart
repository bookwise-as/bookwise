import 'package:flutter/material.dart';

import '../services/api.dart';
import '../widgets/app_navigation_shell.dart';
import 'book_form_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const navy = Color(0xFF191B3A);
  static const indigo = Color(0xFF454AA6);
  static const muted = Color(0xFF777BA0);

  final query = TextEditingController();

  List books = [];
  List allBooks = [];
  List history = [];

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

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get _borrowedCount =>
      history.where((item) => item['action']?.toString() == 'borrowed').length;

  int get _returnedCount =>
      history.where((item) => item['action']?.toString() == 'returned').length;

  int get _currentlyBorrowed {
    final count = _borrowedCount - _returnedCount;
    return count < 0 ? 0 : count;
  }

  int get _availableCopies => allBooks.fold<int>(
        0,
        (total, book) =>
            total + _intValue(book['available_copies'] ?? book['copies'] ?? 0),
      );

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    try {
      final responses = await Future.wait([
        Api.request(
          'GET',
          '/books?q=${Uri.encodeComponent(query.text)}&sort=$sort',
        ),
        Api.request('GET', '/history'),
        Api.request('GET', '/books?sort=title'),
      ]);

      if (!mounted) return;

      setState(() {
        books = responses[0]['books'] ?? [];
        history = responses[1]['history'] ?? [];
        allBooks = responses[2]['books'] ?? [];
      });
    } catch (error) {
      if (mounted) _message(error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  Future<void> _favorite(dynamic book) async {
    try {
      await Api.request(
        'POST',
        '/books/${book['id']}/favorite',
      );
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
        _message(
          response['message'] ?? 'Book borrowed successfully.',
        );
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
        _message(
          response['message'] ?? 'Book returned successfully.',
        );
        await load();
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _reserve(dynamic book) async {
    try {
      final response = await Api.request(
        'POST',
        '/books/${book['id']}/reserve',
      );

      if (mounted) {
        _message(
          '${response['message']} Position: ${response['queue_position']}',
        );
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _deleteBook(dynamic book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text(
          'Are you sure you want to delete "${book['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.request(
        'DELETE',
        '/books/${book['id']}',
      );
      if (mounted) {
        _message('Book deleted successfully.');
        await load();
      }
    } catch (error) {
      if (mounted) _message(error);
    }
  }

  Future<void> _editBook(dynamic book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppNavigationShell(
          currentRoute: '/catalog',
          child: BookFormPage(book: book),
        ),
      ),
    );

    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Books'),
        actions: [
          IconButton(
            tooltip: 'Refresh catalog',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Add a book',
            onPressed: () {
              Navigator.pushNamed(context, '/add-book').then((_) => load());
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _introCard(),
            const SizedBox(height: 22),
            const Text(
              'Your borrowing overview',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'A quick look at your reading activity and library stock.',
              style: TextStyle(
                fontSize: 13,
                color: muted,
              ),
            ),
            const SizedBox(height: 14),
            _summaryCards(),
            const SizedBox(height: 26),
            const Text(
              'Find your next read',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
            const SizedBox(height: 12),
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
                          setState(() {});
                          load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '${books.length} books found',
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE1E3F1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sort,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.tune_rounded, size: 19),
                      items: const [
                        DropdownMenuItem(
                          value: 'title',
                          child: Text('Title A–Z'),
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
                ),
              ],
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (!loading && books.isEmpty) _emptyState(),
            ...books.map(
              (book) => _BookCard(
                book: book,
                onFavorite: () => _favorite(book),
                onBorrow: () => _borrow(book),
                onReturn: () => _return(book),
                onReserve: () => _reserve(book),
                onEdit: () => _editBook(book),
                onDelete: () => _deleteBook(book),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCards() {
    final statistics = [
      _CatalogStat(
        label: 'Currently Borrowed',
        value: _currentlyBorrowed,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFE8E9FF),
        foreground: const Color(0xFF454AA6),
      ),
      _CatalogStat(
        label: 'Books Returned',
        value: _returnedCount,
        icon: Icons.assignment_return_rounded,
        color: const Color(0xFFE2F5EF),
        foreground: const Color(0xFF287C68),
      ),
      _CatalogStat(
        label: 'Available Copies',
        value: _availableCopies,
        icon: Icons.library_books_rounded,
        color: const Color(0xFFFFF0D8),
        foreground: const Color(0xFF98651D),
      ),
      _CatalogStat(
        label: 'Search Results',
        value: books.length,
        icon: Icons.search_rounded,
        color: const Color(0xFFF0E6FF),
        foreground: const Color(0xFF7650AA),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in statistics)
              SizedBox(
                width: cardWidth,
                child: _statCard(stat),
              ),
          ],
        );
      },
    );
  }

  Widget _statCard(_CatalogStat stat) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: stat.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                stat.icon,
                color: stat.foreground,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stat.value}',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stat.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF191B3A),
            Color(0xFF353B78),
            Color(0xFF555BC1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x222A2D69),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'YOUR READING JOURNEY',
                        style: TextStyle(
                          color: Color(0xFFDADFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Find a story\nthat stays with you.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Explore new worlds, discover authors, and find your next favorite book.',
                      style: TextStyle(
                        color: Color(0xFFE2E5FF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE4E6FF),
                        foregroundColor: navy,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/recommendations');
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('For you'),
                    ),
                  ],
                ),
              ),
              if (constraints.maxWidth >= 360) ...[
                const SizedBox(width: 12),
                Container(
                  width: constraints.maxWidth >= 600 ? 110 : 66,
                  height: constraints.maxWidth >= 600 ? 110 : 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: const Color(0xFFC8CCFF),
                    size: constraints.maxWidth >= 600 ? 68 : 42,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: indigo,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No books found',
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another search or clear your current search terms.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                query.clear();
                load();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Show all books'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStat {
  const _CatalogStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.foreground,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color foreground;
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

  // Known ISBNs for the books included in the BookWise catalog.
  // These ISBNs are used to request a cover for the corresponding edition.
  static const Map<String, String> _isbnByTitle = {
    'the silent patient': '9781250301697',
    'atomic habits': '9780735211292',
    'dune': '9780441172719',
    'pride and prejudice': '9780141439518',
    'the hobbit': '9780547928227',
    'clean code': '9780132350884',
    'the alchemist': '9780062315007',
    'the midnight library': '9780525559474',
    'project hail mary': '9780593135204',
    'educated': '9780399590504',
    'the creative act': '9780593652886',
    'a brief history of time': '9780553380163',
    'the little prince': '9780156012195',
    'tomorrow and tomorrow and tomorrow': '9780593321201',
    'the book thief': '9780375842207',
    'klara and the sun': '9780593318171',
    'the name of the wind': '9780756404741',
    'the vanishing half': '9780525536291',
    'sapiens': '9780062316097',
    'the psychology of money': '9780857197689',
    'circe': '9780316556347',
    'the seven husbands of evelyn hugo': '9781501161933',
  };

  String _normaliseTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String? _coverUrlForBook() {
    final title = _normaliseTitle(
      (book['title'] ?? '').toString(),
    );

    // Prefer an ISBN already stored in the database.
    final suppliedIsbn =
        (book['isbn'] ?? book['isbn13'] ?? book['isbn_13'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9Xx]'), '');

    // If there is no ISBN, use the known ISBN associated with the title.
    final mappedIsbn = _isbnByTitle[title];
    final isbn = suppliedIsbn.isNotEmpty ? suppliedIsbn : mappedIsbn;

    if (isbn != null && isbn.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg?default=false';
    }

    // For books outside the map, keep an existing non-stock cover image.
    final existingUrl = (book['cover_url'] ?? '').toString().trim();

    if ((existingUrl.startsWith('https://') ||
            existingUrl.startsWith('http://')) &&
        !existingUrl.contains('images.unsplash.com')) {
      return existingUrl;
    }

    // No known original cover URL is available.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rawCopies = book['available_copies'] ?? book['copies'] ?? 0;
    final copies = rawCopies is num
        ? rawCopies.toInt()
        : int.tryParse(rawCopies.toString()) ?? 0;

    final available = copies > 0;
    final isBorrowed = book['is_borrowed'] == true;
    final isFavorite = book['is_favorite'] == true;
    final coverUrl = _coverUrlForBook();

    final status = isBorrowed && available
        ? '$copies available • You borrowed this'
        : isBorrowed
            ? 'You borrowed this'
            : available
                ? '$copies available'
                : 'Currently unavailable';

    final statusColor = isBorrowed
        ? const Color(0xFF8B691E)
        : available
            ? const Color(0xFF287C68)
            : Theme.of(context).colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 102,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF25284D),
                        Color(0xFF656BD1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),

                  // Request the book's cover using its ISBN.
                  // Show a fallback icon if the cover cannot be loaded.
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFFDDE0FF),
                            size: 34,
                          ),
                        )
                      : const Icon(
                          Icons.auto_stories_rounded,
                          color: Color(0xFFDDE0FF),
                          size: 34,
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']?.toString() ?? 'Untitled',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF242644),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book['author']?.toString() ?? 'Unknown author',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF777BA0),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFC18A2C),
                              size: 16,
                            ),
                            label: Text('${book['rating'] ?? 0}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              book['genre']?.toString() ?? 'Uncategorised',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? const Color(0xFFE65A79)
                        : const Color(0xFF777BA0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    available
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Published ${book['published_year'] ?? 'year unknown'}',
              style: const TextStyle(
                color: Color(0xFF8589A8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: available ? onBorrow : null,
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Borrow'),
                ),
                OutlinedButton.icon(
                  onPressed: isBorrowed ? onReturn : null,
                  icon: const Icon(Icons.assignment_return_rounded, size: 18),
                  label: const Text('Return'),
                ),
                if (!available && !isBorrowed)
                  TextButton.icon(
                    onPressed: onReserve,
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                    ),
                    label: const Text('Reserve'),
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
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit book'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete book'),
                        contentPadding: EdgeInsets.zero,
                      ),
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
