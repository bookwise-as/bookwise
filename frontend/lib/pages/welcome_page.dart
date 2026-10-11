import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color navy = Color(0xFF191B3A);
  static const Color navyLight = Color(0xFF25284D);
  static const Color indigo = Color(0xFF454AA6);
  static const Color lavender = Color(0xFFE8E9FF);
  static const Color background = Color(0xFFF7F8FE);
  static const Color textColor = Color(0xFF242644);
  static const Color muted = Color(0xFF777BA0);
  static const Color borderColor = Color(0xFFE7E8F3);

  void _openLogin(BuildContext context, {required bool signup}) {
    Navigator.of(context).pushNamed(
      signup ? '/signup' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final horizontalPadding = compact ? 16.0 : 28.0;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNavigation(context, compact),
                        const SizedBox(height: 28),

                        // Main hero section.
                        _buildHero(context, compact),

                        const SizedBox(height: 25),

                        // Short highlights.
                        _buildTrustRow(compact),

                        const SizedBox(height: 64),

                        // Features.
                        _buildSectionHeading(
                          eyebrow: 'THE BOOKWISE EXPERIENCE',
                          title: 'Make every reading moment count.',
                          description:
                              'Discover books that match your interests, '
                              'keep the stories you love, and find your '
                              'next great read.',
                          compact: compact,
                        ),

                        const SizedBox(height: 28),
                        _buildFeatures(),

                        const SizedBox(height: 68),

                        // How BookWise works.
                        _buildHowItWorks(compact),

                        const SizedBox(height: 68),

                        // Informational banner, without repeated buttons.
                        _buildCommunityBanner(compact),

                        const SizedBox(height: 30),

                        // Simple footer, without repeated buttons.
                        _buildFooter(compact),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // TOP NAVIGATION: two account buttons only.
  Widget _buildNavigation(BuildContext context, bool compact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    indigo,
                    Color(0xFF777CE0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BookWise',
                  style: TextStyle(
                    color: navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  'YOUR READING SPACE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: compact ? 4 : 10,
          children: [
            TextButton(
              onPressed: () => _openLogin(context, signup: false),
              style: TextButton.styleFrom(
                foregroundColor: indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => _openLogin(context, signup: true),
              style: FilledButton.styleFrom(
                backgroundColor: indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 13 : 19,
                  vertical: 14,
                ),
              ),
              child: const Text('Create account'),
            ),
          ],
        ),
      ],
    );
  }

  // MAIN HERO: two primary actions only.
  Widget _buildHero(BuildContext context, bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 23 : 42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navy,
            Color(0xFF303568),
            indigo,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 670;
          final copy = _heroCopy(context, narrow);

          final artwork = Padding(
            padding: EdgeInsets.only(
              top: narrow ? 12 : 0,
              left: narrow ? 0 : 15,
            ),
            child: SizedBox(
              height: narrow ? 215 : 270,
              child: _buildBookArtwork(),
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                artwork,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: copy),
              Expanded(flex: 5, child: artwork),
            ],
          );
        },
      ),
    );
  }

  Widget _heroCopy(BuildContext context, bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFD6D8FF),
                size: 15,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'YOUR NEXT CHAPTER STARTS HERE',
                  style: TextStyle(
                    color: Color(0xFFE0E2FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          'Find your next\nfavorite story.',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 39 : 51,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Discover books that speak to you, save the ones you love, '
          'and make your reading journey your own.',
          style: TextStyle(
            color: Color(0xFFD9DBF2),
            fontSize: 15,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 25),

        // Only two buttons inside the hero box.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _openLogin(context, signup: true),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text('Start reading'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => _openLogin(context, signup: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
              child: const Text('I have an account'),
            ),
          ],
        ),
      ],
    );
  }

  // Decorative book artwork; it does not create fake catalog records.
  Widget _buildBookArtwork() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final small = width < 320;
        final bookWidth = small ? width * 0.29 : 100.0;
        final bookHeight = small ? 137.0 : 160.0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: width * 0.05,
              top: 12,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 30,
              ),
            ),
            Positioned(
              left: width * 0.06,
              bottom: 24,
              child: Transform.rotate(
                angle: -0.10,
                child: _bookCover(
                  width: bookWidth,
                  height: bookHeight,
                  title: 'DREAM',
                  subtitle: 'Fantasy',
                  icon: Icons.nights_stay_rounded,
                  colors: const [
                    Color(0xFF777CE0),
                    Color(0xFF35396F),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * 0.34,
              bottom: 43,
              child: _bookCover(
                width: bookWidth,
                height: bookHeight,
                title: 'EXPLORE',
                subtitle: 'Adventure',
                icon: Icons.explore_rounded,
                colors: const [
                  Color(0xFFDBB4FF),
                  Color(0xFF7160B7),
                ],
              ),
            ),
            Positioned(
              left: width * 0.62,
              bottom: 25,
              child: Transform.rotate(
                angle: 0.10,
                child: _bookCover(
                  width: bookWidth,
                  height: bookHeight,
                  title: 'FEEL',
                  subtitle: 'Romance',
                  icon: Icons.favorite_rounded,
                  colors: const [
                    Color(0xFFE9A6CD),
                    Color(0xFF98528B),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: width * 0.44,
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFD98B).withValues(alpha: 0.9),
                size: 25,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bookCover({
    required double width,
    required double height,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(4, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: width * 0.34,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: width * 0.13,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: width * 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow(bool compact) {
    const items = [
      _TrustItem(
        Icons.auto_awesome_rounded,
        'Personalized picks',
      ),
      _TrustItem(
        Icons.favorite_border_rounded,
        'Your favorites',
      ),
      _TrustItem(
        Icons.people_outline_rounded,
        'A reading community',
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 17, color: indigo),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String description,
    required bool compact,
  }) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: indigo,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: navy,
            fontSize: compact ? 27 : 35,
            fontWeight: FontWeight.w900,
            height: 1.2,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width >= 900
            ? (width - 36) / 3
            : width >= 600
                ? (width - 18) / 2
                : width;

        const features = [
          _FeatureData(
            icon: Icons.auto_awesome_rounded,
            title: 'Discover your next read',
            description: 'Explore books and discover recommendations '
                'inspired by your interests and reading activity.',
            number: '01',
          ),
          _FeatureData(
            icon: Icons.favorite_rounded,
            title: 'Keep the books you love',
            description: 'Save your favorites and return to books '
                'you want to read or recommend again.',
            number: '02',
          ),
          _FeatureData(
            icon: Icons.menu_book_rounded,
            title: 'Manage your reading',
            description: 'Keep track of your borrowing history, '
                'returns, and book reservations in one place.',
            number: '03',
          ),
        ];

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final feature in features)
              SizedBox(
                width: cardWidth,
                child: _featureCard(feature),
              ),
          ],
        );
      },
    );
  }

  Widget _featureCard(_FeatureData feature) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  feature.icon,
                  color: indigo,
                  size: 25,
                ),
              ),
              const Spacer(),
              Text(
                feature.number,
                style: const TextStyle(
                  color: Color(0xFFB6B9D5),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            feature.title,
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            feature.description,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(bool compact) {
    const steps = [
      _StepData(
        '01',
        'Create your account',
        'Join BookWise to access your reading space and library features.',
        Icons.person_add_alt_1_rounded,
      ),
      _StepData(
        '02',
        'Explore and discover',
        'Browse the catalog, save favorites, and find recommendations.',
        Icons.search_rounded,
      ),
      _StepData(
        '03',
        'Make it your own',
        'Track reading activity and share books with the community.',
        Icons.auto_stories_rounded,
      ),
    ];

    return Column(
      children: [
        _buildSectionHeading(
          eyebrow: 'GETTING STARTED',
          title: 'Your reading journey, made simple.',
          description: 'Get started in a few simple steps and build '
              'a reading experience that works for you.',
          compact: compact,
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final cardWidth = width >= 900
                ? (width - 36) / 3
                : width >= 600
                    ? (width - 18) / 2
                    : width;

            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final step in steps)
                  SizedBox(
                    width: cardWidth,
                    child: _stepCard(step),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _stepCard(_StepData step) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              step.icon,
              color: indigo,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.number,
                  style: const TextStyle(
                    color: indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Informational banner without any additional account buttons.
  Widget _buildCommunityBanner(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 23 : 35),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Every great book starts with a discovery.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'Discover new stories, explore different genres, '
                'and share the books that inspire you.',
                style: TextStyle(
                  color: Color(0xFFD9DBF2),
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFFD0D4FF),
                      size: 18,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Discover. Read. Recommend.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (narrow) return content;

          return Row(
            children: [
              Expanded(flex: 5, child: content),
              const SizedBox(width: 30),
              const Expanded(
                flex: 2,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 115,
                  color: Color(0x77FFFFFF),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Simple footer with branding and slogan only.
  Widget _buildFooter(bool compact) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 15,
        runSpacing: 12,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: indigo,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'BookWise',
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            'Discover. Read. Recommend.',
            style: TextStyle(
              color: muted,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem {
  const _TrustItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.number,
  });

  final IconData icon;
  final String title;
  final String description;
  final String number;
}

class _StepData {
  const _StepData(
    this.number,
    this.title,
    this.description,
    this.icon,
  );

  final String number;
  final String title;
  final String description;
  final IconData icon;
}
