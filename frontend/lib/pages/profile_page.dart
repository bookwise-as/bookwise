import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color navy = Color(0xFF191B3A);
  static const Color indigo = Color(0xFF454AA6);
  static const Color lavender = Color(0xFFE8E9FF);
  static const Color background = Color(0xFFF5F6FC);
  static const Color muted = Color(0xFF777BA0);
  static const Color border = Color(0xFFE7E8F3);
  static const Color white = Colors.white;

  static const int _maxBioLength = 500;

  Map<String, dynamic> profile = {};
  List books = [];
  List history = [];
  List recommendations = [];

  final TextEditingController _bioController = TextEditingController();

  Uint8List? photoBytes;

  bool loading = true;
  bool photoSaving = false;
  bool bioSaving = false;

  String _savedBio = '';
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  String _bioStorageKeyFor(Map<String, dynamic> account) {
    final identity = (account['id'] ?? account['email'] ?? 'reader').toString();

    return 'bookwise_profile_bio_${identity.trim().toLowerCase()}';
  }

  String get _bioStorageKey => _bioStorageKeyFor(profile);

  bool get _bioHasChanges => _bioController.text.trim() != _savedBio;

  Future<dynamic> _safeGet(String path) async {
    try {
      return await Api.request('GET', path);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final profileResponse = await Api.request('GET', '/profile');

      final data = await Future.wait<dynamic>([
        _safeGet('/books?sort=title'),
        _safeGet('/history'),
        _safeGet('/my-recommendations'),
      ]);

      final bookResponse = data[0];
      final historyResponse = data[1];
      final recommendationResponse = data[2];

      final loadedProfile = Map<String, dynamic>.from(profileResponse as Map);

      // Use a server-supplied bio if the API provides one.
      // Otherwise, restore the bio saved on this device.
      String loadedBio = loadedProfile['bio']?.toString() ?? '';

      try {
        final preferences = await SharedPreferences.getInstance();

        if (loadedBio.trim().isEmpty) {
          loadedBio =
              preferences.getString(_bioStorageKeyFor(loadedProfile)) ?? '';
        }
      } catch (_) {
        // The rest of the profile can still load if local preferences fail.
      }

      if (!mounted) return;

      _bioController.value = TextEditingValue(
        text: loadedBio,
        selection: TextSelection.collapsed(offset: loadedBio.length),
      );

      setState(() {
        profile = loadedProfile;
        photoBytes = _decodePhoto(loadedProfile['profile_photo']);
        _savedBio = loadedBio;

        books = bookResponse is Map && bookResponse['books'] is List
            ? List.from(bookResponse['books'])
            : [];

        history = historyResponse is Map && historyResponse['history'] is List
            ? List.from(historyResponse['history'])
            : [];

        recommendations = recommendationResponse is Map &&
                recommendationResponse['books'] is List
            ? List.from(recommendationResponse['books'])
            : [];
      });
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _saveBio() async {
    if (bioSaving) return;

    final bio = _bioController.text.trim();

    if (bio.length > _maxBioLength) {
      _message('Your bio must be 500 characters or fewer.');
      return;
    }

    setState(() => bioSaving = true);

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_bioStorageKey, bio);

      if (!mounted) return;

      setState(() {
        _savedBio = bio;
      });

      _message('Your bio has been saved successfully.');
    } catch (_) {
      _message('Unable to save your bio. Please try again.');
    } finally {
      if (mounted) {
        setState(() => bioSaving = false);
      }
    }
  }

  Uint8List? _decodePhoto(dynamic value) {
    final photo = value?.toString() ?? '';
    const prefix = 'data:image/jpeg;base64,';

    if (!photo.startsWith(prefix)) return null;

    try {
      return Uint8List.fromList(
        base64Decode(photo.substring(prefix.length)),
      );
    } catch (_) {
      return null;
    }
  }

  String get userName {
    final name = profile['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Reader' : name;
  }

  String get userEmail => profile['email']?.toString() ?? 'No email available';

  String get userRole {
    final role = profile['role']?.toString().toLowerCase() ?? 'user';
    return role == 'admin' ? 'Administrator' : 'Reader';
  }

  String get initials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'R';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  int get borrowedCount =>
      books.where((book) => book is Map && book['is_borrowed'] == true).length;

  int get favoriteCount =>
      books.where((book) => book is Map && book['is_favorite'] == true).length;

  String get joinedDate {
    final raw = profile['created_at']?.toString() ?? '';
    final date = DateTime.tryParse(raw);

    if (date == null) return 'Not available';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Uint8List _preparePhoto(Uint8List sourceBytes) {
    final original = img.decodeImage(sourceBytes);

    if (original == null) {
      throw StateError(
        'This image could not be opened. Choose a JPG or PNG image.',
      );
    }

    final oriented = img.bakeOrientation(original);

    double scale =
        math.min(1.0, 512 / math.max(oriented.width, oriented.height));

    img.Image resizeImage() {
      return img.copyResize(
        oriented,
        width: math.max(1, (oriented.width * scale).round()).toInt(),
        height: math.max(1, (oriented.height * scale).round()).toInt(),
        interpolation: img.Interpolation.average,
      );
    }

    var resized = resizeImage();
    var jpeg = img.encodeJpg(resized, quality: 82);

    while (jpeg.length > 300 * 1024 && scale > 0.25) {
      scale *= 0.8;
      resized = resizeImage();
      jpeg = img.encodeJpg(resized, quality: 72);
    }

    if (jpeg.length > 350 * 1024) {
      throw StateError(
        'This photo is still too large. Please choose a smaller image.',
      );
    }

    return Uint8List.fromList(jpeg);
  }

  Future<void> _choosePhoto() async {
    if (photoSaving) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final sourceBytes = result.files.single.bytes;

      if (sourceBytes == null || sourceBytes.isEmpty) {
        _message('Unable to read this image. Please choose another.');
        return;
      }

      final compressed = _preparePhoto(sourceBytes);
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(compressed)}';

      if (!mounted) return;

      setState(() => photoSaving = true);

      final response = await Api.request(
        'PUT',
        '/profile/photo',
        body: {'profile_photo': dataUrl},
      );

      if (!mounted) return;

      setState(() {
        photoBytes = compressed;
        profile['profile_photo'] = response['profile_photo'] ?? dataUrl;
      });

      _message('Your profile photo has been saved to your account.');
    } catch (exception) {
      _message(
        exception.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => photoSaving = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    if (photoBytes == null || photoSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'This will remove the photo from your account on all devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => photoSaving = true);

    try {
      await Api.request('DELETE', '/profile/photo');

      if (!mounted) return;

      setState(() {
        photoBytes = null;
        profile['profile_photo'] = null;
      });

      _message('Your profile photo has been removed.');
    } catch (exception) {
      _message(
        exception.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => photoSaving = false);
      }
    }
  }

  Future<void> _showPhotoActions() async {
    if (photoSaving) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile photo',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_a_photo_outlined,
                color: indigo,
              ),
              title: const Text('Choose a photo'),
              subtitle: const Text('Select an image from your device'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choosePhoto();
              },
            ),
            if (photoBytes != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB23B50),
                ),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My profile',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded, color: indigo),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: indigo,
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          children: [
            if (loading && profile.isEmpty)
              _loadingState()
            else if (profile.isEmpty && error != null)
              _errorState()
            else if (profile.isNotEmpty)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: indigo,
                          backgroundColor: lavender,
                        ),
                      _profileHeader(),
                      const SizedBox(height: 22),
                      _readingStats(),
                      const SizedBox(height: 28),
                      _sectionTitle(
                        'Account information',
                        'Your BookWise account details',
                      ),
                      const SizedBox(height: 12),
                      _accountCard(),
                      const SizedBox(height: 28),
                      _sectionTitle(
                        'Your reading space',
                        'Jump straight to the things you use most',
                      ),
                      const SizedBox(height: 12),
                      _shortcuts(),
                      const SizedBox(height: 28),
                      _sectionTitle(
                        'Recent activity',
                        'A glimpse of your latest reading actions',
                      ),
                      const SizedBox(height: 12),
                      _recentActivity(),
                      const SizedBox(height: 24),
                      _signOutButton(),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Some profile information could not be refreshed.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: lavender,
                      backgroundImage:
                          photoBytes != null ? MemoryImage(photoBytes!) : null,
                      child: photoBytes == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: indigo,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 0,
                    child: Material(
                      color: white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _showPhotoActions,
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: indigo,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR READER PROFILE',
                        style: TextStyle(
                          color: Color(0xFFDADDFE),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: white,
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userEmail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E3F6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          userRole,
                          style: const TextStyle(
                            color: white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0x557E81BF), height: 1),
          const SizedBox(height: 20),

          // BIO SECTION — replaces the photo instructions and buttons.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'About Me',
                  style: TextStyle(
                    color: white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              if (!_bioHasChanges && _savedBio.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: Color(0xFFD8F5E7),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: Color(0xFFD8F5E7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us a little about yourself, your interests, and the books you enjoy.',
            style: TextStyle(
              color: Color(0xFFDADCF1),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioController,
            minLines: 3,
            maxLines: 5,
            maxLength: _maxBioLength,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            onChanged: (_) {
              setState(() {});
            },
            style: const TextStyle(
              color: white,
              fontSize: 13,
              height: 1.5,
            ),
            cursorColor: white,
            decoration: InputDecoration(
              hintText:
                  'Example: I love mystery novels, fantasy worlds, and discovering new authors...',
              hintStyle: const TextStyle(
                color: Color(0xFFCFD2F0),
                fontSize: 12,
                height: 1.5,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.09),
              counterStyle: const TextStyle(
                color: Color(0xFFDADCF1),
                fontSize: 10,
              ),
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC8CCFF),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your bio is saved on this device.',
                  style: TextStyle(
                    color: Color(0xFFDADCF1),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: bioSaving ? null : _saveBio,
                style: FilledButton.styleFrom(
                  backgroundColor: lavender,
                  foregroundColor: navy,
                  disabledBackgroundColor: const Color(0xFFB9BCDA),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: bioSaving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: navy,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        size: 17,
                      ),
                label: Text(
                  bioSaving ? 'Saving...' : 'Save Bio',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readingStats() {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            icon: Icons.menu_book_rounded,
            value: '$borrowedCount',
            label: 'Currently borrowed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            icon: Icons.favorite_border_rounded,
            value: '$favoriteCount',
            label: 'Favorites',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            icon: Icons.recommend_outlined,
            value: '${recommendations.length}',
            label: 'Your picks',
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: indigo, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _accountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.person_outline_rounded,
            'Full name',
            userName,
          ),
          const Divider(height: 24, color: border),
          _detailRow(
            Icons.alternate_email_rounded,
            'Email address',
            userEmail,
          ),
          const Divider(height: 24, color: border),
          _detailRow(
            Icons.badge_outlined,
            'Account type',
            userRole,
          ),
          const Divider(height: 24, color: border),
          _detailRow(
            Icons.calendar_month_outlined,
            'Member since',
            joinedDate,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: indigo, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shortcuts() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _shortcut(
          Icons.auto_stories_rounded,
          'Browse books',
          '/catalog',
        ),
        _shortcut(
          Icons.auto_awesome_rounded,
          'Recommendations',
          '/recommendations',
        ),
        _shortcut(
          Icons.history_rounded,
          'Borrowing history',
          '/history',
        ),
        _shortcut(
          Icons.add_circle_outline_rounded,
          'Recommend a book',
          '/recommend-book',
        ),
      ],
    );
  }

  Widget _shortcut(
    IconData icon,
    String label,
    String route,
  ) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: indigo,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _recentActivity() {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 31,
              color: indigo,
            ),
            SizedBox(height: 10),
            Text(
              'Your reading story is just beginning.',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Borrow or return a book to see your activity here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          ...history.take(3).toList().asMap().entries.map((entry) {
            final item = entry.value;
            final title = item['title']?.toString() ?? 'Untitled book';
            final action = item['action']?.toString() ?? 'Activity';
            final isReturn = action.toLowerCase().contains('return');

            final date = DateTime.tryParse(
              item['created_at']?.toString() ?? '',
            );

            final dateText = date == null
                ? 'Date unavailable'
                : '${date.day}/${date.month}/${date.year}';

            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: lavender,
                    child: Icon(
                      isReturn
                          ? Icons.assignment_turned_in_outlined
                          : Icons.menu_book_rounded,
                      color: indigo,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '$action • $dateText',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (entry.key != math.min(history.length, 3) - 1)
                  const Divider(height: 1, color: border),
              ],
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text(
                'View full history →',
                style: TextStyle(
                  color: indigo,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Api.logout();

          if (!mounted) return;

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: indigo,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: indigo),
            SizedBox(height: 16),
            Text(
              'Loading your profile...',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: indigo,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your profile could not be loaded',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }
}
