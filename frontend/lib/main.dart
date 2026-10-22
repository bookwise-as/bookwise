import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:book_recommendation_app/pages/admin_dashboard_page.dart';
import 'package:book_recommendation_app/pages/book_form_page.dart';
import 'package:book_recommendation_app/pages/catalog_page.dart';
import 'package:book_recommendation_app/pages/dashboard_page.dart';
import 'package:book_recommendation_app/pages/history_page.dart';
import 'package:book_recommendation_app/pages/home_page.dart';
import 'package:book_recommendation_app/pages/login_page.dart';
import 'package:book_recommendation_app/pages/my_borrowed_books_page.dart';
import 'package:book_recommendation_app/pages/profile_page.dart';
import 'package:book_recommendation_app/pages/recommendations_page.dart';
import 'package:book_recommendation_app/pages/welcome_page.dart';
import 'package:book_recommendation_app/services/api.dart';
import 'package:book_recommendation_app/widgets/app_navigation_shell.dart';

void main() => runApp(const BookApp());

// Load the authenticated user's borrowed books.
Future<List<Map<String, dynamic>>> _loadBorrowedBooks() async {
  final response = await Api.request(
    'GET',
    '/history',
  ).timeout(const Duration(seconds: 15));

  if (response is! Map || response['history'] is! List) {
    throw const FormatException(
      'Invalid borrowing history response.',
    );
  }

  final history = response['history'] as List;

  final Map<int, Map<String, dynamic>> booksById = {};
  final Map<int, int> borrowedCounts = {};
  final Map<int, int> returnedCounts = {};

  for (final item in history) {
    if (item is! Map) continue;

    final bookId = int.tryParse(
      '${item['book_id'] ?? ''}',
    );

    if (bookId == null) continue;

    final action = '${item['action'] ?? ''}'.toLowerCase();

    booksById.putIfAbsent(
      bookId,
      () => {
        // The return API requires the book ID.
        // This key matches what your existing page expects.
        'borrowing_id': bookId,
        'book_id': bookId,
        'title': item['title'] ?? 'Untitled book',
        'author': item['author'] ?? 'Unknown author',
        'status': 'borrowed',
        'due_date': null,
      },
    );

    if (action == 'borrowed') {
      borrowedCounts[bookId] = (borrowedCounts[bookId] ?? 0) + 1;
    } else if (action == 'returned') {
      returnedCounts[bookId] = (returnedCounts[bookId] ?? 0) + 1;
    }
  }

  final borrowedBooks = <Map<String, dynamic>>[];

  for (final entry in booksById.entries) {
    final bookId = entry.key;

    final activeCount =
        (borrowedCounts[bookId] ?? 0) - (returnedCounts[bookId] ?? 0);

    if (activeCount > 0) {
      entry.value['borrowed_count'] = activeCount;
      borrowedBooks.add(entry.value);
    }
  }

  return borrowedBooks;
}

// Connect the page's return callback to the existing API method.
Future<void> _returnBorrowedBook(int borrowingId) async {
  await Api.returnBook(borrowingId);
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BookWise',
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5559B8),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF454AA6),
            onPrimary: Colors.white,
            secondary: const Color(0xFF858BF0),
            onSecondary: const Color(0xFF191B3A),
            surface: const Color(0xFFFCFCFF),
            onSurface: const Color(0xFF242644),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F6FC),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE1E3F1),
            space: 1,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF5F6FC),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Color(0xFF202343),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
            iconTheme: IconThemeData(
              color: Color(0xFF454AA6),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF777BA0),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF999DB9),
            ),
            prefixIconColor: const Color(0xFF777DBA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDFE2F3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDFE2F3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6268D5),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFD95771),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFD95771),
                width: 2,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Color(0xFFE5E6F3),
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFEFF0FF),
            selectedColor: const Color(0xFFDDE0FF),
            labelStyle: const TextStyle(
              color: Color(0xFF414584),
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4D52B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF454AA6),
              side: const BorderSide(
                color: Color(0xFFD8DBF1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF202343),
            contentTextStyle: const TextStyle(
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Keep the Welcome page as the starting page.
        home: const WelcomePage(),

        routes: {
          // Public pages.
          '/welcome': (_) => const WelcomePage(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const LoginPage(startWithSignup: true),

          // Home page.
          '/home': (_) => const AppNavigationShell(
                currentRoute: '/home',
                child: HomePage(),
              ),

          // Dashboard page.
          '/dashboard': (_) => const AppNavigationShell(
                currentRoute: '/dashboard',
                child: DashboardPage(),
              ),

          // Book catalog.
          '/catalog': (_) => const AppNavigationShell(
                currentRoute: '/catalog',
                child: CatalogPage(),
              ),

          // Recommendations.
          '/recommendations': (_) => const AppNavigationShell(
                currentRoute: '/recommendations',
                child: RecommendationsPage(),
              ),

          // Borrowing and reading history.
          '/history': (_) => const AppNavigationShell(
                currentRoute: '/history',
                child: HistoryPage(),
              ),

          // My Borrowed Books.
          // My Borrowed Books.
          '/my-borrowed-books': (_) => const AppNavigationShell(
                currentRoute: '/my-borrowed-books',
                child: MyBorrowedBooksPage(
                  loadBooks: _loadBorrowedBooks,
                  returnBook: _returnBorrowedBook,
                ),
              ),
          // User profile.
          '/profile': (_) => const AppNavigationShell(
                currentRoute: '/profile',
                child: ProfilePage(),
              ),

          // Add a book.
          '/add-book': (_) => const AppNavigationShell(
                currentRoute: '/add-book',
                child: BookFormPage(),
              ),

          // Recommend a book.
          '/recommend-book': (_) => const AppNavigationShell(
                currentRoute: '/recommend-book',
                child: BookFormPage(recommendationMode: true),
              ),

          // Admin page.
          '/admin': (_) => const AdminDashboardPage(),
        },
      );
}
