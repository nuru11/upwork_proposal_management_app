import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'providers/providers.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  AppDatabase? _database;
  Object? _error;
  var _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final future = AppDatabase.open();
      final database = kIsWeb
          ? await future.timeout(const Duration(seconds: 12))
          : await future;
      if (!mounted) return;
      setState(() {
        _database = database;
        _opening = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _opening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = _database;
    if (database != null) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const ProposalApp(),
      );
    }

    return MaterialApp(
      title: 'Proposal Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _BootScreen(
        error: _error,
        onRetry: _open,
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  width: 96,
                  height: 96,
                ),
                const SizedBox(height: 24),
                if (failed) ...[
                  const Text(
                    "Couldn't start storage.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teal,
                    ),
                    child: const Text('Retry'),
                  ),
                ] else
                  const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
