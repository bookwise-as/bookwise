import 'package:flutter/material.dart';
import '../services/api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.startWithSignup = false});

  final bool startWithSignup;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  late bool signup;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    signup = widget.startWithSignup;
  }

  @override
  void dispose() {
    email.dispose();
    name.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      final data = await Api.request(
        'POST',
        signup ? '/auth/signup' : '/auth/login',
        body: signup
            ? {
                'name': name.text,
                'email': email.text,
                'password': password.text
              }
            : {'email': email.text, 'password': password.text},
        auth: false,
      );

      await Api.saveAuth(data['token'], data['user']);

      if (mounted) {
        final role = data['user']?['role'] ?? 'user';

        Navigator.pushNamedAndRemoveUntil(
          context,
          !signup && role == 'admin' ? '/admin' : '/home',
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF163F34),
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to BookWise',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (_) => false,
            ),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC8942E).withValues(alpha: 0.28),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      color: const Color(0xFFFFFDF8),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const CircleAvatar(
                            radius: 34,
                            backgroundColor: Color(0xFFDCEBE2),
                            child: Icon(Icons.auto_stories,
                                size: 38, color: Color(0xFF1D5A46)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            signup ? 'Create your account' : 'Welcome back',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            signup
                                ? 'Start discovering books.'
                                : 'Sign in to continue your reading journey.',
                          ),
                          const SizedBox(height: 24),
                          if (signup)
                            TextField(
                              controller: name,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          if (signup) const SizedBox(height: 12),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loading ? null : submit,
                              child: Text(
                                loading
                                    ? 'Please wait...'
                                    : signup
                                        ? 'Sign up'
                                        : 'Sign in',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => signup = !signup),
                            child: Text(
                              signup
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
