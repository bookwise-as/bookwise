import 'package:flutter/material.dart';

import '../services/api.dart';

class BookFormPage extends StatefulWidget {
  final dynamic book;
  final bool recommendationMode;

  const BookFormPage({
    super.key,
    this.book,
    this.recommendationMode = false,
  });

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  static const Color navy = Color(0xFF191B3A);
  static const Color indigo = Color(0xFF454AA6);
  static const Color lavender = Color(0xFFE8E9FF);
  static const Color background = Color(0xFFF5F6FC);
  static const Color textColor = Color(0xFF242644);
  static const Color muted = Color(0xFF777BA0);
  static const Color borderColor = Color(0xFFE7E8F3);

  final title = TextEditingController();
  final author = TextEditingController();
  final genre = TextEditingController();
  final description = TextEditingController();
  final year = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final rating = TextEditingController(text: '0');
  final copies = TextEditingController(text: '1');
  final cover = TextEditingController();

  bool loading = false;

  bool get isEditing => widget.book != null;

  String get destinationRoute {
    if (widget.recommendationMode) {
      return '/recommendations';
    }

    return '/catalog';
  }

  @override
  void initState() {
    super.initState();

    final book = widget.book;

    if (book != null) {
      title.text = _value(book['title']);
      author.text = _value(book['author']);
      genre.text = _value(book['genre']);
      description.text = _value(book['description']);
      year.text = _value(book['published_year']);
      rating.text = _value(book['rating']);
      copies.text = _value(book['available_copies']);
      cover.text = _value(book['cover_url']);
    }

    cover.addListener(_onCoverChanged);
  }

  String _value(dynamic value) => value?.toString() ?? '';

  void _onCoverChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    cover.removeListener(_onCoverChanged);

    for (final controller in [
      title,
      author,
      genre,
      description,
      year,
      rating,
      copies,
      cover,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst('Exception: ', ''),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Do not pop the form: the navigation shell may have cleared
  // the previous route. Always navigate to a known destination.
  void _leaveForm({String? message}) {
    if (!mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      destinationRoute,
      (route) => false,
    );
  }

  Future<void> save() async {
    if (loading) return;

    final titleValue = title.text.trim();
    final authorValue = author.text.trim();
    final genreValue = genre.text.trim();
    final descriptionValue = description.text.trim();
    final coverValue = cover.text.trim();

    if (titleValue.isEmpty || authorValue.isEmpty || genreValue.isEmpty) {
      _showMessage('Please enter the book title, author, and genre.');
      return;
    }

    if (titleValue.length > 255 || authorValue.length > 255) {
      _showMessage('Title and author must be 255 characters or fewer.');
      return;
    }

    if (genreValue.length > 100) {
      _showMessage('Genre must be 100 characters or fewer.');
      return;
    }

    if (descriptionValue.length > 4000) {
      _showMessage('Description must be 4000 characters or fewer.');
      return;
    }

    final parsedYear = int.tryParse(year.text.trim());
    final parsedRating = double.tryParse(rating.text.trim());
    final parsedCopies = int.tryParse(copies.text.trim());

    if (parsedYear == null || parsedYear < 0 || parsedYear > 3000) {
      _showMessage('Enter a valid publication year.');
      return;
    }

    if (parsedRating == null ||
        !parsedRating.isFinite ||
        parsedRating < 0 ||
        parsedRating > 5) {
      _showMessage('Rating must be a number between 0 and 5.');
      return;
    }

    if (parsedCopies == null || parsedCopies < 0) {
      _showMessage(
        'Available copies must be a non-negative whole number.',
      );
      return;
    }

    if (coverValue.isNotEmpty) {
      final uri = Uri.tryParse(coverValue);

      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme.toLowerCase())) {
        _showMessage(
          'Enter a valid cover image URL starting with http:// or https://.',
        );
        return;
      }
    }

    setState(() => loading = true);

    final body = {
      'title': titleValue,
      'author': authorValue,
      'genre': genreValue,
      'description': descriptionValue,
      'published_year': parsedYear,
      'rating': parsedRating,
      'available_copies': parsedCopies,
      'cover_url': coverValue,
      'community_recommendation': widget.recommendationMode,
    };

    try {
      await Api.request(
        isEditing ? 'PUT' : 'POST',
        isEditing ? '/books/${widget.book['id']}' : '/books',
        body: body,
      );

      if (!mounted) return;

      final message = widget.recommendationMode
          ? 'Your book recommendation was submitted successfully.'
          : isEditing
              ? 'Book details updated successfully.'
              : 'Book added successfully.';

      // Update the loading state before leaving this page.
      setState(() => loading = false);

      _leaveForm(message: message);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && loading) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, color: muted, size: 21),
      filled: true,
      fillColor: const Color(0xFFFAFAFF),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(
        color: Color(0xFFAAAEC7),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: indigo,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization capitalization = TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: !loading,
      style: const TextStyle(
        color: textColor,
        fontSize: 14,
      ),
      decoration: _decoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: indigo, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: lavender,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 35,
            color: indigo,
          ),
          SizedBox(height: 8),
          Text(
            'BOOKWISE',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPreview() {
    final value = cover.text.trim();
    final uri = Uri.tryParse(value);

    final valid = uri != null &&
        uri.hasAuthority &&
        ['http', 'https'].contains(uri.scheme.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 95,
              height: 133,
              child: valid
                  ? Image.network(
                      value,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: indigo,
                          ),
                        );
                      },
                    )
                  : _coverPlaceholder(),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Book cover preview',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  valid
                      ? 'The cover will appear here when the image is available.'
                      : 'Paste an image URL above to preview the book cover.',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: indigo,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'HTTPS image links are recommended.',
                        style: TextStyle(
                          color: indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final fieldWidth = width >= 620
            ? (width - 24) / 3
            : width >= 400
                ? (width - 12) / 2
                : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _textInput(
                controller: year,
                label: 'Published year',
                hint: '2026',
                icon: Icons.calendar_month_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _textInput(
                controller: rating,
                label: 'Rating (0–5)',
                hint: '4.5',
                icon: Icons.star_outline_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _textInput(
                controller: copies,
                label: 'Available copies',
                hint: '1',
                icon: Icons.library_books_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHero() {
    final heading = widget.recommendationMode
        ? 'Share your next great read'
        : isEditing
            ? 'Update book details'
            : 'Grow the BookWise library';

    final subtitle = widget.recommendationMode
        ? 'Recommend a book to the community and help other readers discover a new favorite.'
        : isEditing
            ? 'Keep the book information accurate and up to date.'
            : 'Add the details readers need to discover their next favorite book.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    widget.recommendationMode
                        ? 'COMMUNITY'
                        : 'BOOKWISE LIBRARY',
                    style: const TextStyle(
                      color: Color(0xFFD0D4FF),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Icon(
            widget.recommendationMode
                ? Icons.auto_awesome_rounded
                : Icons.menu_book_rounded,
            color: Colors.white.withValues(alpha: 0.2),
            size: 54,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.recommendationMode
        ? 'Share a Book'
        : isEditing
            ? 'Edit Book'
            : 'Add Book';

    final saveLabel = widget.recommendationMode
        ? 'Submit recommendation'
        : isEditing
            ? 'Save changes'
            : 'Add to library';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: loading ? null : _leaveForm,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 22),
                  _sectionCard(
                    title: 'Book information',
                    subtitle:
                        'Start with the essential details about this book.',
                    icon: Icons.menu_book_rounded,
                    children: [
                      _textInput(
                        controller: title,
                        label: 'Book title',
                        hint: 'Enter the complete title',
                        icon: Icons.title_rounded,
                        maxLength: 255,
                      ),
                      const SizedBox(height: 15),
                      _textInput(
                        controller: author,
                        label: 'Author',
                        hint: 'Enter the author’s name',
                        icon: Icons.person_outline_rounded,
                        maxLength: 255,
                      ),
                      const SizedBox(height: 15),
                      _textInput(
                        controller: genre,
                        label: 'Genre',
                        hint: 'e.g. Fantasy, Romance, Science Fiction',
                        icon: Icons.category_outlined,
                        maxLength: 100,
                      ),
                      const SizedBox(height: 15),
                      _textInput(
                        controller: description,
                        label: 'Book description',
                        hint:
                            'Describe the story, main ideas, or what makes it special.',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                        maxLength: 4000,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Publication and availability',
                    subtitle:
                        'Enter the publication year, rating, and available copies.',
                    icon: Icons.library_books_outlined,
                    children: [
                      _numberFields(),
                      const SizedBox(height: 11),
                      const Text(
                        'Rating must be between 0 and 5. Available copies must be a whole number that is zero or greater.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Book cover',
                    subtitle:
                        'Add an image URL to make the book easier to recognize.',
                    icon: Icons.image_outlined,
                    children: [
                      _textInput(
                        controller: cover,
                        label: 'Cover image URL',
                        hint: 'https://example.com/book-cover.jpg',
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        capitalization: TextCapitalization.none,
                      ),
                      const SizedBox(height: 15),
                      _coverPreview(),
                    ],
                  ),
                  if (widget.recommendationMode) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: lavender,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: indigo,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Share accurate details so other readers can find and enjoy your recommendation.',
                              style: TextStyle(
                                color: textColor,
                                height: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : save,
                      icon: loading
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              widget.recommendationMode
                                  ? Icons.send_rounded
                                  : Icons.check_circle_outline_rounded,
                            ),
                      label: Text(loading ? 'Saving...' : saveLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: loading ? null : _leaveForm,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                      ),
                      label: const Text('Cancel and go back'),
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
