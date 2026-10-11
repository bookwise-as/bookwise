import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const Color navy = Color(0xFF1B203F);
  static const Color selectedColor = Color(0xFF3C467D);
  static const Color mutedText = Color(0xFFADB5DB);
  static const Color accent = Color(0xFF9BA8FF);

  bool collapsed = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedUser = preferences.getString('user');

      if (savedUser == null) return;

      final user = jsonDecode(savedUser);

      if (!mounted) return;

      setState(() {
        isAdmin = user is Map && user['role'] == 'admin';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isAdmin = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await Api.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
      (_) => false,
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: collapsed ? 82 : 286,
      backgroundColor: navy,
      child: Material(
        color: navy,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  collapsed ? 8 : 18,
                  18,
                  collapsed ? 8 : 14,
                  18,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: accent,
                        size: 27,
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BookWise',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'YOUR READING SPACE',
                              maxLines: 1,
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  collapsed ? 8 : 18,
                  16,
                  collapsed ? 8 : 14,
                  8,
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!collapsed)
                      const Expanded(
                        child: Text(
                          'LIBRARY MENU',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    Tooltip(
                      message:
                          collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() => collapsed = !collapsed);
                        },
                        icon: Icon(
                          collapsed
                              ? Icons.keyboard_double_arrow_right_rounded
                              : Icons.keyboard_double_arrow_left_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  children: [
                    if (isAdmin) ...[
                      _navItem(
                        context,
                        Icons.admin_panel_settings_rounded,
                        'Admin Dashboard',
                        '/admin',
                      ),
                      _sectionLabel('ADMINISTRATION'),
                      _navItem(
                        context,
                        Icons.people_alt_rounded,
                        'Manage Users',
                        '/admin',
                      ),
                      _navItem(
                        context,
                        Icons.library_books_rounded,
                        'Manage Books',
                        '/admin',
                      ),
                      _navItem(
                        context,
                        Icons.event_note_rounded,
                        'Reservations',
                        '/admin',
                      ),
                      _navItem(
                        context,
                        Icons.manage_history_rounded,
                        'Borrowing Records',
                        '/admin',
                      ),
                      _sectionLabel('MY READING'),
                    ] else
                      _sectionLabel('YOUR READING SPACE'),
                    _navItem(
                      context,
                      Icons.dashboard_rounded,
                      'Dashboard',
                      '/home',
                    ),
                    _navItem(
                      context,
                      Icons.menu_book_rounded,
                      'Discover Books',
                      '/catalog',
                    ),
                    _navItem(
                      context,
                      Icons.auto_awesome_rounded,
                      'Recommendations',
                      '/recommendations',
                    ),
                    _navItem(
                      context,
                      Icons.lightbulb_outline_rounded,
                      'Recommend a Book',
                      '/recommend-book',
                    ),
                    _navItem(
                      context,
                      Icons.history_rounded,
                      'Borrowing History',
                      '/history',
                    ),
                    _navItem(
                      context,
                      Icons.person_outline_rounded,
                      'My Profile',
                      '/profile',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 8),
                    Tooltip(
                      message: 'Sign out',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _signOut(context),
                          child: SizedBox(
                            height: 48,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: collapsed ? 0 : 14,
                              ),
                              child: Row(
                                mainAxisAlignment: collapsed
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFFFA7B5),
                                  ),
                                  if (!collapsed) ...[
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Sign out',
                                      style: TextStyle(
                                        color: Color(0xFFFFA7B5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Color(0x33FFFFFF)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Tooltip(
        message: collapsed ? label : '',
        child: Material(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _navigate(context, route),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : 13,
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: selected ? Colors.white : mutedText,
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? Colors.white : mutedText,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
