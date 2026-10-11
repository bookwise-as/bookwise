import 'package:flutter/material.dart';

import '../services/api.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const Color navy = Color(0xFF191B3A);
  static const Color indigo = Color(0xFF454AA6);
  static const Color lavender = Color(0xFFE8E9FF);
  static const Color background = Color(0xFFF6F7FC);
  static const Color muted = Color(0xFF777BA0);
  static const Color border = Color(0xFFE6E8F2);
  static const Color white = Colors.white;

  List history = [];
  bool loading = true;
  String? error;

  String searchQuery = '';
  String selectedFilter = 'All';

  final TextEditingController searchController = TextEditingController();

  final List<String> filters = [
    'All',
    'Borrowed',
    'Returned',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final response = await Api.request('GET', '/history');
      final result = response['history'];

      if (mounted) {
        setState(() {
          history = result is List ? result : [];
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String valueOf(dynamic item, String key, [String fallback = '']) {
    if (item is Map && item[key] != null) {
      final value = item[key].toString().trim();
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return fallback;
  }

  String normalizedAction(dynamic item) {
    return valueOf(item, 'action', 'activity')
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }

  bool isBorrowAction(dynamic item) {
    return normalizedAction(item).contains('borrow');
  }

  bool isReturnAction(dynamic item) {
    return normalizedAction(item).contains('return');
  }

  List get filteredHistory {
    final query = searchQuery.trim().toLowerCase();

    return history.where((item) {
      final title = valueOf(item, 'title', 'Untitled').toLowerCase();
      final author = valueOf(item, 'author', 'Unknown author').toLowerCase();
      final action = normalizedAction(item);

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          author.contains(query) ||
          action.contains(query);

      final matchesFilter = switch (selectedFilter) {
        'Borrowed' => isBorrowAction(item),
        'Returned' => isReturnAction(item),
        'Other' => !isBorrowAction(item) && !isReturnAction(item),
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get borrowedCount => history.where(isBorrowAction).length;

  int get returnedCount => history.where(isReturnAction).length;

  int get otherCount => history.length - borrowedCount - returnedCount;

  IconData actionIcon(dynamic item) {
    if (isBorrowAction(item)) return Icons.menu_book_rounded;
    if (isReturnAction(item)) return Icons.assignment_turned_in_rounded;
    return Icons.history_rounded;
  }

  Color actionColor(dynamic item) {
    if (isBorrowAction(item)) return indigo;
    if (isReturnAction(item)) return const Color(0xFF59658B);
    return muted;
  }

  Color actionBackground(dynamic item) {
    if (isBorrowAction(item)) return lavender;
    if (isReturnAction(item)) return const Color(0xFFF0F1F8);
    return const Color(0xFFF1F2F8);
  }

  String actionLabel(dynamic item) {
    final action = normalizedAction(item);

    if (isBorrowAction(item)) return 'BOOK BORROWED';
    if (isReturnAction(item)) return 'BOOK RETURNED';

    if (action.isEmpty || action == 'activity') {
      return 'READING ACTIVITY';
    }

    return action.toUpperCase();
  }

  DateTime? eventDate(dynamic item) {
    final raw = valueOf(item, 'created_at');
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String monthName(int month) {
    const months = [
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

    return months[month - 1];
  }

  String shortMonthName(int month) {
    return monthName(month).substring(0, 3);
  }

  String dateLabel(dynamic item) {
    final date = eventDate(item);

    if (date == null) return 'Date unavailable';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);

    if (eventDay == today) return 'Today';

    if (eventDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${monthName(date.month)} ${date.day}, ${date.year}';
  }

  String formattedTime(dynamic item) {
    final date = eventDate(item);

    if (date == null) return 'Time unavailable';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  bool isSameDay(dynamic first, dynamic second) {
    final a = eventDate(first);
    final b = eventDate(second);

    if (a == null || b == null) return a == null && b == null;

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String groupLabel(dynamic item) {
    final date = eventDate(item);

    if (date == null) return 'OTHER ACTIVITY';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return 'TODAY';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'YESTERDAY';
    }

    return '${shortMonthName(date.month).toUpperCase()} '
        '${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = filteredHistory;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 22,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading history',
              style: TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Your borrowing activity, in order',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: loading ? null : load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: indigo,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: loading && history.isNotEmpty
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: indigo,
                  backgroundColor: lavender,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: indigo,
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            _buildIntro(),
            const SizedBox(height: 24),
            _buildActivityOverview(),
            const SizedBox(height: 28),
            _buildSectionHeading(),
            const SizedBox(height: 14),
            _buildSearchField(),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 22),
            if (loading && history.isEmpty)
              _buildLoadingState()
            else if (error != null && history.isEmpty)
              _buildErrorState()
            else if (entries.isEmpty)
              _buildEmptyState()
            else
              ..._buildTimeline(entries),
            const SizedBox(height: 8),
            if (error != null && history.isNotEmpty) _buildRefreshWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: indigo,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Every chapter leaves a trace.',
                style: TextStyle(
                  color: navy,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Review the books you have borrowed and returned, '
            'along with your previous reading activity.',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOverview() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 19,
        horizontal: 8,
      ),
      child: Row(
        children: [
          _overviewItem(
            value: history.length,
            label: 'ACTIVITIES',
            icon: Icons.timeline_rounded,
          ),
          _overviewDivider(),
          _overviewItem(
            value: borrowedCount,
            label: 'BORROWED',
            icon: Icons.menu_book_rounded,
          ),
          _overviewDivider(),
          _overviewItem(
            value: returnedCount,
            label: 'RETURNED',
            icon: Icons.assignment_turned_in_outlined,
          ),
        ],
      ),
    );
  }

  Widget _overviewItem({
    required int value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: indigo),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 23,
              color: navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 0.5,
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewDivider() {
    return Container(
      width: 1,
      height: 65,
      color: border,
    );
  }

  Widget _buildSectionHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity timeline',
                style: TextStyle(
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your latest activity appears first.',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${filteredHistory.length} entries',
          style: const TextStyle(
            color: indigo,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (value) => setState(() => searchQuery = value),
      style: const TextStyle(
        color: navy,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search by book, author, or activity...',
        hintStyle: const TextStyle(
          color: muted,
          fontSize: 12,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: indigo,
        ),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  searchController.clear();
                  setState(() => searchQuery = '');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: muted,
                ),
              )
            : null,
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: indigo,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => selectedFilter = filter);
              },
              labelStyle: TextStyle(
                color: selected ? white : muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: white,
              selectedColor: indigo,
              side: BorderSide(
                color: selected ? indigo : border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTimeline(List entries) {
    final widgets = <Widget>[];

    for (var index = 0; index < entries.length; index++) {
      final item = entries[index];

      final isNewGroup = index == 0 || !isSameDay(entries[index - 1], item);

      if (isNewGroup) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                Text(
                  groupLabel(item),
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Divider(
                    height: 1,
                    color: border,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(_buildActivityItem(item));

      if (index != entries.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  Widget _buildActivityItem(dynamic item) {
    final title = valueOf(item, 'title', 'Untitled book');
    final author = valueOf(item, 'author', 'Unknown author');
    final color = actionColor(item);
    final iconBackground = actionBackground(item);

    return Container(
      decoration: BoxDecoration(
        color: white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              actionIcon(item),
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        actionLabel(item),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      formattedTime(item),
                      style: const TextStyle(
                        fontSize: 10,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by $author',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateLabel(item),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: indigo,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your reading history...',
              style: TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: indigo,
            size: 38,
          ),
          const SizedBox(height: 12),
          const Text(
            'History could not be loaded',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = searchQuery.isNotEmpty || selectedFilter != 'All';

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 32, 25, 32),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.auto_stories_outlined,
              color: indigo,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters ? 'No matching activities' : 'Your story starts here',
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasFilters
                ? 'Try another keyword or choose a different filter.'
                : 'Your borrowing and return activities will appear here '
                    'when you start borrowing books.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                  selectedFilter = 'All';
                });
              },
              child: const Text(
                'Clear filters',
                style: TextStyle(
                  color: indigo,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF946200),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not refresh history: $error',
              style: const TextStyle(
                color: Color(0xFF795414),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: loading ? null : load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF946200),
            ),
          ),
        ],
      ),
    );
  }
}
