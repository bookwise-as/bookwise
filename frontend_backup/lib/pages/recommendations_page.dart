import 'package:flutter/material.dart';

import 'book_form_page.dart';
import '../services/api.dart';
import '../widgets/app_drawer.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List recs = [];
  List mine = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await Api.request('GET', '/recommendations');
      final submitted = await Api.request('GET', '/my-recommendations');
      if (mounted) {
        setState(() {
          recs = (data['recommendations'] as List?) ?? [];
          mine = (submitted['books'] as List?) ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'The Reading Room',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Recommend a book',
              onPressed: () => Navigator.pushNamed(
                context,
                '/recommend-book',
              ).then((_) => load()),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF211A12),
                      Color(0xFF72521F),
                      Color(0xFFC8942E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A shelf picked\njust for you.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Find your next five-star feeling.',
                            style: TextStyle(color: Color(0xFFFFE8B0)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      size: 72,
                      color: Colors.amber.shade200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Curated for your mood',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${recs.length} picks',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Your favorites and reading history help BookWise find the right story.',
              ),
              const SizedBox(height: 14),
              if (loading) const Center(child: CircularProgressIndicator()),
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                FilledButton.icon(
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
              if (!loading && error == null && recs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Borrow or favorite a few books to help us build your shelf.',
                    ),
                  ),
                ),
              if (!loading && mine.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Your community picks',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text('Edit or remove books you have recommended.'),
                const SizedBox(height: 8),
                ...mine.map((book) => _OwnedRecommendation(
                      book: book,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookFormPage(
                            recommendationMode: true,
                            book: book,
                          ),
                        ),
                      ).then((_) => load()),
                      onDelete: () => _deleteRecommendation(book),
                    )),
              ],
              ...recs.asMap().entries.map(
                    (entry) => _BookRecommendation(
                      rank: entry.key + 1,
                      book: entry.value,
                    ),
                  ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFFFFF0C7),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFD982),
                    child: Icon(Icons.tips_and_updates, color: Color(0xFF6F4C13)),
                  ),
                  title: const Text(
                    'Know a hidden gem?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Share it with the BookWise community.'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/recommend-book',
                  ).then((_) => load()),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _deleteRecommendation(dynamic book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove recommendation?'),
        content: Text('Remove "${book['title']}" from the community shelf?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.request('DELETE', '/books/${book['id']}');
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}

class _OwnedRecommendation extends StatelessWidget {
  const _OwnedRecommendation({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFFFF8E8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFD982),
            child: Icon(Icons.person_outline, color: Color(0xFF6F4C13)),
          ),
          title: Text(
            book['title']?.toString() ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${book['author'] ?? 'Unknown author'} • ${book['genre'] ?? 'Unknown genre'}',
          ),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Edit recommendation',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete recommendation',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );
}

class _BookRecommendation extends StatelessWidget {
  const _BookRecommendation({required this.rank, required this.book});

  final int rank;
  final dynamic book;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFFFF0C7),
                child: Icon(Icons.menu_book, color: Color(0xFF8B641E)),
              ),
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFFC8942E),
                child: Text(
                  '$rank',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          title: Text(
            book['title']?.toString() ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${book['author'] ?? 'Unknown author'} • ${book['genre'] ?? 'Unknown genre'}',
          ),
          trailing: Text(
            '${book['rating'] ?? 0} ★',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
}
