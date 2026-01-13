
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart'; // Ensure this exists or is handled
import 'providers/user_provider.dart';
import 'models/user_model.dart';
import 'models/quiz_model.dart';
import 'models/result_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/landing_page.dart';
import 'screens/about_us_screen.dart';
import 'screens/dashboards.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/student/quiz_attempt_screen.dart';
import 'screens/student/review_quiz_screen.dart';
import 'screens/student/grade_history_screen.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/teacher/create_quiz_screen.dart';
import 'screens/teacher/quiz_results_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/admin/all_quizzes_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/common/user_guide_screen.dart';
import 'screens/common/contact_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
      ],
      child: const MainAppRouter(),
    );
  }
}

class MainAppRouter extends StatelessWidget {
  const MainAppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch user provider to trigger redirects on auth state change
    final userProvider = context.watch<UserProvider>();

    // Determine initial route based on Platform
    // If Android or iOS (likely mobile app or mobile web), start at Login
    // kIsWeb check is important if we want specific web behavior, but user said "phone view".
    // Assuming "phone view" implies running on a phone.
    bool isMobile = defaultTargetPlatform == TargetPlatform.android || 
                    defaultTargetPlatform == TargetPlatform.iOS;
    
    final router = GoRouter(
      refreshListenable: userProvider,
      initialLocation: isMobile ? '/login' : '/',
      redirect: (context, state) {
        final isLoggedIn = userProvider.isLoggedIn;
        final path = state.uri.path;
        final isLoggingIn = path == '/login';
        final isAbout = path == '/about';
        final isRoot = path == '/';
        final isWelcome = path == '/welcome'; // Explicit Landing Page
        
        if (userProvider.isLoading) return null; 

        // 1. If Logged In, redirect Login -> Dashboard
        if (isLoggedIn && isLoggingIn) {
          return _getHomeRoute(userProvider.user?.role);
        }

        // 2. Allowed Public Paths (About, Welcome)
        if (isAbout || isWelcome) return null;

        // 3. Root Handling
        // If Logged In at Root, redirect to Dashboard
        if (isRoot && isLoggedIn) {
           return _getHomeRoute(userProvider.user?.role);
        }
        
        // 4. If Guest at Root, stay at Root (Landing Page)
        if (isRoot && !isLoggedIn) return null;

        // 5. If Guest and not on public pages -> Login
        if (!isLoggedIn && !isLoggingIn && !isRoot) {
          return '/login';
        }

        return null; // Allow navigation
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutUsScreen(),
        ),
        GoRoute(
          path: '/super_admin',
          builder: (context, state) => const SuperAdminDashboard(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherDashboard(),
          routes: [
            GoRoute(
              path: 'create-quiz',
              builder: (context, state) {
                final quizToEdit = state.extra as QuizModel?;
                return CreateQuizScreen(quizToEdit: quizToEdit);
              },
            ),
            GoRoute(
              path: 'results',
              builder: (context, state) {
                final quiz = state.extra as QuizModel;
                return QuizResultsScreen(quiz: quiz);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentDashboard(),
          routes: [
            GoRoute(
              path: 'history',
              builder: (context, state) => const GradeHistoryScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/attempt-quiz',
          builder: (context, state) {
            final quiz = state.extra as QuizModel;
            return QuizAttemptScreen(quiz: quiz);
          },
        ),
        GoRoute(
          path: '/review-quiz',
          builder: (context, state) {
            final result = state.extra as ResultModel;
            return ReviewQuizScreen(result: result);
          },
        ),
        GoRoute(
          path: '/all-quizzes',
          builder: (context, state) {
             final canPause = (state.extra as bool?) ?? false;
             return AllQuizzesScreen(canPause: canPause);
          },
        ),
        GoRoute(
          path: '/quiz-results/:id',
          builder: (context, state) {
            final quiz = state.extra as QuizModel;
            return QuizResultsScreen(quiz: quiz);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/user-guide',
          builder: (context, state) => const UserGuideScreen(),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactUsScreen(),
        ),
      ],
      // Theme Configuration with Google Fonts & Material 3
    );

    if (userProvider.isLoading) {
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp.router(
      title: 'EduSync',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Deep Purple base
          brightness: Brightness.light,
          primary: const Color(0xFF6750A4),
          secondary: const Color(0xFF625B71),
          tertiary: const Color(0xFF7D5260),
          surface: const Color(0xFFFFFBFE),
          background: const Color(0xFFFFFBFE),
        ),
        textTheme: GoogleFonts.outfitTextTheme(), // Modern geometric sans
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent, // For slivers
        ),
        // cardTheme: CardTheme(
        //   elevation: 0, 
        //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        //   color: const Color(0xFFF3F0F5), 
        //   margin: const EdgeInsets.symmetric(vertical: 8),
        // ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  String _getHomeRoute(UserRole? role) {
    switch (role) {
      case UserRole.super_admin:
        return '/super_admin';
      case UserRole.admin:
        return '/admin';
      case UserRole.teacher:
        return '/teacher';
      case UserRole.student:
        return '/student';
      default:
        return '/login'; // Or an error page
    }
  }
}
