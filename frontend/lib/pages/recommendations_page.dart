import 'package:flutter/material.dart';

import '../services/api.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  // ------------------------------------------------------------
// BOOKWISE THEME COLORS
// ------------------------------------------------------------

  static const Color _pageBackground = Color(0xFFF5F6FC);
  static const Color _cream = Color(0xFFE8E9FF);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF191B3A);
  static const Color _muted = Color(0xFF777B99);
  static const Color _green = Color(0xFF191B3A);
  static const Color _orange = Color(0xFF454AA6);
  static const Color _border = Color(0xFFE8EAF2);

  static const Color _indigo = Color(0xFF454AA6);
  static const Color _lavender = Color(0xFFE8E9FF);
  // Actual editions are looked up by ISBN.
  // Known titles override generic seed-data placeholder images.
  static const Map<String, String> _coverIsbns = {
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

    // Books from the supplied design reference.
    'company of one': '9781328972354',
    'how innovation works': '9780062916594',
    'the picture of dorian gray': '9780141439570',
    'the two towers': '9780618346264',
    'objectif lune': '9782203001134',
    'the subtle art of not giving': '9780062457714',
  };

  static const List<String> _fallbackCovers = [
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=400&q=75',
    'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=400&q=75',
    'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=400&q=75',
    'https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=400&q=75',
  ];

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _recommendations = [];

  String _name = 'Reader';
  String _selectedCategory = 'All Categories';
  String _search = '';

  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // API
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      final response = await Api.request(
        'GET',
        path,
      ).timeout(const Duration(seconds: 6));

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {
      // An unavailable endpoint will not prevent other data from loading.
    }

    return <String, dynamic>{};
  }

  Future<void> _loadPage() async {
    if (_loadingMore) return;

    _loadingMore = true;

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      // Fetch the recommendations, library, and profile simultaneously.
      final responses = await Future.wait<Map<String, dynamic>>([
        _safeGet('/recommendations'),
        _safeGet('/books?sort=rating'),
        _safeGet('/profile'),
      ]);

      if (!mounted) return;

      setState(() {
        _recommendations = _asMapList(responses[0]['recommendations']);

        _books = _asMapList(responses[1]['books']);

        final profile = responses[2];
        final profileName = profile['name']?.toString();

        if (profileName != null && profileName.trim().isNotEmpty) {
          _name = profileName;
        }
      });
    } finally {
      _loadingMore = false;

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _open(String route) {
    Navigator.of(context).pushNamed(route);
  }

  // ------------------------------------------------------------
  // BOOK DATA AND COVER IMAGES
  // ------------------------------------------------------------

  String _normaliseTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _coverUrl(Map<String, dynamic> book, int index) {
    final title = _normaliseTitle(
      (book['title'] ?? '').toString(),
    );

    // Prefer a specific cover for known titles.
    for (final entry in _coverIsbns.entries) {
      if (title.contains(_normaliseTitle(entry.key))) {
        return 'https://covers.openlibrary.org/b/isbn/'
            '${entry.value}-L.jpg?default=false';
      }
    }

    // Use the book's own cover when it has one.
    final storedCover = (book['cover_url'] ??
            book['coverUrl'] ??
            book['image_url'] ??
            book['image'] ??
            '')
        .toString()
        .trim();

    if (storedCover.startsWith('https://') ||
        storedCover.startsWith('http://')) {
      return storedCover;
    }

    return _fallbackCovers[index.abs() % _fallbackCovers.length];
  }

  List<Map<String, dynamic>> get _recommendationSource {
    return _recommendations.isNotEmpty ? _recommendations : _books;
  }

  List<Map<String, dynamic>> get _filteredRecommendations {
    final query = _search.toLowerCase().trim();

    return _recommendationSource.where((book) {
      final title = (book['title'] ?? '').toString();
      final author = (book['author'] ?? '').toString();
      final genre = (book['genre'] ?? '').toString();

      final matchesCategory = _selectedCategory == 'All Categories' ||
          genre.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = query.isEmpty ||
          title.toLowerCase().contains(query) ||
          author.toLowerCase().contains(query) ||
          genre.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get _categories {
    final unique = <String>{};

    for (final book in _books) {
      final genre = (book['genre'] ?? '').toString().trim();

      if (genre.isNotEmpty) {
        unique.add(genre);
      }
    }

    final sorted = unique.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['All Categories', ...sorted];
  }

  List<MapEntry<String, Map<String, dynamic>>> get _categoryItems {
    final grouped = <String, Map<String, dynamic>>{};

    for (final book in _books) {
      final genre = (book['genre'] ?? '').toString().trim();

      if (genre.isNotEmpty) {
        grouped.putIfAbsent(genre, () => book);
      }
    }

    final items = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return items;
  }

  int _genreCount(String genre) {
    return _books.where((book) {
      return (book['genre'] ?? '').toString().toLowerCase() ==
          genre.toLowerCase();
    }).length;
  }

  bool _isFavorite(Map<String, dynamic> book) {
    final value = book['is_favorite'] ?? book['isFavorite'] ?? false;

    return value == true || value.toString().toLowerCase() == 'true';
  }

  Future<void> _toggleFavorite(Map<String, dynamic> book) async {
    final id = book['id'];

    if (id == null) {
      _showMessage('This book does not have a valid ID.');
      return;
    }

    try {
      final response = await Api.request(
        'POST',
        '/books/$id/favorite',
      );

      if (!mounted) return;

      _showMessage(
        response is Map
            ? response['message']?.toString() ?? 'Favorite list updated.'
            : 'Favorite list updated.',
      );

      await _loadPage();
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _displayGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'finance':
        return 'Money / Investing';
      case 'art & design':
        return 'Design';
      case 'self-help':
        return 'Self Improvement';
      default:
        return genre;
    }
  }

  // ------------------------------------------------------------
  // PAGE LAYOUT
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPage,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
            children: [
              _topHeader(),
              const SizedBox(height: 28),
              _searchPanel(),
              const SizedBox(height: 30),
              _recommendationsPanel(),
              const SizedBox(height: 26),
              _categoryPanel(),
              const SizedBox(height: 26),
              _libraryFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP HEADER
  // ------------------------------------------------------------

  Widget _topHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover',
              style: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Find the next book worth getting lost in.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
          ],
        );

        final profile = InkWell(
          onTap: () => _open('/profile'),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFF3D77D),
                  child: Text(
                    _name.isNotEmpty
                        ? _name.substring(0, 1).toUpperCase()
                        : 'R',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    _name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _ink,
                ),
              ],
            ),
          ),
        );

        if (constraints.maxWidth < 550) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profile,
              const SizedBox(height: 20),
              title,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            profile,
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SEARCH AND CATEGORY FILTER
  // ------------------------------------------------------------

  Widget _searchPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final categoryDropdown = DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'All Categories',
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19,
              ),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCategory = value);
              },
            ),
          );

          final searchField = TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() => _search = value.trim());
            },
            onSubmitted: (value) {
              setState(() => _search = value.trim());
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _muted,
                size: 20,
              ),
              hintText: 'Find the book you like...',
              hintStyle: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                    ),
              filled: true,
              fillColor: _white,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 13,
              ),
            ),
          );

          final searchButton = SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _search = _searchController.text.trim();
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Search',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );

          if (constraints.maxWidth < 570) {
            return Column(
              children: [
                categoryDropdown,
                const Divider(height: 8, color: _border),
                searchField,
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_filteredRecommendations.length} books found',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 105,
                      child: searchButton,
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 150,
                child: categoryDropdown,
              ),
              const SizedBox(
                height: 28,
                child: VerticalDivider(
                  width: 18,
                  color: _border,
                ),
              ),
              Expanded(child: searchField),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: searchButton,
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOK RECOMMENDATIONS
  // ------------------------------------------------------------

  Widget _recommendationsPanel() {
    final books = _filteredRecommendations;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 18),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 12, 17),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Recommendation',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Discover stories, ideas, and new perspectives.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _search = '';
                      _selectedCategory = 'All Categories';
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: _white,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (_loading && books.isEmpty)
            const SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(
                  color: _green,
                ),
              ),
            )
          else if (books.isEmpty)
            _emptyRecommendations()
          else
            SizedBox(
              height: 365,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 19),
                itemBuilder: (context, index) {
                  return _bookCard(
                    books[index],
                    index,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookCard(
    Map<String, dynamic> book,
    int index,
  ) {
    final title = (book['title'] ?? 'Untitled book').toString();
    final author = (book['author'] ?? 'Unknown author').toString();
    final rating = double.tryParse(
          (book['rating'] ?? 0).toString(),
        ) ??
        0;

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFF9F8F3),
                      padding: const EdgeInsets.all(2),
                      child: _coverImage(
                        book,
                        index,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: _white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Add to favorites',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _toggleFavorite(book),
                      icon: Icon(
                        _isFavorite(book)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _orange,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFE4B44F),
                size: 15,
              ),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                (book['available_copies'] ?? 0).toString(),
                style: const TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'available',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverImage(
    Map<String, dynamic> book,
    int index,
  ) {
    final url = _coverUrl(book, index);

    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: const Color(0xFFF5F2E9),
          alignment: Alignment.center,
          child: const Icon(
            Icons.menu_book_rounded,
            color: _muted,
            size: 32,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _coverPlaceholder(
          (book['title'] ?? 'Book').toString(),
        );
      },
    );
  }

  Widget _coverPlaceholder(String title) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE9E5D6),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: _green,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRecommendations() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 35, 18, 45),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 45,
              color: _green,
            ),
            const SizedBox(height: 12),
            const Text(
              'No matching recommendations',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another category or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _search = '';
                  _selectedCategory = 'All Categories';
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOK CATEGORY
  // ------------------------------------------------------------

  Widget _categoryPanel() {
    final categories = _categoryItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Category',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Explore books by the subjects you enjoy.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Show all categories',
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All Categories';
                  });
                },
                icon: const Icon(
                  Icons.tune_rounded,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Book categories will appear here.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    (constraints.maxWidth / 165).floor().clamp(2, 5);

                const spacing = 14.0;

                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 20,
                  children: [
                    for (final item in categories)
                      SizedBox(
                        width: cardWidth,
                        child: _categoryCard(
                          genre: item.key,
                          book: item.value,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required String genre,
    required Map<String, dynamic> book,
  }) {
    final selected = _selectedCategory.toLowerCase() == genre.toLowerCase();

    final bookIndex = _books.indexOf(book);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = selected ? 'All Categories' : genre;

          _searchController.clear();
          _search = '';
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 132,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFFE5E7DB) : const Color(0xFFF4F4F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _green : Colors.transparent,
                width: selected ? 1.5 : 0,
              ),
            ),
            child: _coverImage(
              book,
              bookIndex < 0 ? 0 : bookIndex,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _displayGenre(genre),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _green : _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_genreCount(genre)} '
            '${_genreCount(genre) == 1 ? 'book' : 'books'}',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FOOTER ACTIONS
  // ------------------------------------------------------------

  Widget _libraryFooter() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final information = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your next favorite book is waiting.',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Explore the library or share a book with '
                'the BookWise community.',
                style: TextStyle(
                  color: Color(0xFFD5E2DE),
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _open('/catalog'),
                style: FilledButton.styleFrom(
                  backgroundColor: _white,
                  foregroundColor: _green,
                ),
                child: const Text('Explore library'),
              ),
              OutlinedButton(
                onPressed: () => _open('/recommend-book'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _white,
                  side: const BorderSide(
                    color: Color(0xFFD5E2DE),
                  ),
                ),
                child: const Text('Share a book'),
              ),
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: SizedBox.shrink(),
              ),
              Expanded(
                flex: 3,
                child: information,
              ),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}
