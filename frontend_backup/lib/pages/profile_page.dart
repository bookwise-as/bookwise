import 'package:flutter/material.dart';

import '../services/api.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> profile = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await Api.request('GET', '/profile');
      if (!mounted) return;
      setState(() {
        profile = Map<String, dynamic>.from(data);
        loading = false;
      });
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const AppDrawer(),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          load();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  )
                : Card(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 18),
                Text(
                  profile['name']?.toString() ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(profile['email']?.toString() ?? ''),
                const SizedBox(height: 20),
                const Text('Your account is protected by JWT authentication.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
