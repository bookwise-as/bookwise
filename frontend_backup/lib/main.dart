import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pages/admin_dashboard_page.dart';
import 'pages/book_form_page.dart';
import 'pages/catalog_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/recommendations_page.dart';
import 'pages/welcome_page.dart';

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
            seedColor: const Color(0xFFC8942E),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFBF7EF),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE9DDC7),
            space: 1,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Color(0xFF211A12),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFCF6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            labelStyle: const TextStyle(color: Color(0xFF806F5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9DDC7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9DDC7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFC8942E),
                width: 2,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFFFFDF8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFEFE4D1)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFFFF0C7),
            selectedColor: const Color(0xFFC8942E),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
          ),
        ),
        initialRoute: '/welcome',
        routes: {
          '/welcome': (_) => const WelcomePage(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const LoginPage(startWithSignup: true),
          '/home': (_) => const HomePage(),
          '/catalog': (_) => const CatalogPage(),
          '/recommendations': (_) => const RecommendationsPage(),
          '/history': (_) => const HistoryPage(),
          '/profile': (_) => const ProfilePage(),
          '/add-book': (_) => const BookFormPage(),
          '/recommend-book': (_) =>
              const BookFormPage(recommendationMode: true),
          '/admin': (_) => const AdminDashboardPage(),
        },
      );
}
