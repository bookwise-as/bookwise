import 'package:flutter/material.dart';

import '../services/api.dart';
import '../widgets/app_drawer.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List history = [];
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
      final response = await Api.request('GET', '/history');
      if (mounted) setState(() => history = response['history'] as List? ?? []);
    } catch (exception) {
      if (mounted) {
        setState(() => error = exception.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Your reading trail'),
          actions: [
            IconButton(
              tooltip: 'Refresh history',
              onPressed: load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              const Card(
                color: Color(0xFFFFF0C7),
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories, color: Color(0xFF8B641E)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Every borrowed book is part of your reading story.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (loading) const LinearProgressIndicator(minHeight: 3),
              if (error != null) ...[
                const SizedBox(height: 18),
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
              if (!loading && error == null && history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 44),
                        SizedBox(height: 10),
                        Text(
                          'Your reading trail is empty',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text('Borrow a book and it will appear here.'),
                      ],
                    ),
                  ),
                ),
              ...history.asMap().entries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF0C7),
                          child: Text(
                            '#${entry.key + 1}',
                            style: const TextStyle(
                              color: Color(0xFF8B641E),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          entry.value['title']?.toString() ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${entry.value['author'] ?? 'Unknown author'} • ${entry.value['action'] ?? 'Activity'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
}
