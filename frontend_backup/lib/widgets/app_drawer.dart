import 'package:flutter/material.dart';
import '../services/api.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 54, 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF211A12), Color(0xFFC8942E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_stories, size: 44, color: Color(0xFFFFD982)),
                  SizedBox(height: 12),
                  Text('BookWise',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Your personal reading lounge',
                      style: TextStyle(color: Color(0xFFFFE8B0))),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'YOUR READING SPACE',
                style: TextStyle(
                  color: Color(0xFF907B61),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _item(context, Icons.dashboard, 'Dashboard', '/home'),
            _item(context, Icons.menu_book, 'Book Catalog', '/catalog'),
            _item(context, Icons.auto_awesome, 'Recommendations',
                '/recommendations'),
            _item(context, Icons.tips_and_updates, 'Recommend a book',
                '/recommend-book'),
            _item(context, Icons.history, 'Borrowing History', '/history'),
            _item(context, Icons.person, 'Profile', '/profile'),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await Api.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/welcome', (_) => false);
                  }
                }),
          ],
        ),
      );

  Widget _item(BuildContext c, IconData i, String t, String route) => ListTile(
        leading: Icon(i),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.pop(c);
          Navigator.pushNamed(c, route);
        },
      );
}
