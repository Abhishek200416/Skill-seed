import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/styles.dart';
import '../../../providers/auth_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentUserProvider);

    async.whenData((u) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final path = u == null
            ? '/login'
            : (u.role == 'admin'
                ? '/admin'
                : (u.role == 'teacher'
                    ? (u.isApproved ? '/teacher' : '/login')
                    : '/student'));
        context.go(path);
      });
    });

    return Scaffold(
      body: AnimatedPageGradient(
        child: Center(
          child: Glass(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                FlutterLogo(size: 28),
                SizedBox(width: 12),
                Text('SkillSeed',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(width: 16),
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
