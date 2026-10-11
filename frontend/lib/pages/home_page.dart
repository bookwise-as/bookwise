import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ------------------------------------------------------------
  // BOOKWISE THEME
  // ------------------------------------------------------------

  static const Color _navy = Color(0xFF191B3A);
  static const Color _indigo = Color(0xFF454AA6);
  static const Color _lavender = Color(0xFFE8E9FF);
  static const Color _background = Color(0xFFF5F6FC);
  static const Color _white = Colors.white;
  static const Color _muted = Color(0xFF777B99);
  static const Color _border = Color(0xFFE7E8F2);
  static const Color _softBlue = Color(0xFFF0F0FF);

  // A reading-space photograph used behind the welcome banner.
  static const String _heroImage =
      'https://images.unsplash.com/photo-1507842217343-583bb7270b66'
      '?auto=format&fit=crop&w=1400&q=80';

  // ------------------------------------------------------------
  // QUOTE COLLECTION
  // ------------------------------------------------------------

  static const List<Map<String, String>> _quotes = [
    {
      'quote': 'A room without books is like a body without a soul.',
      'author': 'Cicero',
    },
    {
      'quote': 'There is no friend as loyal as a book.',
      'author': 'Ernest Hemingway',
    },
    {
      'quote': 'Today a reader, tomorrow a leader.',
      'author': 'Margaret Fuller',
    },
    {
      'quote': 'Books are a uniquely portable magic.',
      'author': 'Stephen King',
    },
    {
      'quote': 'A book is a dream that you hold in your hands.',
      'author': 'Neil Gaiman',
    },
    {
      'quote': 'The more that you read, the more things you will know.',
      'author': 'Dr. Seuss',
    },
    {
      'quote':
          'Reading gives us someplace to go when we have to stay where we are.',
      'author': 'Mason Cooley',
    },
  ];

  // ------------------------------------------------------------
  // BOOK COVER ISBN MAPPING
  // ------------------------------------------------------------

  // Recognized books use ISBN-based cover lookups rather than
  // unrelated decorative photographs.
  static const Map<String, String> _bookIsbns = {
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

  // ------------------------------------------------------------
  // MONTHLY CELEBRATIONS
  // ------------------------------------------------------------

  static const List<_MonthlyCelebration> _celebrations = [
    _MonthlyCelebration(
      month: 1,
      title: 'Fresh Starts, New Chapters',
      tag: 'NEW YEAR READING',
      description: 'Start the year with a new story, a fresh perspective, '
          'and a reading goal of your own.',
      activity: 'Choose a book for your next chapter.',
      icon: Icons.auto_awesome_rounded,
    ),
    _MonthlyCelebration(
      month: 2,
      title: 'Art and Imagination',
      tag: 'NATIONAL ARTS MONTH',
      description: 'Discover books that celebrate creativity, illustration, '
          'poetry, and imagination.',
      activity: 'Read something that inspires your creativity.',
      icon: Icons.palette_outlined,
    ),
    _MonthlyCelebration(
      month: 3,
      title: 'Women Who Inspire',
      tag: 'WOMEN’S MONTH',
      description: 'Discover the stories, achievements, and ideas of women '
          'who have shaped our world.',
      activity: 'Explore a biography or a book by a woman author.',
      icon: Icons.auto_stories_rounded,
    ),
    _MonthlyCelebration(
      month: 4,
      title: 'Celebrate Literature',
      tag: 'WORLD BOOK DAY · APR 23',
      description: 'Celebrate books, authors, imagination, and the joy '
          'of sharing a great story.',
      activity: 'Recommend a book to a friend.',
      icon: Icons.menu_book_rounded,
    ),
    _MonthlyCelebration(
      month: 5,
      title: 'Heritage in Every Story',
      tag: 'HERITAGE MONTH',
      description: 'Explore stories that preserve traditions, memories, '
          'and the experiences of different communities.',
      activity: 'Discover a book about culture or history.',
      icon: Icons.account_balance_outlined,
    ),
    _MonthlyCelebration(
      month: 6,
      title: 'Read for a Greener World',
      tag: 'ENVIRONMENT MONTH',
      description: 'Explore stories about nature, sustainability, '
          'and our planet.',
      activity: 'Learn something new about the natural world.',
      icon: Icons.eco_outlined,
    ),
    _MonthlyCelebration(
      month: 7,
      title: 'Young Readers, Big Dreams',
      tag: 'CHILDREN’S STORIES',
      description: 'Celebrate stories that spark curiosity and make '
          'reading enjoyable for young minds.',
      activity: 'Share a favorite story with a young reader.',
      icon: Icons.toys_outlined,
    ),
    _MonthlyCelebration(
      month: 8,
      title: 'Language and Identity',
      tag: 'BUWAN NG WIKA',
      description: 'Celebrate Filipino languages and culture through '
          'stories, poetry, and literature.',
      activity: 'Read a story in a language you love.',
      icon: Icons.translate_rounded,
    ),
    _MonthlyCelebration(
      month: 9,
      title: 'Literacy for Everyone',
      tag: 'INTERNATIONAL LITERACY DAY · SEP 8',
      description: 'Celebrate the power of reading, education, and '
          'equal access to knowledge.',
      activity: 'Help someone discover the joy of reading.',
      icon: Icons.school_outlined,
    ),
    _MonthlyCelebration(
      month: 10,
      title: 'Mystery and Imagination',
      tag: 'SPOOKY STORY SEASON',
      description: 'Explore mysteries, gothic classics, and stories '
          'that keep you turning the pages.',
      activity: 'Try a mystery or suspense novel.',
      icon: Icons.nights_stay_outlined,
    ),
    _MonthlyCelebration(
      month: 11,
      title: 'Books Bring Us Together',
      tag: 'BOOK SHARING',
      description: 'Celebrate the conversations and friendships '
          'that begin with a shared book.',
      activity: 'Share a meaningful book with someone.',
      icon: Icons.diversity_3_outlined,
    ),
    _MonthlyCelebration(
      month: 12,
      title: 'Stories to Share',
      tag: 'HOLIDAY READING',
      description: 'Revisit a favorite story and share the gift '
          'of reading this season.',
      activity: 'Give a book or share a favorite passage.',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  static const List<String> _monthNames = [
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

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  String _name = 'Reader';

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _recommendations = [];

  bool _loading = true;
  bool _requestInProgress = false;
  bool _challengeCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  // ------------------------------------------------------------
  // LOADING
  // ------------------------------------------------------------

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );

      final savedUser = prefs.getString('user');

      String savedName = 'Reader';

      if (savedUser != null && savedUser.isNotEmpty) {
        final decoded = jsonDecode(savedUser);

        if (decoded is Map) {
          final candidate = decoded['name']?.toString();

          if (candidate != null && candidate.trim().isNotEmpty) {
            savedName = candidate;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _name = savedName;
        _challengeCompleted = prefs.getBool(_challengePreferenceKey) ?? false;
      });
    } catch (_) {
      // The homepage can still appear without saved preferences.
    }
  }

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
      // Keep other homepage content available if a request fails.
    }

    return <String, dynamic>{};
  }

  Future<void> _loadHome() async {
    if (_requestInProgress) return;

    _requestInProgress = true;

    if (mounted) {
      setState(() => _loading = true);
    }

    // Both data requests run at the same time.
    final requestFuture = Future.wait<Map<String, dynamic>>([
      _safeGet('/books?sort=rating'),
      _safeGet('/recommendations'),
    ]);

    try {
      await _loadSavedPreferences();

      final responses = await requestFuture;

      if (!mounted) return;

      setState(() {
        _books = _asMapList(responses[0]['books']);
        _recommendations = _asMapList(responses[1]['recommendations']);
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'We could not refresh your reading page. Please try again.',
        );
      }
    } finally {
      _requestInProgress = false;

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

  // ------------------------------------------------------------
  // DAILY CONTENT
  // ------------------------------------------------------------

  Map<String, String> get _quoteForToday {
    return _quotes[_dayOfYear % _quotes.length];
  }

  // ------------------------------------------------------------
  // REAL BOOK COVERS
  // ------------------------------------------------------------

  String _normaliseTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String? _coverUrl(Map<String, dynamic> book) {
    // Prefer an ISBN supplied by the API, if present.
    final suppliedIsbn =
        (book['isbn'] ?? book['isbn13'] ?? book['isbn_13'] ?? '')
            .toString()
            .replaceAll(RegExp(r'[^0-9Xx]'), '');

    if (suppliedIsbn.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/'
          '$suppliedIsbn-L.jpg?default=false';
    }

    // Find a known edition by the exact normalized title.
    final title = _normaliseTitle(
      (book['title'] ?? '').toString(),
    );

    final isbn = _bookIsbns[title];

    if (isbn != null) {
      return 'https://covers.openlibrary.org/b/isbn/'
          '$isbn-L.jpg?default=false';
    }

    // Don't present generic Unsplash photos as original book covers.
    final storedCover = (book['cover_url'] ??
            book['coverUrl'] ??
            book['image_url'] ??
            book['image'] ??
            '')
        .toString()
        .trim();

    if ((storedCover.startsWith('https://') ||
            storedCover.startsWith('http://')) &&
        !storedCover.toLowerCase().contains('unsplash.com')) {
      return storedCover;
    }

    return null;
  }

  Widget _bookCover(
    Map<String, dynamic> book, {
    double width = 135,
    double height = 195,
  }) {
    final url = _coverUrl(book);
    final title = (book['title'] ?? 'Book').toString();

    if (url == null) {
      return SizedBox(
        width: width,
        height: height,
        child: _coverPlaceholder(title),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Container(
          color: _softBlue,
          padding: const EdgeInsets.all(4),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return const Center(
                child: CircularProgressIndicator(
                  color: _indigo,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _coverPlaceholder(title);
            },
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(String title) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _lavender,
            _background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: _indigo,
            size: 35,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'BOOKWISE',
            style: TextStyle(
              color: _indigo,
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PAGE LAYOUT
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHome,
          color: _indigo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
            children: [
              _header(),
              const SizedBox(height: 23),
              _heroBanner(),
              const SizedBox(height: 29),
              _sectionHeading(
                'A thought for today',
                'A little inspiration for your reading journey.',
              ),
              const SizedBox(height: 13),
              _quoteCard(),
              const SizedBox(height: 29),
              _sectionHeading(
                'Book of the Day',
                'One story selected for today.',
              ),
              const SizedBox(height: 13),
              _bookOfTheDayCard(),
              const SizedBox(height: 24),
              _readingChallenge(),
              const SizedBox(height: 31),
              _sectionHeading(
                'Monthly Celebrations',
                'A year of reading, culture, and discovery.',
              ),
              const SizedBox(height: 13),
              _monthlyCelebrations(),
              if (_loading) ...[
                const SizedBox(height: 20),
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: _indigo,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, _indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18454AA6),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: _white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BookWise',
                style: TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'A world between the pages',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _white,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: IconButton(
            tooltip: 'Open profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(
              Icons.person_outline_rounded,
              color: _indigo,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PHOTO HERO
  // ------------------------------------------------------------

  Widget _heroBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;

        return Container(
          height: compact ? 330 : 305,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A191B3A),
                blurRadius: 23,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _heroImage,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: _navy);
                },
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _navy.withValues(alpha: 0.98),
                      _navy.withValues(alpha: 0.88),
                      _indigo.withValues(alpha: 0.45),
                    ],
                    stops: const [0.0, 0.54, 1.0],
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: -22,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: compact ? 135 : 175,
                  color: _white.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'YOUR PERSONAL READING SPACE',
                        style: TextStyle(
                          color: _white,
                          fontSize: 9,
                          letterSpacing: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hello,\n$_name.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _white,
                        fontSize: compact ? 30 : 38,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(
                      width: 345,
                      child: Text(
                        'Slow down, open a book, and discover '
                        'a new perspective today.',
                        style: TextStyle(
                          color: Color(0xFFE5E6FF),
                          height: 1.55,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    Wrap(
                      spacing: 10,
                      runSpacing: 9,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/catalog');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _white,
                            foregroundColor: _navy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore the library',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _todayDate(),
                          style: const TextStyle(
                            color: Color(0xFFE5E6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  String _todayDate() {
    final today = DateTime.now();

    return '${_monthNames[today.month - 1]} '
        '${today.day}, ${today.year}';
  }

  // ------------------------------------------------------------
  // SECTION HEADING
  // ------------------------------------------------------------

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // QUOTE OF THE DAY
  // ------------------------------------------------------------

  Widget _quoteCard() {
    final quote = _quoteForToday;

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070F1240),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            bottom: -9,
            child: Icon(
              Icons.format_quote_rounded,
              size: 81,
              color: _lavender.withValues(alpha: 0.9),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_lavender, _softBlue],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: _indigo,
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUOTE OF THE DAY',
                      style: TextStyle(
                        color: _indigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '“${quote['quote']}”',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '— ${quote['author']}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _copyQuote,
                          tooltip: 'Copy quote',
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: _softBlue,
                            foregroundColor: _indigo,
                          ),
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyQuote() async {
    final quote = _quoteForToday;

    await Clipboard.setData(
      ClipboardData(
        text: '“${quote['quote']}” — ${quote['author']}',
      ),
    );

    if (mounted) {
      _showMessage('Quote copied to clipboard.');
    }
  }

  // ------------------------------------------------------------
  // BOOK OF THE DAY
  // ------------------------------------------------------------

  Map<String, dynamic>? get _bookOfTheDay {
    final source = _recommendations.isNotEmpty ? _recommendations : _books;

    if (source.isEmpty) return null;

    return source[_dayOfYear % source.length];
  }

  int get _dayOfYear {
    final today = DateTime.now();

    return today.difference(DateTime(today.year, 1, 1)).inDays;
  }

  Widget _bookOfTheDayCard() {
    final book = _bookOfTheDay;

    if (book == null) {
      return _emptyBookCard();
    }

    final title = (book['title'] ?? 'Untitled book').toString();
    final author = (book['author'] ?? 'Unknown author').toString();
    final genre = (book['genre'] ?? 'General').toString();
    final description = (book['description'] ??
            'Discover a new perspective in today’s featured read.')
        .toString();
    final rating = double.tryParse((book['rating'] ?? 0).toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F1240),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final coverWidth = compact ? 130.0 : 155.0;
          final coverHeight = compact ? 190.0 : 225.0;

          final cover = Center(
            child: _bookCover(
              book,
              width: coverWidth,
              height: coverHeight,
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _lavender,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'TODAY’S PICK',
                  style: TextStyle(
                    color: _indigo,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 23,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.55,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'by $author',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _bookTag(
                    Icons.category_outlined,
                    genre,
                  ),
                  _bookTag(
                    Icons.star_rounded,
                    rating.toStringAsFixed(1),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 17),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/catalog');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.menu_book_rounded,
                  size: 17,
                ),
                label: const Text(
                  'Explore the library',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cover,
                const SizedBox(height: 22),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: 23),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _bookTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _indigo, size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 115),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBookCard() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: _indigo,
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Your next favorite is waiting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'The featured book will appear once the library is available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DAILY READING CHALLENGE
  // ------------------------------------------------------------

  Future<void> _toggleChallenge() async {
    final completed = !_challengeCompleted;

    setState(() => _challengeCompleted = completed);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        _challengePreferenceKey,
        completed,
      );
    } catch (_) {
      // Keep the interactive checkbox usable for this session.
    }

    if (mounted && completed) {
      _showMessage('Wonderful! You completed today’s reading goal.');
    }
  }

  String get _challengePreferenceKey {
    final today = DateTime.now();

    return 'bookwise_reading_challenge_'
        '${today.year}-${today.month}-${today.day}';
  }

  Widget _readingChallenge() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _lavender,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD9DBFA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: _indigo,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY’S LITTLE CHALLENGE',
                  style: TextStyle(
                    color: _indigo,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _challengeCompleted
                      ? 'Your reading goal is complete!'
                      : 'Make 15 minutes for a book.',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _challengeCompleted
                      ? 'Well done. Come back tomorrow for a new goal.'
                      : 'A little reading can make room for a big idea.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: _challengeCompleted,
            activeColor: _indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (_) => _toggleChallenge(),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MONTHLY CELEBRATIONS
  // ------------------------------------------------------------

  _MonthlyCelebration get _currentCelebration {
    return _celebrations.firstWhere(
      (item) => item.month == DateTime.now().month,
    );
  }

  Widget _monthlyCelebrations() {
    final featured = _currentCelebration;
    final month = DateTime.now().month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large photo-based feature for the current month.
        Container(
          height: 245,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _celebrationImage(month),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_navy, _indigo],
                      ),
                    ),
                  );
                },
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _navy.withValues(alpha: 0.97),
                      _navy.withValues(alpha: 0.83),
                      _indigo.withValues(alpha: 0.40),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '${_monthNames[month - 1].toUpperCase()} '
                        'CELEBRATION',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 9,
                          letterSpacing: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      featured.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 23,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 420,
                      child: Text(
                        featured.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE6E7FF),
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFD8D9FF),
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            featured.activity,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your year of reading',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Text(
              '12 monthly themes',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 650
                    ? 3
                    : constraints.maxWidth >= 400
                        ? 2
                        : 1;

            const spacing = 12.0;

            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final celebration in _celebrations)
                  SizedBox(
                    width: width,
                    child: _celebrationCard(
                      celebration,
                      isCurrent: celebration.month == month,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Photos used for celebration banners, not as book covers.
  String _celebrationImage(int month) {
    const images = [
      'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=900&q=75',
      'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=900&q=75',
      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=900&q=75',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=900&q=75',
      'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=900&q=75',
      'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=900&q=75',
    ];

    return images[(month - 1) % images.length];
  }

  Widget _celebrationCard(
    _MonthlyCelebration celebration, {
    required bool isCurrent,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 165),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCurrent ? _lavender : _white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isCurrent ? _indigo : _border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: isCurrent ? _indigo : _softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  celebration.icon,
                  color: isCurrent ? _white : _indigo,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _indigo,
                  size: 17,
                ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            _monthNames[celebration.month - 1].toUpperCase(),
            style: const TextStyle(
              color: _indigo,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            celebration.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            celebration.tag,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            celebration.activity,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FOOTER
  // ------------------------------------------------------------

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: _indigo,
            size: 17,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'BookWise · Every book opens a new world.',
              textAlign: TextAlign.center,
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
}

// --------------------------------------------------------------
// MONTHLY CELEBRATION MODEL
// --------------------------------------------------------------

class _MonthlyCelebration {
  final int month;
  final String title;
  final String tag;
  final String description;
  final String activity;
  final IconData icon;

  const _MonthlyCelebration({
    required this.month,
    required this.title,
    required this.tag,
    required this.description,
    required this.activity,
    required this.icon,
  });
}
