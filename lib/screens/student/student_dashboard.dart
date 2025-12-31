import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/result_model.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<List<QuizModel>>(
        stream: _firestoreService.getQuizzesForStudent(),
        builder: (context, quizSnapshot) {
          if (quizSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (quizSnapshot.hasError) return Center(child: Text('Error: ${quizSnapshot.error}'));

          final quizzes = quizSnapshot.data ?? [];

          return StreamBuilder<List<ResultModel>>(
            stream: _firestoreService.getResultsForStudent(user.uid),
            builder: (context, resultSnapshot) {
              final results = resultSnapshot.data ?? [];
              final attemptedQuizIds = results.map((r) => r.quizId).toSet();
              // Fallback for old data
              final attemptedQuizTitles = results.where((r) => r.quizId.isEmpty).map((r) => r.quizTitle).toSet();

              final availableQuizzes = quizzes.where((q) {
                final isIdMatch = attemptedQuizIds.contains(q.id);
                final isTitleMatch = attemptedQuizTitles.contains(q.title);
                return !isIdMatch && !isTitleMatch;
              }).toList();

              return CustomScrollView(
                slivers: [
                  // Hero Section
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, // Use surface for clean look, or primaryContainer
                        // gradient: LinearGradient(
                        //   colors: [
                        //     Theme.of(context).colorScheme.primaryContainer,
                        //     Theme.of(context).colorScheme.surface,
                        //   ],
                        //   begin: Alignment.topCenter,
                        //   end: Alignment.bottomCenter,
                        // ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Brand/Logo Area
                              Row(
                                children: [
                                  Icon(Icons.school, color: Theme.of(context).colorScheme.primary, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    'QuizApp',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Nav Items
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {}, 
                                    icon: const Icon(Icons.home), 
                                    label: const Text('Home')
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.read<UserProvider>().logout(),
                                    icon: const Icon(Icons.logout), 
                                    label: const Text('Logout'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Welcome back, ${user.name}!',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ready to challenge yourself? Select an active quiz below or review your past achievements.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Available Quizzes',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${availableQuizzes.length} Active',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quiz Grid
                  if (availableQuizzes.isEmpty)
                     SliverToBoxAdapter(
                        child:  Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(child: Text("No quizzes available right now.", style: Theme.of(context).textTheme.bodyLarge)),
                        ),
                     )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400, // Responsive width
                          mainAxisExtent: 220, // Fixed height for consistency
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final quiz = availableQuizzes[index];
                            return _buildQuizCard(context, quiz);
                          },
                          childCount: availableQuizzes.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'QUIZ ID: ${quiz.id.substring(0, 6).toUpperCase()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const Spacer(),
            Row(
              children: [
                _buildInfoBadge(context, Icons.timer_outlined, '${quiz.durationMinutes} mins'),
                const SizedBox(width: 12),
                _buildInfoBadge(context, Icons.star_outline, '${quiz.totalMarks} Marks'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), // Custom Purple for button to match design
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push('/attempt-quiz', extra: quiz),
                child: const Text('Start Now →', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoBadge(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(width: 4),
            Flexible( // Prevent overflow
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
