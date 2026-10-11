import 'package:flutter/material.dart';
import '../services/api.dart';

class BookFormPage extends StatefulWidget {
  final dynamic book;
  final bool recommendationMode;
  const BookFormPage({super.key, this.book, this.recommendationMode = false});
  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final title = TextEditingController(),
      author = TextEditingController(),
      genre = TextEditingController(),
      description = TextEditingController(),
      year = TextEditingController(text: '2024'),
      rating = TextEditingController(text: '0'),
      copies = TextEditingController(text: '1'),
      cover = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    for (final controller in [
      title,
      author,
      genre,
      description,
      year,
      rating,
      copies,
      cover
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    if (b != null) {
      title.text = b['title'];
      author.text = b['author'];
      genre.text = b['genre'];
      description.text = b['description'] ?? '';
      year.text = '${b['published_year']}';
      rating.text = '${b['rating']}';
      copies.text = '${b['available_copies']}';
      cover.text = b['cover_url'] ?? '';
    }
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty ||
        author.text.trim().isEmpty ||
        genre.text.trim().isEmpty) {
      msg('Title, author and genre are required.');
      return;
    }
    final parsedYear = int.tryParse(year.text.trim());
    final parsedRating = double.tryParse(rating.text.trim());
    final parsedCopies = int.tryParse(copies.text.trim());
    if (parsedYear == null || parsedYear < 0 || parsedYear > 3000) {
      msg('Enter a valid publication year.');
      return;
    }
    if (parsedRating == null || parsedRating < 0 || parsedRating > 5) {
      msg('Rating must be between 0 and 5.');
      return;
    }
    if (parsedCopies == null || parsedCopies < 0) {
      msg('Available copies must be a non-negative whole number.');
      return;
    }
    setState(() => loading = true);
    final body = {
      'title': title.text,
      'author': author.text,
      'genre': genre.text,
      'description': description.text,
      'published_year': parsedYear,
      'rating': parsedRating,
      'available_copies': parsedCopies,
      'cover_url': cover.text,
      'community_recommendation': widget.recommendationMode
    };
    try {
      await Api.request(widget.book == null ? 'POST' : 'PUT',
          widget.book == null ? '/books' : '/books/${widget.book['id']}',
          body: body);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      msg(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          title: Text(widget.book == null
              ? (widget.recommendationMode ? 'Share a Book' : 'Add Book')
              : 'Edit Book')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (widget.recommendationMode)
          const Card(
              color: Color(0xFFFFF0C7),
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates, color: Color(0xFF8B641E)),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'Recommend a book to the BookWise community. Share the story that stayed with you.',
                                style: TextStyle(fontWeight: FontWeight.w600)))
                      ]))),
        for (final x in [
          title,
          author,
          genre,
          description,
          year,
          rating,
          copies,
          cover
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                  controller: x,
                  maxLines: x == description ? 4 : 1,
                  decoration: InputDecoration(labelText: _label(x)))),
        FilledButton(
            onPressed: loading ? null : save,
            child: Text(loading ? 'Saving...' : 'Save book'))
      ]));
  String _label(TextEditingController x) => x == title
      ? 'Title'
      : x == author
          ? 'Author'
          : x == genre
              ? 'Genre'
              : x == description
                  ? 'Description'
                  : x == year
                      ? 'Published year'
                      : x == rating
                          ? 'Rating (0-5)'
                          : x == copies
                              ? 'Available copies'
                              : 'Cover image URL';
}
