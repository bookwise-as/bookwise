import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool loading = true;
  String? error;

  int users = 0;
  int books = 0;
  int borrowed = 0;
  int reservations = 0;

  List usersList = [];
  List booksList = [];
  List reservationsList = [];
  List historyList = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final overview = await Api.request('GET', '/admin/overview');
      final usersData = await Api.request('GET', '/admin/users');
      final booksData = await Api.request('GET', '/admin/books');
      final reservationsData = await Api.request('GET', '/admin/reservations');
      final historyData = await Api.request('GET', '/admin/history');

      if (!mounted) return;

      setState(() {
        users = overview['users'] ?? 0;
        books = overview['books'] ?? 0;
        borrowed = overview['borrowed'] ?? 0;
        reservations = overview['reservations'] ?? 0;

        usersList = usersData['users'] ?? [];
        booksList = booksData['books'] ?? [];
        reservationsList = reservationsData['reservations'] ?? [];
        historyList = historyData['history'] ?? [];

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> changeUserRole(int userId, String role) async {
    try {
      await Api.request(
        'PUT',
        '/admin/users/$userId/role',
        body: {'role': role},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role changed to $role.'),
        ),
      );

      await loadDashboard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> deleteBook(int bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text(
          'Are you sure you want to delete this book?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Api.request(
        'DELETE',
        '/admin/books/$bookId',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted successfully.'),
        ),
      );

      await loadDashboard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void logout() async {
    await Api.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
      (route) => false,
    );
  }

  Widget statCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0C7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8A641C),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF806F5A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF211A12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUsers() {
    if (usersList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No users found.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: usersList.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final user = usersList[index];

        final int id = user['id'];
        final String name = user['name'] ?? '';
        final String email = user['email'] ?? '';
        final String role = user['role'] ?? 'user';

        return ListTile(
          leading: CircleAvatar(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(email),
          trailing: PopupMenuButton<String>(
            initialValue: role,
            onSelected: (value) {
              if (value != role) {
                changeUserRole(id, value);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'user',
                child: Text('User'),
              ),
              PopupMenuItem(
                value: 'admin',
                child: Text('Admin'),
              ),
            ],
            child: Chip(
              label: Text(
                role.toUpperCase(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildBooks() {
    if (booksList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No books found.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: booksList.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final book = booksList[index];

        final int id = book['id'];
        final String title = book['title'] ?? '';
        final String author = book['author'] ?? '';
        final String genre = book['genre'] ?? '';
        final int copies = book['available_copies'] ?? 0;

        return ListTile(
          leading: const Icon(Icons.menu_book_rounded),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '$author • $genre • $copies available',
          ),
          trailing: IconButton(
            tooltip: 'Delete book',
            onPressed: () => deleteBook(id),
            icon: const Icon(Icons.delete_outline),
          ),
        );
      },
    );
  }

  Widget buildReservations() {
    if (reservationsList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No reservations found.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservationsList.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final reservation = reservationsList[index];

        final String userName = reservation['user_name'] ?? '';
        final String bookTitle = reservation['title'] ?? '';
        final String status = reservation['status'] ?? '';
        final int position = reservation['queue_position'] ?? 0;

        return ListTile(
          leading: const Icon(Icons.event_note_outlined),
          title: Text(
            bookTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '$userName • Position $position',
          ),
          trailing: Chip(
            label: Text(status),
          ),
        );
      },
    );
  }

  Widget buildHistory() {
    if (historyList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No borrowing history found.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyList.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = historyList[index];

        final String userName = item['user_name'] ?? '';
        final String title = item['title'] ?? '';
        final String action = item['action'] ?? '';

        return ListTile(
          leading: Icon(
            action == 'borrowed'
                ? Icons.bookmark_add_outlined
                : Icons.assignment_return_outlined,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '$userName • $action',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadDashboard,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1200,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BookWise Administration',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF211A12),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Manage users, books, reservations, and borrowing activity.',
                              style: TextStyle(
                                color: Color(0xFF806F5A),
                              ),
                            ),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;

                                final columns = width >= 900
                                    ? 4
                                    : width >= 600
                                        ? 2
                                        : 1;

                                final itemWidth = columns == 1
                                    ? width
                                    : (width - ((columns - 1) * 12)) / columns;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: itemWidth,
                                      child: statCard(
                                        'Users',
                                        users,
                                        Icons.people_outline,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: statCard(
                                        'Books',
                                        books,
                                        Icons.menu_book_outlined,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: statCard(
                                        'Borrowed',
                                        borrowed,
                                        Icons.bookmark_outline,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: statCard(
                                        'Reservations',
                                        reservations,
                                        Icons.event_note_outlined,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            sectionCard(
                              'Manage Users',
                              Icons.people_alt_outlined,
                              buildUsers(),
                            ),
                            const SizedBox(height: 20),
                            sectionCard(
                              'Manage Books',
                              Icons.menu_book_outlined,
                              buildBooks(),
                            ),
                            const SizedBox(height: 20),
                            sectionCard(
                              'Reservations',
                              Icons.event_note_outlined,
                              buildReservations(),
                            ),
                            const SizedBox(height: 20),
                            sectionCard(
                              'Borrowing History',
                              Icons.history,
                              buildHistory(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget sectionCard(
    String title,
    IconData icon,
    Widget child,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
