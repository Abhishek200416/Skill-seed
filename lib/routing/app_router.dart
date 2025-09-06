// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Splash & Auth
import '../ui/screens/splash_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_student_screen.dart';
import '../ui/screens/auth/register_teacher_screen.dart';

// Dashboards
import '../ui/screens/admin/admin_dashboard.dart';
import '../ui/screens/teacher/teacher_dashboard.dart';
import '../ui/screens/student/student_dashboard.dart';

// Teacher
import '../ui/screens/teacher/upload_content_screen.dart';
import '../ui/screens/teacher/teacher_profile_screen.dart'; // NEW

// Student
import '../ui/screens/student/category_detail_screen.dart';
import '../ui/screens/student/student_profile_screen.dart';

// Tests / Live / Misc
import '../ui/screens/test/test_runner_screen.dart';
import '../ui/screens/leaderboard_screen.dart';
import '../ui/screens/notifications_screen.dart';
import '../ui/screens/live_join_screen.dart';

final appRouter = GoRouter(
  // If you want a non-root initial page, set: initialLocation: '/login',
  routes: [
    // Splash / Auth
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register/student',
      name: 'register_student',
      builder: (_, __) => const RegisterStudentScreen(),
    ),
    GoRoute(
      path: '/register/teacher',
      name: 'register_teacher',
      builder: (_, __) => const RegisterTeacherScreen(),
    ),

    // Admin
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (_, __) => const AdminDashboard(),
    ),

    // Teacher area
    GoRoute(
      path: '/teacher',
      name: 'teacher_dashboard',
      builder: (_, __) => const TeacherDashboard(),
    ),
    GoRoute(
      path: '/teacher/upload',
      name: 'teacher_upload',
      builder: (_, __) => const UploadContentScreen(),
    ),
    GoRoute(
      path: '/teacher/profile', // NEW dedicated screen
      name: 'teacher_profile',
      builder: (_, __) => const TeacherProfileScreen(),
    ),

    // Student area
    GoRoute(
      path: '/student',
      name: 'student_dashboard',
      builder: (_, __) => const StudentDashboard(),
    ),
    GoRoute(
      path: '/student/category',
      name: 'student_category',
      builder: (_, s) => CategoryDetailScreen(
        category: s.uri.queryParameters['name'] ?? 'COMMUNICATION',
      ),
    ),

    // Student profile (keeps your old '/profile' path and adds explicit alias)
    GoRoute(
      path: '/profile',
      name: 'student_profile_legacy',
      builder: (_, __) => const StudentProfileScreen(),
    ),
    GoRoute(
      path: '/student/profile',
      name: 'student_profile',
      builder: (_, __) => const StudentProfileScreen(),
    ),

    // Tests
    GoRoute(
      path: '/test/runner',
      name: 'test_runner',
      builder: (_, s) => TestRunnerScreen(
        paperId: s.uri.queryParameters['paperId']!,
      ),
    ),

    // Leaderboard / Notifications
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (_, s) => LeaderboardScreen(
        category: s.uri.queryParameters['category'] ?? 'COMMUNICATION',
      ),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),

    // Live join
    GoRoute(
      path: '/live/join',
      name: 'live_join',
      builder: (_, s) => LiveJoinScreen(
        sessionId: s.uri.queryParameters['sessionId']!,
        url: s.uri.queryParameters['url'], // optional
      ),
    ),
  ],
);
