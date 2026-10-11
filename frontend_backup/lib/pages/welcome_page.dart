import 'package:flutter/material.dart';

import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories, size: 32),
                          const SizedBox(width: 10),
                          const Text(
                            'BookWise',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _openLogin(context, false),
                            child: const Text('Sign in'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _openLogin(context, true),
                            child: const Text('Create account'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
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
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Flex(
                          direction: constraints.maxWidth > 700
                              ? Axis.horizontal
                              : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (constraints.maxWidth > 700)
                              Expanded(child: _heroCopy(context))
                            else
                              _heroCopy(context),
                            if (constraints.maxWidth > 700)
                              const SizedBox(width: 30),
                            if (constraints.maxWidth > 700)
                              const Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    color: Color(0xFFFFD982),
                                    size: 190,
                                  ),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFFFFF4D6),
                                  size: 190,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _TrustPill(
                              icon: Icons.auto_awesome,
                              text: 'Personalized picks'),
                          _TrustPill(
                              icon: Icons.favorite_border,
                              text: 'Save what moves you'),
                          _TrustPill(
                              icon: Icons.people_outline,
                              text: 'Read with a community'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Your next favorite book is closer than you think',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Discover, save, borrow, and build a reading life that feels uniquely yours.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          _FeatureCard(
                            icon: Icons.auto_awesome,
                            title: 'Personal picks',
                            text:
                                'Recommendations shaped by your favorites and history.',
                          ),
                          _FeatureCard(
                            icon: Icons.explore_outlined,
                            title: 'Explore freely',
                            text:
                                'Browse a growing library across every kind of mood.',
                          ),
                          _FeatureCard(
                            icon: Icons.bookmark_outline,
                            title: 'Keep your story',
                            text:
                                'Track favorites, reservations, and every borrowed book.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  void _openLogin(BuildContext context, bool signup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(startWithSignup: signup),
      ),
    );
  }

  Widget _heroCopy(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'READ MORE.\nFEEL MORE.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BookWise turns every reading mood into your next great story.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.tonalIcon(
            onPressed: () => _openLogin(context, true),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Start your reading journey'),
          ),
        ],
      );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 310,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF0C7),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(text),
              ],
            ),
          ),
        ),
      );
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE9DDC7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF8B641E)),
            const SizedBox(width: 7),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
