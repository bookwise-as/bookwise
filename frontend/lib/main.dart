import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pages/admin_dashboard_page.dart';
import 'pages/book_form_page.dart';
import 'pages/catalog_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/recommendations_page.dart';
import 'pages/welcome_page.dart';
import 'widgets/app_navigation_shell.dart';

void main() => runApp(const BookApp());

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

        // Keep the existing public landing page as the first page.
        initialRoute: '/welcome',

        routes: {
          // Public pages — unchanged.
          '/welcome': (_) => const WelcomePage(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const LoginPage(startWithSignup: true),

          // HOME PAGE: book discovery and recommendations.
          '/home': (_) => const AppNavigationShell(
                currentRoute: '/home',
                child: HomePage(),
              ),

          // DASHBOARD PAGE: reading statistics and activities.
          '/dashboard': (_) => const AppNavigationShell(
                currentRoute: '/dashboard',
                child: DashboardPage(),
              ),

          // Explore the book catalog.
          '/catalog': (_) => const AppNavigationShell(
                currentRoute: '/catalog',
                child: CatalogPage(),
              ),

          // Personalized recommendations.
          '/recommendations': (_) => const AppNavigationShell(
                currentRoute: '/recommendations',
                child: RecommendationsPage(),
              ),

          // Borrowing and reading history.
          '/history': (_) => const AppNavigationShell(
                currentRoute: '/history',
                child: HistoryPage(),
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
