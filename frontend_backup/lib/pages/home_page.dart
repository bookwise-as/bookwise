import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = 'Reader';
  List books = [];
  List recs = [];
  bool loading = true;
  String selectedMood = 'All';

  static const _quotes = [
    'A room without books is like a body without a soul. — Cicero',
    'There is no friend as loyal as a book. — Ernest Hemingway',
    'Today a reader, tomorrow a leader. — Margaret Fuller',
    'Books are a uniquely portable magic. — Stephen King',
    'The world belongs to those who read. — Rick Holland',
  ];

  static const _moods = ['All', 'Feel-good', 'Adventure', 'Mystery', 'Romance'];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final preferences = await SharedPreferences.getInstance();
    final user = jsonDecode(preferences.getString('user') ?? '{}');
    if (!mounted) return;
    setState(() => name = user['name'] ?? 'Reader');
    try {
      final booksResponse = await Api.request('GET', '/books');
      final recommendations = await Api.request('GET', '/recommendations');
      if (!mounted) return;
      setState(() {
        books = booksResponse['books'] ?? [];
        recs = recommendations['recommendations'] ?? [];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('We could not refresh your shelf. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'BookWise',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.account_circle_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF211A12),
                      Color(0xFF72521F),
                      Color(0xFFC8942E)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_stories,
                        color: Colors.white, size: 34),
                    const SizedBox(height: 18),
                    Text(
                      'Hello, $name',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your next chapter\nstarts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.pushNamed(context, '/catalog'),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explore the library'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (loading) const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 18),
              _quoteOfTheDay(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Books',
                      books.length.toString(),
                      Icons.menu_book_outlined,
                      const Color(0xFFEDE7F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat(
                      'For you',
                      recs.length.toString(),
                      Icons.auto_awesome,
                      const Color(0xFFFFF1D6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Make today a reading day',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/recommendations'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Small choices become your next favorite story.'),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: Row(
                  children: [
                    Expanded(
                        child: _quickAction(
                      context,
                      Icons.search_rounded,
                      'Browse books',
                      'Find your next read',
                      '/catalog',
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _quickAction(
                      context,
                      Icons.auto_awesome,
                      'For your mood',
                      'Personalized picks',
                      '/recommendations',
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'What are you in the mood for?',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _moods
                      .map(
                        (mood) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(mood),
                            selected: selectedMood == mood,
                            onSelected: (_) =>
                                setState(() => selectedMood = mood),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _bookForToday(),
              const SizedBox(height: 20),
              const Text(
                'Curated for your mood',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Personalized picks based on what you love to read.'),
              const SizedBox(height: 8),
              if (!loading && recs.isEmpty)
                Card(
                  color: const Color(0xFFFFF0C7),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title:
                        const Text('Your shelf is waiting for a little input.'),
                    subtitle: const Text(
                        'Favorite or borrow a book to unlock better picks.'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.pushNamed(context, '/catalog'),
                  ),
                ),
              ..._visibleRecommendations.take(5).map(
                    (book) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 5,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF0C7),
                          child: Icon(
                            Icons.book_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          book['title']?.toString() ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${book['author'] ?? 'Unknown author'} • ${book['genre'] ?? 'Unknown genre'}',
                        ),
                        trailing: Text(
                          '${book['rating'] ?? 0} ★',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );

  List get _visibleRecommendations {
    if (selectedMood == 'All') return recs;
    final keyword = selectedMood.toLowerCase().split('-').first.trim();
    final matches = recs
        .where((book) => '${book['genre'] ?? ''} ${book['title'] ?? ''}'
            .toString()
            .toLowerCase()
            .contains(keyword))
        .toList();
    return matches.isEmpty ? recs : matches;
  }

  String get _quoteForToday {
    final index =
        DateTime.now().difference(DateTime(2024, 1, 1)).inDays % _quotes.length;
    return _quotes[index];
  }

  Widget _quoteOfTheDay() => Card(
        color: const Color(0xFFFFF8E8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded,
                  color: Color(0xFFC8942E), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUOTE OF THE DAY',
                        style: TextStyle(
                            color: Color(0xFF8B641E),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(_quoteForToday,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bookForToday() {
    final book = _visibleRecommendations.isNotEmpty
        ? _visibleRecommendations.first
        : (books.isNotEmpty ? books.first : null);
    if (book == null) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A2818), Color(0xFF8B641E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD982),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  size: 36, color: Color(0xFF5A3B12)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOOK FITS FOR TODAY',
                      style: TextStyle(
                          color: Color(0xFFFFE8B0),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  Text(book['title']?.toString() ?? 'A story for you',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                      book['author']?.toString() ??
                          'Waiting on your next discovery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero),
                    onPressed: () => Navigator.pushNamed(context, '/catalog'),
                    child: const Text('Meet this book  →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, child: Icon(icon)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) =>
      Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFFFF0C7),
                  child: Icon(icon, color: const Color(0xFF8B641E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
