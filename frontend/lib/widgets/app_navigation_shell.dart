import 'package:flutter/material.dart';

import '../services/api.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  // Keep the sidebar's collapsed setting when navigating between pages.
  static bool _collapsed = false;

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  static const Color _navy = Color(0xFF191B3A);
  static const Color _navyLight = Color(0xFF25284D);
  static const Color _selected = Color(0xFF424783);
  static const Color _accent = Color(0xFFA8AEFF);
  static const Color _muted = Color(0xFFD0D4EE);
  static const Color _mutedLabel = Color(0xFF969DC8);
  static const Color _lavender = Color(0xFFE4E6FF);

  // Prevent labels and tooltips from flashing during sidebar animation.
  bool _sidebarAnimating = false;

  static const List<_NavigationItem> _items = [
    _NavigationItem(
      'Home',
      Icons.home_rounded,
      '/home',
    ),
    _NavigationItem(
      'Dashboard',
      Icons.space_dashboard_rounded,
      '/dashboard',
    ),
    _NavigationItem(
      'Explore Books',
      Icons.menu_book_rounded,
      '/catalog',
    ),
    _NavigationItem(
      'Recommendations',
      Icons.auto_awesome_rounded,
      '/recommendations',
    ),
    _NavigationItem(
      'Recommend a Book',
      Icons.volunteer_activism_rounded,
      '/recommend-book',
    ),
    _NavigationItem(
      'Borrowing History',
      Icons.history_rounded,
      '/history',
    ),
    _NavigationItem(
      'My Profile',
      Icons.person_outline_rounded,
      '/profile',
    ),
  ];

  void _setSidebarCollapsed(bool collapsed) {
    if (AppNavigationShell._collapsed == collapsed) return;

    setState(() {
      AppNavigationShell._collapsed = collapsed;
      _sidebarAnimating = true;
    });
  }

  void _finishSidebarAnimation() {
    if (!mounted || !_sidebarAnimating) return;

    setState(() {
      _sidebarAnimating = false;
    });
  }

  void _navigate(String route) {
    if (widget.currentRoute == route) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  Future<void> _logout() async {
    try {
      await Api.logout();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign out. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use bottom navigation on smaller screens.
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Expanded(child: widget.child),
              SafeArea(
                top: false,
                child: _mobileNavigation(),
              ),
            ],
          );
        }

        final collapsed = AppNavigationShell._collapsed;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _desktopSidebar(collapsed),
            Expanded(
              child: widget.child,
            ),
          ],
        );
      },
    );
  }

  Widget _desktopSidebar(bool collapsed) {
    // Hide all sidebar labels until the width animation has finished.
    final compact = collapsed || _sidebarAnimating;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: collapsed ? 78 : 252,
      clipBehavior: Clip.hardEdge,
      onEnd: _finishSidebarAnimation,
      decoration: const BoxDecoration(
        color: _navy,
        boxShadow: [
          BoxShadow(
            color: Color(0x180D1030),
            blurRadius: 22,
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: Material(
        color: _navy,
        child: SafeArea(
          child: Column(
            children: [
              _sidebarHeader(compact),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  height: 1,
                ),
              ),

              // Do not display text in the menu heading while animating.
              if (collapsed && !_sidebarAnimating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: IconButton(
                    tooltip: 'Expand sidebar',
                    onPressed: () => _setSidebarCollapsed(false),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _navyLight,
                    ),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                    ),
                  ),
                )
              else if (_sidebarAnimating)
                const SizedBox(height: 39)
              else
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 17, 12, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LIBRARY MENU',
                      style: TextStyle(
                        color: _mutedLabel,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                    vertical: 4,
                  ),
                  children: [
                    for (final item in _items)
                      _sidebarItem(
                        item,
                        collapsed: collapsed,
                        hideLabels: _sidebarAnimating,
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  height: 1,
                ),
              ),

              _sidebarAction(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                collapsed: collapsed,
                hideLabels: _sidebarAnimating,
                onTap: _logout,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarHeader(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 16,
        16,
        compact ? 8 : 10,
        18,
      ),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7079E8),
                  Color(0xFF454B9F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BookWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'YOUR READING SPACE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedLabel,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 32,
              height: 38,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Collapse sidebar',
                onPressed: () => _setSidebarCollapsed(true),
                style: IconButton.styleFrom(
                  foregroundColor: _muted,
                  minimumSize: const Size(32, 38),
                ),
                icon: const Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 21,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sidebarItem(
    _NavigationItem item, {
    required bool collapsed,
    required bool hideLabels,
  }) {
    final selected = widget.currentRoute == item.route ||
        (widget.currentRoute == '/add-book' && item.route == '/catalog');

    final compact = collapsed || hideLabels;

    final button = Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? _selected : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _navigate(item.route),
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 12,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      item.icon,
                      size: 21,
                      color: selected ? _accent : _muted,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : _muted,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Tooltips are available only when the sidebar is fully collapsed.
    if (collapsed && !hideLabels) {
      return Tooltip(
        key: ValueKey('collapsed-${item.route}'),
        message: item.label,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }

  Widget _sidebarAction({
    required IconData icon,
    required String label,
    required bool collapsed,
    required bool hideLabels,
    required VoidCallback onTap,
  }) {
    final compact = collapsed || hideLabels;

    final button = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 12,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      icon,
                      color: const Color(0xFFFFA9BD),
                      size: 21,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFA9BD),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (collapsed && !hideLabels) {
      return Tooltip(
        key: const ValueKey('collapsed-sign-out-tooltip'),
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }

  // Mobile bottom navigation.
  Widget _mobileNavigation() {
    const mobileItems = [
      _NavigationItem(
        'Home',
        Icons.home_rounded,
        '/home',
      ),
      _NavigationItem(
        'Dashboard',
        Icons.space_dashboard_rounded,
        '/dashboard',
      ),
      _NavigationItem(
        'Explore',
        Icons.menu_book_rounded,
        '/catalog',
      ),
      _NavigationItem(
        'For you',
        Icons.auto_awesome_rounded,
        '/recommendations',
      ),
      _NavigationItem(
        'History',
        Icons.history_rounded,
        '/history',
      ),
      _NavigationItem(
        'Profile',
        Icons.person_rounded,
        '/profile',
      ),
    ];

    var selectedIndex = mobileItems.indexWhere(
      (item) => item.route == widget.currentRoute,
    );

    if (selectedIndex < 0) {
      if (widget.currentRoute == '/recommend-book') {
        selectedIndex = 3;
      } else if (widget.currentRoute == '/add-book') {
        selectedIndex = 2;
      } else {
        selectedIndex = 0;
      }
    }

    return NavigationBar(
      height: 70,
      selectedIndex: selectedIndex,
      backgroundColor: Colors.white,
      indicatorColor: _lavender,
      onDestinationSelected: (index) {
        final route = mobileItems[index].route;

        if (route != widget.currentRoute) {
          _navigate(route);
        }
      },
      destinations: [
        for (final item in mobileItems)
          NavigationDestination(
            icon: Icon(
              item.icon,
              color: const Color(0xFF777CA7),
            ),
            selectedIcon: Icon(
              item.icon,
              color: const Color(0xFF4D52B5),
            ),
            label: item.label,
          ),
      ],
    );
  }
}

class _NavigationItem {
  const _NavigationItem(
    this.label,
    this.icon,
    this.route,
  );

  final String label;
  final IconData icon;
  final String route;
}
