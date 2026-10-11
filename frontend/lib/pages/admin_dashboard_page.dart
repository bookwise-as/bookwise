import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color navy = Color(0xFF191B3A);
  static const Color indigo = Color(0xFF454AA6);
  static const Color lavender = Color(0xFFE8E9FF);
  static const Color background = Color(0xFFF5F6FC);
  static const Color ink = Color(0xFF242644);
  static const Color muted = Color(0xFF777BA0);
  static const Color border = Color(0xFFE7E8F3);
  static const Color danger = Color(0xFFC4435A);
  static const Color success = Color(0xFF287C68);
  static const Color paleGreen = Color(0xFFE2F5EF);
  static const Color paleYellow = Color(0xFFFFF0D8);
  static const Color palePurple = Color(0xFFF0E6FF);

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  bool loading = true;
  bool _hasLoaded = false;

  String? error;
  String _section = 'Overview';
  String _userSearch = '';
  String _bookSearch = '';
  String _historySearch = '';
  String _historyFilter = 'All';

  int currentUserId = 0;
  int users = 0;
  int books = 0;
  int borrowed = 0;
  int reservations = 0;

  List<Map<String, dynamic>> usersList = [];
  List<Map<String, dynamic>> booksList = [];
  List<Map<String, dynamic>> reservationsList = [];
  List<Map<String, dynamic>> historyList = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _str(dynamic value) => value?.toString() ?? '';

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _cleanError(Object exception) {
    return exception.toString().replaceFirst('Exception: ', '');
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        Api.request('GET', '/admin/overview'),
        Api.request('GET', '/admin/users'),
        Api.request('GET', '/admin/books'),
        Api.request('GET', '/admin/reservations'),
        Api.request('GET', '/admin/history'),
        Api.request('GET', '/profile'),
      ]);

      if (!mounted) return;

      final overview = results[0] is Map
          ? Map<String, dynamic>.from(results[0] as Map)
          : <String, dynamic>{};

      final profile = results[5] is Map
          ? Map<String, dynamic>.from(results[5] as Map)
          : <String, dynamic>{};

      setState(() {
        users = _asInt(overview['users']);
        books = _asInt(overview['books']);
        borrowed = _asInt(overview['borrowed']);
        reservations = _asInt(overview['reservations']);

        usersList = _mapList(results[1]['users']);
        booksList = _mapList(results[2]['books']);
        reservationsList = _mapList(results[3]['reservations']);
        historyList = _mapList(results[4]['history']);

        currentUserId = _asInt(profile['id']);
        _hasLoaded = true;
      });
    } catch (exception) {
      if (!mounted) return;

      if (!_hasLoaded) {
        setState(() => error = _cleanError(exception));
      } else {
        _message(
            'Could not refresh the dashboard. Your previous data is still shown.');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  static const List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem('Overview', Icons.dashboard_rounded),
    _AdminMenuItem('Users', Icons.people_alt_rounded),
    _AdminMenuItem('Books', Icons.menu_book_rounded),
    _AdminMenuItem('Borrowing', Icons.swap_horiz_rounded),
    _AdminMenuItem('Reservations', Icons.event_note_rounded),
  ];

  void _selectSection(String value) {
    setState(() => _section = value);
  }

  Future<void> _openPage(String route) async {
    await Navigator.pushNamed(context, route);

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Do you want to leave the admin dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
        (route) => false,
      );
    } catch (exception) {
      _message(_cleanError(exception));
    }
  }

  // ------------------------------------------------------------
  // USER MANAGEMENT
  // ------------------------------------------------------------

  List<Map<String, dynamic>> get _visibleUsers {
    final query = _userSearch.trim().toLowerCase();

    if (query.isEmpty) return usersList;

    return usersList.where((user) {
      final content = '${user['name'] ?? ''} '
              '${user['email'] ?? ''} '
              '${user['role'] ?? ''}'
          .toLowerCase();

      return content.contains(query);
    }).toList();
  }

  Future<void> changeUserRole(int userId, String role) async {
    if (userId == currentUserId) {
      _message('You cannot change your own administrator role here.');
      return;
    }

    try {
      await Api.request(
        'PUT',
        '/admin/users/$userId/role',
        body: {'role': role},
      );

      _message('Account role updated to $role.');
      await loadDashboard();
    } catch (exception) {
      _message(_cleanError(exception));
    }
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    final id = _asInt(user['id']);
    final name = _str(user['name']).trim();
    final role = _str(user['role']).toLowerCase();

    if (id == currentUserId) {
      _message('You cannot delete your own active account.');
      return;
    }

    if (role == 'admin') {
      _message('Administrator accounts are protected from this delete action.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.person_remove_alt_1_rounded,
          color: danger,
          size: 34,
        ),
        title: const Text(
          'Delete this user?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Delete ${name.isEmpty ? 'this account' : name} and its account records? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete user'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.request('DELETE', '/admin/users/$id');

      _message('User account deleted.');
      await loadDashboard();
    } catch (exception) {
      _message(_cleanError(exception));
    }
  }

  void _showUserHistory(Map<String, dynamic> user) {
    final userId = _asInt(user['id']);
    final name = _str(user['name']).trim();
    final email = _str(user['email']);

    final entries = historyList.where((entry) {
      return _asInt(entry['user_id']) == userId;
    }).toList()
      ..sort((a, b) {
        final first =
            DateTime.tryParse(_str(a['created_at'])) ?? DateTime(1970);
        final second =
            DateTime.tryParse(_str(b['created_at'])) ?? DateTime(1970);

        return second.compareTo(first);
      });

    final borrowedEntries = entries.where((entry) {
      return _str(entry['action']).toLowerCase() == 'borrowed';
    }).length;

    final returnedEntries = entries.where((entry) {
      return _str(entry['action']).toLowerCase() == 'returned';
    }).length;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: background,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          name.isEmpty ? 'User borrowing history' : '$name\'s history',
          style: const TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 610,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _smallMetric(
                      'Borrowed records',
                      borrowedEntries,
                      lavender,
                      indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallMetric(
                      'Returned records',
                      returnedEntries,
                      paleGreen,
                      success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'ACTIVITY RECORDS',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          'No borrowing or return records found for this user.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: border),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final action = _str(entry['action']).toLowerCase();
                          final isBorrow = action == 'borrowed';
                          final date = _formatDate(entry['created_at']);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isBorrow ? lavender : paleGreen,
                              child: Icon(
                                isBorrow
                                    ? Icons.menu_book_rounded
                                    : Icons.assignment_return_rounded,
                                color: isBorrow ? indigo : success,
                              ),
                            ),
                            title: Text(
                              _str(entry['title']).isEmpty
                                  ? 'Unknown book'
                                  : _str(entry['title']),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${action.isEmpty ? 'Activity' : _titleCase(action)}'
                              ' • $date',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Icon(
                              isBorrow
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: isBorrow ? indigo : success,
                              size: 18,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(
    String label,
    int value,
    Color color,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 23,
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOK MANAGEMENT
  // ------------------------------------------------------------

  List<Map<String, dynamic>> get _visibleBooks {
    final query = _bookSearch.trim().toLowerCase();

    if (query.isEmpty) return booksList;

    return booksList.where((book) {
      final content = '${book['title'] ?? ''} '
              '${book['author'] ?? ''} '
              '${book['genre'] ?? ''} '
              '${book['submitted_by_name'] ?? ''} '
              '${book['submitted_by_email'] ?? ''}'
          .toLowerCase();

      return content.contains(query);
    }).toList();
  }

  Future<void> _addBook() async {
    await _openPage('/add-book');
  }

  Future<void> editBook(Map<String, dynamic> book) async {
    final id = _asInt(book['id']);

    final titleController = TextEditingController(text: _str(book['title']));
    final authorController = TextEditingController(text: _str(book['author']));
    final genreController = TextEditingController(text: _str(book['genre']));
    final yearController = TextEditingController(
      text: _str(book['published_year']).isEmpty
          ? '2024'
          : _str(book['published_year']),
    );
    final ratingController = TextEditingController(
      text: _str(book['rating']).isEmpty ? '0' : _str(book['rating']),
    );
    final copiesController = TextEditingController(
      text: _str(book['available_copies']).isEmpty
          ? '0'
          : _str(book['available_copies']),
    );
    final coverController =
        TextEditingController(text: _str(book['cover_url']));
    final descriptionController =
        TextEditingController(text: _str(book['description']));

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Edit book',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formField(titleController, 'Book title'),
                  _formField(authorController, 'Author'),
                  _formField(genreController, 'Genre'),
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          yearController,
                          'Published year',
                          numeric: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _formField(
                          ratingController,
                          'Rating (0–5)',
                          numeric: true,
                        ),
                      ),
                    ],
                  ),
                  _formField(
                    copiesController,
                    'Available copies',
                    numeric: true,
                  ),
                  _formField(coverController, 'Cover image URL'),
                  _formField(
                    descriptionController,
                    'Description',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      );

      if (saved != true) return;

      final year = int.tryParse(yearController.text.trim());
      final rating = double.tryParse(ratingController.text.trim());
      final copies = int.tryParse(copiesController.text.trim());

      if (titleController.text.trim().isEmpty ||
          authorController.text.trim().isEmpty ||
          genreController.text.trim().isEmpty ||
          year == null ||
          rating == null ||
          copies == null) {
        _message('Please complete the required fields with valid numbers.');
        return;
      }

      await Api.request(
        'PUT',
        '/admin/books/$id',
        body: {
          'title': titleController.text.trim(),
          'author': authorController.text.trim(),
          'genre': genreController.text.trim(),
          'published_year': year,
          'rating': rating,
          'available_copies': copies,
          'cover_url': coverController.text.trim(),
          'description': descriptionController.text.trim(),
        },
      );

      _message('Book updated successfully.');
      await loadDashboard();
    } catch (exception) {
      _message(_cleanError(exception));
    } finally {
      titleController.dispose();
      authorController.dispose();
      genreController.dispose();
      yearController.dispose();
      ratingController.dispose();
      copiesController.dispose();
      coverController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.multiline,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> deleteBook(int bookId) async {
    final book = booksList.where((item) => _asInt(item['id']) == bookId);

    final title = book.isEmpty ? 'this book' : _str(book.first['title']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: danger,
          size: 34,
        ),
        title: const Text(
          'Delete this book?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove "$title" from the library? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete book'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.request('DELETE', '/admin/books/$bookId');
      _message('Book deleted successfully.');
      await loadDashboard();
    } catch (exception) {
      _message(_cleanError(exception));
    }
  }

  // ------------------------------------------------------------
  // SEARCH AND HISTORY
  // ------------------------------------------------------------

  List<Map<String, dynamic>> get _visibleHistory {
    final query = _historySearch.trim().toLowerCase();

    return historyList.where((entry) {
      final action = _str(entry['action']).toLowerCase();

      if (_historyFilter == 'Borrowed' && action != 'borrowed') {
        return false;
      }

      if (_historyFilter == 'Returned' && action != 'returned') {
        return false;
      }

      if (query.isEmpty) return true;

      final content = '${entry['user_name'] ?? ''} '
              '${entry['user_email'] ?? ''} '
              '${entry['title'] ?? ''} '
              '${entry['author'] ?? ''} '
              '${entry['action'] ?? ''}'
          .toLowerCase();

      return content.contains(query);
    }).toList();
  }

  DateTime? _date(dynamic value) {
    return DateTime.tryParse(_str(value))?.toLocal();
  }

  String _formatDate(dynamic value) {
    final date = _date(value);
    if (date == null) return 'Date unavailable';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  int _activityCountForDay(DateTime day) {
    return historyList.where((entry) {
      final date = _date(entry['created_at']);

      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).length;
  }

  List<int> get _weeklyCounts {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return List<int>.generate(7, (index) {
      return _activityCountForDay(monday.add(Duration(days: index)));
    });
  }

  // ------------------------------------------------------------
  // REUSABLE UI
  // ------------------------------------------------------------

  Widget _pageShell(
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return RefreshIndicator(
      color: indigo,
      onRefresh: loadDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 600 ? 16.0 : 26.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, 24, padding, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...children,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
    IconData icon = Icons.grid_view_rounded,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D1030),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: indigo, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: border),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _emptyState(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: indigo, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: indigo),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // OVERVIEW
  // ------------------------------------------------------------

  Widget _overviewPage() {
    return _pageShell(
      'Library Overview',
      'Monitor BookWise accounts, books, and borrowing activity.',
      [
        _hero(),
        const SizedBox(height: 23),
        _statsGrid(),
        const SizedBox(height: 23),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 850) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _activityChart()),
                  const SizedBox(width: 18),
                  Expanded(child: _recentActivity()),
                ],
              );
            }

            return Column(
              children: [
                _activityChart(),
                const SizedBox(height: 18),
                _recentActivity(),
              ],
            );
          },
        ),
        const SizedBox(height: 23),
        _quickActions(),
      ],
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, indigo, Color(0xFF6268C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 510;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BOOKWISE ADMIN CENTER',
                  style: TextStyle(
                    color: Color(0xFFE3E4FF),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Built for readers.\nDesigned for control.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.13,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage books, members, reservations, and borrowing records from one place.',
                style: TextStyle(
                  color: Color(0xFFE2E4FF),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 19),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  FilledButton.icon(
                    onPressed: _addBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navy,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add a book'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _selectSection('Users'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x99FFFFFF)),
                    ),
                    icon: const Icon(Icons.people_outline_rounded, size: 18),
                    label: const Text('Manage users'),
                  ),
                ],
              ),
            ],
          );

          final illustration = Container(
            width: compact ? 75 : 130,
            height: compact ? 75 : 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: compact ? 42 : 73,
              color: const Color(0xFFD8DAFF),
            ),
          );

          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: information),
                const SizedBox(width: 8),
                illustration,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 20),
              illustration,
            ],
          );
        },
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      _StatData(
        'REGISTERED USERS',
        users,
        Icons.people_alt_rounded,
        lavender,
        indigo,
        'Accounts in BookWise',
      ),
      _StatData(
        'LIBRARY BOOKS',
        books,
        Icons.menu_book_rounded,
        palePurple,
        const Color(0xFF7650AA),
        'Books in your collection',
      ),
      _StatData(
        'CURRENTLY BORROWED',
        borrowed,
        Icons.bookmark_added_rounded,
        const Color(0xFFE7F3FA),
        const Color(0xFF397BA6),
        'Active borrowing records',
      ),
      _StatData(
        'WAITING RESERVATIONS',
        reservations,
        Icons.event_note_rounded,
        paleYellow,
        const Color(0xFF98651D),
        'In the reservation queue',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _statCard(stat),
              ),
          ],
        );
      },
    );
  }

  Widget _statCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
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
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                color: muted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 19),
          Text(
            stat.label,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${stat.value}',
            style: const TextStyle(
              color: ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.description,
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _activityChart() {
    final counts = _weeklyCounts;
    final maxCount = counts.fold<int>(
        0, (previous, value) => value > previous ? value : previous);
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));

    return _panel(
      title: 'Library activity',
      subtitle: 'Borrowing and returns this week',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 200,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${counts[i]}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: maxCount == 0
                                  ? 8
                                  : 18 + 95 * counts[i] / maxCount,
                              decoration: BoxDecoration(
                                color: i == today.weekday - 1
                                    ? indigo
                                    : const Color(0xFFBFC3F3),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Text(
                      _days[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Week of ${monday.day}/${monday.month}/${monday.year}',
              style: const TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity() {
    final latest = List<Map<String, dynamic>>.from(historyList)
      ..sort((a, b) {
        final first =
            _date(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final second =
            _date(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);

        return second.compareTo(first);
      });

    return _panel(
      title: 'Recent activity',
      subtitle: 'Latest book movements',
      icon: Icons.history_rounded,
      action: TextButton(
        onPressed: () => _selectSection('Borrowing'),
        child: const Text('View all'),
      ),
      child: latest.isEmpty
          ? _emptyState(
              Icons.history_rounded,
              'No activity yet',
              'Borrowing and return records will appear here.',
            )
          : Column(
              children: [
                for (final entry in latest.take(5))
                  _historyTile(entry, compact: true),
              ],
            ),
    );
  }

  Widget _quickActions() {
    return _panel(
      title: 'Quick actions',
      subtitle: 'Common library administration tasks',
      icon: Icons.bolt_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _quickAction(
            Icons.add_circle_outline_rounded,
            'Add a book',
            _addBook,
          ),
          _quickAction(
            Icons.people_outline_rounded,
            'Manage users',
            () => _selectSection('Users'),
          ),
          _quickAction(
            Icons.menu_book_rounded,
            'Manage books',
            () => _selectSection('Books'),
          ),
          _quickAction(
            Icons.history_rounded,
            'Borrowing history',
            () => _selectSection('Borrowing'),
          ),
          _quickAction(
            Icons.event_note_rounded,
            'Reservations',
            () => _selectSection('Reservations'),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: indigo,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // USERS PAGE
  // ------------------------------------------------------------

  Widget _usersPage() {
    return _pageShell(
      'User Management',
      'Search accounts, review each reader’s history, and manage permissions.',
      [
        _panel(
          title: 'Registered users',
          subtitle: '${_visibleUsers.length} matching accounts',
          icon: Icons.people_alt_rounded,
          action: IconButton(
            tooltip: 'Refresh',
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: indigo),
          ),
          child: Column(
            children: [
              _searchField(
                hint: 'Search name, email, or role',
                onChanged: (value) => setState(() => _userSearch = value),
              ),
              const SizedBox(height: 12),
              if (_visibleUsers.isEmpty)
                _emptyState(
                  Icons.people_outline_rounded,
                  'No users found',
                  'Try a different search term.',
                )
              else
                for (final user in _visibleUsers) _userCard(user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final id = _asInt(user['id']);
    final name = _str(user['name']).trim();
    final email = _str(user['email']);
    final role =
        _str(user['role']).isEmpty ? 'user' : _str(user['role']).toLowerCase();
    final isAdmin = role == 'admin';
    final isCurrentUser = id == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 570;

          final details = Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: lavender,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: indigo,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 7,
                      children: [
                        Text(
                          name.isEmpty ? 'Unnamed user' : name,
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (isCurrentUser) _badge('YOU', lavender, indigo),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Joined ${_formatDate(user['created_at'])}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showUserHistory(user),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              if (!isCurrentUser)
                PopupMenuButton<String>(
                  tooltip: 'Change role',
                  onSelected: (value) {
                    if (value != role) changeUserRole(id, value);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'user',
                      child: Text('Set as reader'),
                    ),
                    PopupMenuItem(
                      value: 'admin',
                      child: Text('Set as administrator'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: indigo,
                      size: 18,
                    ),
                  ),
                ),
              if (!isAdmin && !isCurrentUser)
                IconButton(
                  tooltip: 'Delete user',
                  onPressed: () => deleteUser(user),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: danger,
                  ),
                )
              else if (isAdmin)
                _badge('ADMIN', palePurple, indigo),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String label, Color color, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOKS PAGE
  // ------------------------------------------------------------

  Widget _booksPage() {
    return _pageShell(
      'Book Management',
      'Manage every book in the library, including reader-submitted books.',
      [
        _panel(
          title: 'Library collection',
          subtitle: '${_visibleBooks.length} matching books',
          icon: Icons.menu_book_rounded,
          action: FilledButton.icon(
            onPressed: _addBook,
            style: FilledButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add book'),
          ),
          child: Column(
            children: [
              _searchField(
                hint: 'Search title, author, genre, or submitter',
                onChanged: (value) => setState(() => _bookSearch = value),
              ),
              const SizedBox(height: 12),
              if (_visibleBooks.isEmpty)
                _emptyState(
                  Icons.menu_book_outlined,
                  'No books found',
                  'Try another search or add a book to the library.',
                )
              else
                for (final book in _visibleBooks) _bookCard(book),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookCard(Map<String, dynamic> book) {
    final title = _str(book['title']);
    final author = _str(book['author']);
    final genre = _str(book['genre']);
    final copies = _asInt(book['available_copies']);
    final year = _str(book['published_year']);
    final submitter = _str(book['submitted_by_name']).trim();
    final email = _str(book['submitted_by_email']).trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navy, indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFFD8DAFF),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Untitled book' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$author${year.isEmpty ? '' : ' • $year'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _badge(genre.isEmpty ? 'Uncategorized' : genre, lavender,
                        indigo),
                    _badge(
                      '$copies available',
                      copies > 0 ? paleGreen : const Color(0xFFFFE9ED),
                      copies > 0 ? success : danger,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  submitter.isNotEmpty
                      ? 'Added by $submitter'
                      : email.isNotEmpty
                          ? 'Submitted by $email'
                          : 'Library book',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Book actions',
            onSelected: (value) {
              if (value == 'edit') editBook(book);
              if (value == 'delete') deleteBook(_asInt(book['id']));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 9),
                    Text('Edit book'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: danger),
                    SizedBox(width: 9),
                    Text('Delete book'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: muted),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BORROWING HISTORY
  // ------------------------------------------------------------

  Widget _borrowingPage() {
    return _pageShell(
      'Borrowing & Returns',
      'Review who borrowed books, which books were returned, and when.',
      [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 600
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _miniSummary(
                    'Borrowed records',
                    historyList
                        .where((entry) =>
                            _str(entry['action']).toLowerCase() == 'borrowed')
                        .length,
                    lavender,
                    indigo,
                    Icons.bookmark_add_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _miniSummary(
                    'Returned records',
                    historyList
                        .where((entry) =>
                            _str(entry['action']).toLowerCase() == 'returned')
                        .length,
                    paleGreen,
                    success,
                    Icons.assignment_return_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 19),
        _panel(
          title: 'All book transactions',
          subtitle: '${_visibleHistory.length} matching records',
          icon: Icons.history_rounded,
          child: Column(
            children: [
              _searchField(
                hint: 'Search by reader, email, book, or action',
                onChanged: (value) => setState(() => _historySearch = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final filter in ['All', 'Borrowed', 'Returned'])
                      ChoiceChip(
                        label: Text(filter),
                        selected: _historyFilter == filter,
                        selectedColor: lavender,
                        labelStyle: TextStyle(
                          color: _historyFilter == filter ? indigo : muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                        onSelected: (_) => setState(() {
                          _historyFilter = filter;
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_visibleHistory.isEmpty)
                _emptyState(
                  Icons.history_rounded,
                  'No records found',
                  'Borrowing and return transactions will appear here.',
                )
              else
                for (final entry in _visibleHistory) _historyTile(entry),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniSummary(
    String label,
    int value,
    Color color,
    Color foreground,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(
    Map<String, dynamic> entry, {
    bool compact = false,
  }) {
    final action = _str(entry['action']).toLowerCase();
    final isBorrowed = action == 'borrowed';
    final title = _str(entry['title']);
    final user = _str(entry['user_name']);
    final email = _str(entry['user_email']);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isBorrowed ? lavender : paleGreen,
            child: Icon(
              isBorrowed
                  ? Icons.menu_book_rounded
                  : Icons.assignment_return_rounded,
              color: isBorrowed ? indigo : success,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Unknown book' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  compact
                      ? '$user • ${_titleCase(action)}'
                      : '${user.isEmpty ? email : user}'
                          '${email.isEmpty || compact ? '' : ' • $email'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_titleCase(action)} • ${_formatDate(entry['created_at'])}',
                  style: TextStyle(
                    color: isBorrowed ? indigo : success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
  // RESERVATIONS
  // ------------------------------------------------------------

  Widget _reservationsPage() {
    return _pageShell(
      'Reservations',
      'Monitor the reservation queue and identify readers waiting for a book.',
      [
        _panel(
          title: 'Reservation queue',
          subtitle: '${reservationsList.length} reservation records',
          icon: Icons.event_note_rounded,
          action: IconButton(
            tooltip: 'Refresh',
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: indigo),
          ),
          child: reservationsList.isEmpty
              ? _emptyState(
                  Icons.event_available_outlined,
                  'No reservations yet',
                  'Waiting reservations will be listed here.',
                )
              : Column(
                  children: [
                    for (final reservation in reservationsList)
                      _reservationTile(reservation),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _reservationTile(Map<String, dynamic> item) {
    final status = _str(item['status']).toLowerCase();
    final position = _asInt(item['queue_position']);
    final waiting = status == 'waiting';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 50,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _str(item['title']).isEmpty
                      ? 'Unknown book'
                      : _str(item['title']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_str(item['user_name'])} • ${_str(item['user_email'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Position: $position • ${_formatDate(item['created_at'])}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _badge(
            status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
            waiting ? paleYellow : lavender,
            waiting ? const Color(0xFF98651D) : indigo,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SIDEBAR AND MAIN CONTENT
  // ------------------------------------------------------------

  Widget _sidebar() {
    return Container(
      width: 232,
      color: navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 23, 17, 22),
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7079E8), indigo],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BookWise',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ADMINISTRATION',
                          style: TextStyle(
                            color: Color(0xFFBFC4EE),
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: Color(0xFF9299CA),
                  letterSpacing: 1.3,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final item in _menuItems) _sidebarItem(item),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFC8CCFF),
                      size: 25,
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Admin access',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage library resources and accounts.',
                      style: TextStyle(
                        color: Color(0xFFCFD2EF),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(_AdminMenuItem item) {
    final selected = _section == item.label;
    final count = switch (item.label) {
      'Users' => usersList.length,
      'Books' => booksList.length,
      'Borrowing' => historyList.length,
      'Reservations' => reservationsList.length,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      child: Material(
        color: selected ? indigo : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selectSection(item.label),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: selected ? Colors.white : const Color(0xFFD0D4EE),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD0D4EE),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF969DC8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileMenu() {
    return Container(
      color: navy,
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        scrollDirection: Axis.horizontal,
        children: [
          for (final item in _menuItems)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: TextButton.icon(
                onPressed: () => _selectSection(item.label),
                icon: Icon(item.icon, size: 17),
                label: Text(item.label),
                style: TextButton.styleFrom(
                  backgroundColor:
                      _section == item.label ? indigo : Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionContent() {
    switch (_section) {
      case 'Users':
        return _usersPage();
      case 'Books':
        return _booksPage();
      case 'Borrowing':
        return _borrowingPage();
      case 'Reservations':
        return _reservationsPage();
      default:
        return _overviewPage();
    }
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: danger,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to load the admin dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                error ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loadDashboard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: indigo,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'BookWise Admin',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: indigo,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh data',
            onPressed: loading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: indigo),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded, color: indigo),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_hasLoaded && loading
          ? const Center(
              child: CircularProgressIndicator(color: indigo),
            )
          : !_hasLoaded && error != null
              ? _errorState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1000) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sidebar(),
                          Expanded(child: _sectionContent()),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _mobileMenu(),
                        Expanded(child: _sectionContent()),
                      ],
                    );
                  },
                ),
    );
  }
}

class _StatData {
  const _StatData(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.foreground,
    this.description,
  );

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color foreground;
  final String description;
}

class _AdminMenuItem {
  const _AdminMenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
