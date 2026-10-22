import 'package:flutter/material.dart';

class MyBorrowedBooksPage extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loadBooks;
  final Future<void> Function(int borrowingId) returnBook;

  const MyBorrowedBooksPage({
    super.key,
    required this.loadBooks,
    required this.returnBook,
  });

  @override
  State<MyBorrowedBooksPage> createState() => _MyBorrowedBooksPageState();
}

class _MyBorrowedBooksPageState extends State<MyBorrowedBooksPage> {
  static const Color purple = Color(0xFF5558D9);
  static const Color navy = Color(0xFF191B3D);
  static const Color background = Color(0xFFF4F5FC);
  static const Color muted = Color(0xFF777FAE);

  List<Map<String, dynamic>> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final books = await widget.loadBooks();

      if (!mounted) return;

      setState(() {
        // The backend should return only active loans
        // belonging to the currently authenticated user.
        _books = books.where((book) => book['status'] != 'returned').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load your borrowed books.';
        _loading = false;
      });
    }
  }

  Future<void> _returnBook(Map<String, dynamic> book) async {
    final id = book['borrowing_id'];

    if (id is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This loan has no valid borrowing ID.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Book'),
        content: Text(
          'Are you sure you have returned "${book['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Update the actual borrowing record in the backend.
      await widget.returnBook(id);

      if (!mounted) return;

      setState(() {
        _books.removeWhere(
          (item) => item['borrowing_id'] == id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book returned successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to return the book. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        onRefresh: _loadBooks,
        color: purple,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'My Borrowed Books',
              style: TextStyle(
                color: navy,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage the books you currently have on loan.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navy, purple],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR READING SPACE',
                          style: TextStyle(
                            color: Color(0xFFE1E2FF),
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Your current loans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E5FA),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.library_books_rounded,
                    color: purple,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Currently borrowed',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_books.length}',
                    style: const TextStyle(
                      color: purple,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: purple,
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadBooks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (_books.isEmpty)
              Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: purple,
                      size: 55,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No borrowed books',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Books you borrow will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
              )
            else
              ..._books.map((book) {
                final dueDate = book['due_date']?.toString() ?? 'Not specified';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E5FA),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: purple,
                          size: 35,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title']?.toString() ?? 'Untitled Book',
                              style: const TextStyle(
                                color: navy,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              book['author']?.toString() ?? 'Unknown author',
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Due date: $dueDate',
                              style: const TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _returnBook(book),
                                icon: const Icon(
                                  Icons.assignment_return_outlined,
                                ),
                                label: const Text('Return Book'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: purple,
                                  side: const BorderSide(
                                    color: purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
