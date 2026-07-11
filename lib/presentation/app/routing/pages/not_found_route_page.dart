import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandrr/presentation/app/routing/app_routes.dart';

class NotFoundRoutePage extends StatelessWidget {
  final String path;

  const NotFoundRoutePage({required this.path, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('The page "$path" does not exist.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.root),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
