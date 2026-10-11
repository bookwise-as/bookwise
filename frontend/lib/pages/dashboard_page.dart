import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ------------------------------------------------------------
  // COLORS AND DESIGN
  // ------------------------------------------------------------

  static const Color _ink = Color(0xFF20213D);
  static const Color _muted = Color(0xFF7C809B);
  static const Color _background = Color(0xFFF4F6FA);
  static const Color _line = Color(0xFFE8EAF2);
  static const Color _mint = Color(0xFFD7ECE8);
  static const Color _pink = Color(0xFFFFDDEC);
  static const Color _yellow = Color(0xFFFFE8AC);
  static const Color _lilac = Color(0xFFE0D8F0);
  static const Color _purple = Color(0xFF5559A8);

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _fallbackCovers = [
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=400&q=70',
    'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=400&q=70',
    'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=400&q=70',
    'https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=400&q=70',
  ];

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  String _name = 'Reader';
  String _email = '';
  String _search = '';

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _recommendedBooks = [];
  List<Map<String, dynamic>> _myRecommendations = [];

  List<Map<String, dynamic>> _sortedHistoryCache = [];
  List<Map<String, dynamic>> _activeLoansCache = [];

  final Map<Map<String, dynamic>, DateTime?> _eventDates = {};
  final Map<String, int> _activityCountsByDay = {};

  bool _loading = true;
  bool _returningBook = false;

  Future<void>? _loadOperation;

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATA LOADING
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
      ).timeout(const Duration(seconds: 5));

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {
      // Allow other dashboard sections to load if a request fails.
    }

    return <String, dynamic>{};
  }

  Future<void> _loadCachedUser() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );

      final savedUser = preferences.getString('user');

      if (savedUser == null || savedUser.isEmpty) {
        return;
      }

      final decoded = jsonDecode(savedUser);

      if (decoded is! Map || !mounted) {
        return;
      }

      final cachedName = decoded['name']?.toString();
      final cachedEmail = decoded['email']?.toString();

      setState(() {
        if (cachedName != null && cachedName.trim().isNotEmpty) {
          _name = cachedName;
        }

        if (cachedEmail != null) {
          _email = cachedEmail;
        }
      });
    } catch (_) {
      // Continue using the default name if cached data is unavailable.
    }
  }

  Future<void> _loadDashboard() {
    if (_loadOperation != null) {
      return _loadOperation!;
    }

    final operation = _performDashboardLoad();
    _loadOperation = operation;

    return operation.whenComplete(() {
      _loadOperation = null;
    });
  }

  Future<void> _performDashboardLoad() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    // Start all API requests at the same time.
    final requests = Future.wait<Map<String, dynamic>>([
      _safeGet('/profile'),
      _safeGet('/books?sort=title'),
      _safeGet('/history'),
      _safeGet('/recommendations'),
      _safeGet('/my-recommendations'),
    ]);

    await _loadCachedUser();

    try {
      final responses = await requests;

      if (!mounted) return;

      final profile = responses[0];
      final books = _asMapList(responses[1]['books']);
      final history = _asMapList(responses[2]['history']);
      final recommendations = _asMapList(responses[3]['recommendations']);
      final myRecommendations = _asMapList(responses[4]['books']);

      _prepareHistory(history);

      setState(() {
        final profileName = profile['name']?.toString();
        final profileEmail = profile['email']?.toString();

        if (profileName != null && profileName.trim().isNotEmpty) {
          _name = profileName;
        }

        if (profileEmail != null) {
          _email = profileEmail;
        }

        _books = books;
        _recommendedBooks = recommendations;
        _myRecommendations = myRecommendations;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to refresh dashboard information. '
          'Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _prepareHistory(List<Map<String, dynamic>> history) {
    _history = history;

    _eventDates.clear();
    _activityCountsByDay.clear();

    _sortedHistoryCache = List<Map<String, dynamic>>.from(history);

    for (final event in _history) {
      final date = _eventDate(event);

      if (date != null) {
        final key = _dateKey(date);

        _activityCountsByDay.update(
          key,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    _sortedHistoryCache.sort((a, b) {
      final firstDate = _eventDate(a) ?? DateTime(1970);
      final secondDate = _eventDate(b) ?? DateTime(1970);

      return secondDate.compareTo(firstDate);
    });

    final latestByBook = <String, Map<String, dynamic>>{};

    for (final event in _sortedHistoryCache) {
      final id = (event['book_id'] ?? event['bookId'] ?? '').toString();

      if (id.isEmpty) continue;

      latestByBook.putIfAbsent(id, () => event);
    }

    _activeLoansCache = latestByBook.values.where(_isBorrow).toList();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ------------------------------------------------------------
  // DATE AND ACTIVITY HELPERS
  // ------------------------------------------------------------

  DateTime? _eventDate(Map<String, dynamic> event) {
    if (_eventDates.containsKey(event)) {
      return _eventDates[event];
    }

    final value = event['created_at'] ?? event['createdAt'] ?? event['date'];

    final parsed =
        value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

    _eventDates[event] = parsed;
    return parsed;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'Recently';

    return '${_months[date.month - 1].substring(0, 3)} ${date.day}';
  }

  String _action(Map<String, dynamic> event) {
    return (event['action'] ?? 'activity').toString().toLowerCase();
  }

  bool _isBorrow(Map<String, dynamic> event) {
    return _action(event).contains('borrow');
  }

  bool _isReturn(Map<String, dynamic> event) {
    return _action(event).contains('return');
  }

  List<Map<String, dynamic>> get _sortedHistory {
    return _sortedHistoryCache;
  }

  List<Map<String, dynamic>> get _todayHistory {
    final today = DateTime.now();

    return _history.where((event) {
      final date = _eventDate(event);
      return date != null && _sameDay(date, today);
    }).toList();
  }

  int get _borrowedToday {
    return _todayHistory.where(_isBorrow).length;
  }

  int get _returnedToday {
    return _todayHistory.where(_isReturn).length;
  }

  int get _favoriteCount {
    return _books.where((book) {
      final value = book['is_favorite'] ?? book['isFavorite'] ?? false;

      return value == true || value.toString().toLowerCase() == 'true';
    }).length;
  }

  List<Map<String, dynamic>> get _activeLoans {
    return _activeLoansCache;
  }

  int _activityCount(DateTime date) {
    return _activityCountsByDay[_dateKey(date)] ?? 0;
  }

  List<Map<String, dynamic>> get _selectedDayEvents {
    final query = _search.trim().toLowerCase();

    return _sortedHistory.where((event) {
      final date = _eventDate(event);

      if (date == null || !_sameDay(date, _selectedDate)) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchable = '${event['title'] ?? ''} '
              '${event['author'] ?? ''} '
              '${event['action'] ?? ''}'
          .toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _visibleActivity {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _sortedHistory.take(5).toList();
    }

    return _sortedHistory
        .where((event) {
          final searchable = '${event['title'] ?? ''} '
                  '${event['author'] ?? ''} '
                  '${event['action'] ?? ''}'
              .toLowerCase();

          return searchable.contains(query);
        })
        .take(5)
        .toList();
  }

  List<Map<String, dynamic>> get _visibleLoans {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _activeLoans.take(4).toList();
    }

    return _activeLoans
        .where((event) {
          final searchable =
              '${event['title'] ?? ''} ${event['author'] ?? ''}'.toLowerCase();

          return searchable.contains(query);
        })
        .take(4)
        .toList();
  }

  // ------------------------------------------------------------
  // RETURN A BOOK
  // ------------------------------------------------------------

  Future<void> _returnBook(Map<String, dynamic> loan) async {
    if (_returningBook) return;

    final id = loan['book_id'] ?? loan['bookId'] ?? loan['id'];

    if (id == null) {
      _showMessage('The book ID is missing from this history entry.');
      return;
    }

    setState(() => _returningBook = true);

    try {
      final response = await Api.request(
        'POST',
        '/books/$id/return',
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      _showMessage(
        response is Map
            ? response['message']?.toString() ?? 'Book returned.'
            : 'Book returned.',
      );

      await _loadDashboard();
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _returningBook = false);
      }
    }
  }

  void _open(String route) {
    Navigator.of(context).pushNamed(route);
  }

  // ------------------------------------------------------------
  // MAIN DASHBOARD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            children: [
              _topHeader(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: _purple,
                    backgroundColor: _lilac,
                  ),
                ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _mainColumn(),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: _sideColumn(),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mainColumn(),
                      const SizedBox(height: 22),
                      _sideColumn(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _topHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final greeting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back 👋',
              style: TextStyle(
                color: _ink,
                fontSize: constraints.maxWidth < 480 ? 25 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hello, $_name! Here is your reading overview.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        );

        final searchBox = TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _search = value);
          },
          onSubmitted: (_) => _open('/catalog'),
          decoration: InputDecoration(
            hintText: 'Search books or activity',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
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
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: _line),
            ),
          ),
        );

        final avatar = Tooltip(
          message: _email.isEmpty ? 'My profile' : _email,
          child: InkWell(
            onTap: () => _open('/profile'),
            borderRadius: BorderRadius.circular(50),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: _lilac,
              child: Text(
                _name.isNotEmpty ? _name.substring(0, 1).toUpperCase() : 'R',
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );

        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: searchBox),
                  const SizedBox(width: 12),
                  avatar,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 18),
            SizedBox(width: 250, child: searchBox),
            const SizedBox(width: 12),
            avatar,
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MAIN COLUMN
  // ------------------------------------------------------------

  Widget _mainColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          'Your activities today',
          '${_todayHistory.length} recorded '
              '${_todayHistory.length == 1 ? 'activity' : 'activities'}',
        ),
        const SizedBox(height: 12),
        _todayActivityCards(),
        const SizedBox(height: 24),
        _sectionHeader(
          'Reading progress',
          'A quick overview of your BookWise library.',
        ),
        const SizedBox(height: 12),
        _progressStats(),
        const SizedBox(height: 24),
        _sectionHeader(
          'Currently borrowed',
          'Books that are still marked as borrowed.',
          actionLabel: 'Explore books',
          onAction: () => _open('/catalog'),
        ),
        const SizedBox(height: 12),
        _borrowedBooksPanel(),
        const SizedBox(height: 24),
        _sharedBooksPanel(),
      ],
    );
  }

  // ------------------------------------------------------------
  // TODAY'S ACTIVITY CARDS
  // ------------------------------------------------------------

  Widget _todayActivityCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _activityHighlight(
                title: 'Books borrowed',
                value: _borrowedToday.toString(),
                color: _mint,
                icon: Icons.menu_book_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _activityHighlight(
                title: 'Books returned',
                value: _returnedToday.toString(),
                color: _pink,
                icon: Icons.bookmark_added_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _activityHighlight({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 134,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                child: Icon(
                  icon,
                  size: 18,
                  color: _ink,
                ),
              ),
              const Spacer(),

              // Larger activity number.
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Arrow removed: a simple "Today" label is enough.
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Today',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // READING PROGRESS
  // ------------------------------------------------------------

  Widget _progressStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _miniStat(
                label: 'Active loans',
                value: _activeLoans.length.toString(),
                color: _mint,
                icon: Icons.menu_book_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _miniStat(
                label: 'Favorite books',
                value: _favoriteCount.toString(),
                color: _yellow,
                icon: Icons.favorite_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _miniStat(
                label: 'Picked for you',
                value: _recommendedBooks.length.toString(),
                color: _lilac,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: _ink.withValues(alpha: 0.75),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Larger reading progress number.
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BORROWED BOOKS
  // ------------------------------------------------------------

  Widget _borrowedBooksPanel() {
    final loans = _visibleLoans;

    if (loans.isEmpty) {
      return _emptyPanel(
        icon: Icons.menu_book_outlined,
        title: _search.isEmpty
            ? 'Your borrowed shelf is clear'
            : 'No matching loans',
        message: _search.isEmpty
            ? 'When you borrow a book, it will appear here.'
            : 'Try a different search term.',
        buttonLabel: 'Browse library',
        onPressed: () => _open('/catalog'),
      );
    }

    return Column(
      children: [
        for (final loan in loans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _loanTile(loan),
          ),
      ],
    );
  }

  Widget _loanTile(Map<String, dynamic> loan) {
    final title = (loan['title'] ?? 'Untitled book').toString();
    final author = (loan['author'] ?? 'Unknown author').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 54,
              height: 69,
              child: _photo(_historyBookImage(loan), size: 25),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
                Text(
                  'Borrowed ${_formatShortDate(_eventDate(loan))}',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Return book',
            onPressed: _returningBook ? null : () => _returnBook(loan),
            style: IconButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: _ink,
            ),
            icon: _returningBook
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.assignment_return_rounded,
                    size: 19,
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOKS YOU SHARED
  // ------------------------------------------------------------

  Widget _sharedBooksPanel() {
    if (_myRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Books you shared',
          'Your community recommendations.',
        ),
        const SizedBox(height: 12),
        for (final book in _myRecommendations.take(3))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _lilac,
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    color: _purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (book['title'] ?? 'Untitled book').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (book['author'] ?? 'Unknown author').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RIGHT COLUMN
  // ------------------------------------------------------------

  Widget _sideColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _calendarPanel(),
        const SizedBox(height: 18),
        _recentActivityPanel(),
        const SizedBox(height: 18),
        _discoverPanel(),
      ],
    );
  }

  // ------------------------------------------------------------
  // READING CALENDAR
  // ------------------------------------------------------------

  Widget _calendarPanel() {
    final selectedEvents = _selectedDayEvents;

    final firstWeekday = DateTime(
          _calendarMonth.year,
          _calendarMonth.month,
          1,
        ).weekday -
        1;

    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;

    final cellCount = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    final selectedActivityCount = _activityCount(_selectedDate);

    return _whitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reading calendar',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month - 1,
                      1,
                    );

                    _selectedDate = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month + 1,
                      1,
                    );

                    _selectedDate = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Text(
            '${_months[_calendarMonth.month - 1]} '
            '${_calendarMonth.year}',
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final day in const [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ])
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 37,
              crossAxisSpacing: 2,
              mainAxisSpacing: 3,
            ),
            itemBuilder: (context, index) {
              final day = index - firstWeekday + 1;

              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                _calendarMonth.year,
                _calendarMonth.month,
                day,
              );

              final selected = _sameDay(date, _selectedDate);
              final today = _sameDay(date, DateTime.now());
              final hasActivity = _activityCount(date) > 0;

              return InkWell(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? _purple
                        : today
                            ? _mint
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? null
                        : Border.all(
                            color: today ? _mint : Colors.transparent,
                          ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: selected ? Colors.white : _ink,
                          fontSize: 11,
                          fontWeight: selected || today
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                      if (hasActivity)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : _purple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mint.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  color: _ink,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$selectedActivityCount recorded '
                        '${selectedActivityCount == 1 ? 'activity' : 'activities'}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dots mark days with borrowing history.',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            const Text(
              'No recorded book activity on this day.',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            )
          else
            ...selectedEvents.take(2).map(_calendarActivityItem),
        ],
      ),
    );
  }

  Widget _calendarActivityItem(Map<String, dynamic> event) {
    final returned = _isReturn(event);

    final label = returned
        ? 'Returned'
        : _isBorrow(event)
            ? 'Borrowed'
            : (event['action'] ?? 'Activity').toString();

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Icon(
            returned
                ? Icons.assignment_return_rounded
                : Icons.menu_book_rounded,
            size: 17,
            color: _purple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label · ${event['title'] ?? 'Book activity'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT ACTIVITY
  // ------------------------------------------------------------

  Widget _recentActivityPanel() {
    final activities = _visibleActivity;

    return _whitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Recent activity',
            'Your latest book interactions.',
            actionLabel: 'Full history',
            onAction: () => _open('/history'),
          ),
          const SizedBox(height: 13),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No activity to display yet.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final event in activities) _activityRow(event),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> event) {
    final action = _action(event);
    final returned = _isReturn(event);
    final borrowed = _isBorrow(event);
    final title = (event['title'] ?? 'Book activity').toString();

    final color = returned
        ? _mint
        : borrowed
            ? _pink
            : _lilac;

    final icon = returned
        ? Icons.assignment_return_rounded
        : borrowed
            ? Icons.menu_book_rounded
            : Icons.auto_awesome_rounded;

    final label = returned
        ? 'Returned'
        : borrowed
            ? 'Borrowed'
            : action.isEmpty
                ? 'Activity'
                : '${action[0].toUpperCase()}${action.substring(1)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _ink, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · $title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(_eventDate(event)),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DISCOVERY PANEL
  // ------------------------------------------------------------

  Widget _discoverPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF262A51),
            Color(0xFF5559A8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: _yellow,
            size: 26,
          ),
          const SizedBox(height: 12),
          const Text(
            'Find your next favorite.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore personalized suggestions or share a title '
            'with the community.',
            style: TextStyle(
              color: Color(0xFFE0E2FA),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _open('/recommendations'),
                child: const Text('For you'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFFB5B9E8),
                  ),
                ),
                onPressed: () => _open('/recommend-book'),
                child: const Text('Share a book'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // REUSABLE COMPONENTS
  // ------------------------------------------------------------

  Widget _sectionHeader(
    String title,
    String subtitle, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _whitePanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D1030),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, color: _purple, size: 31),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 11),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOK IMAGES
  // ------------------------------------------------------------

  String _historyBookImage(Map<String, dynamic> event) {
    final id = (event['book_id'] ?? event['bookId'] ?? '').toString();

    for (var i = 0; i < _books.length; i++) {
      if ((_books[i]['id'] ?? '').toString() == id) {
        return _bookImage(_books[i], i);
      }
    }

    final index = _history.indexOf(event).abs();

    return _fallbackCovers[index % _fallbackCovers.length];
  }

  String _bookImage(Map<String, dynamic> book, int index) {
    final cover = (book['cover_url'] ??
            book['coverUrl'] ??
            book['image_url'] ??
            book['image'] ??
            '')
        .toString()
        .trim();

    if (cover.startsWith('https://') || cover.startsWith('http://')) {
      return cover;
    }

    return _fallbackCovers[index % _fallbackCovers.length];
  }

  Widget _photo(String url, {double size = 32}) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }

        return Container(
          color: _lilac,
          alignment: Alignment.center,
          child: Icon(
            Icons.menu_book_rounded,
            color: _purple,
            size: size,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: _lilac,
          alignment: Alignment.center,
          child: Icon(
            Icons.menu_book_rounded,
            color: _purple,
            size: size,
          ),
        );
      },
    );
  }
}
