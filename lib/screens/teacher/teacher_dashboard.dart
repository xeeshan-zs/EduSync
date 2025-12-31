
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ideally filter by the teacher's ID, but for now we might show all or implement filtering in service
    // For this requirements: "My Quizzes" -> List of created quizzes.
    // We'll update FirestoreService to support filtering if not already done, or client side filter.
    final user = context.watch<UserProvider>().user;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text('Teacher Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<UserProvider>().logout(),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.teal.withOpacity(0.05), // Distinct color for Teacher
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<List<QuizModel>>(
          stream: firestoreService.getAllQuizzes(), // We'll filter client side for now or update service
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
               return Center(child: Text('Error: ${snapshot.error}'));
            }
  
            final allQuizzes = snapshot.data ?? [];
            // Client side filter for "My Quizzes"
            final myQuizzes = allQuizzes.where((q) => q.createdByUid == user?.uid).toList();
  
            if (myQuizzes.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.library_add_outlined, size: 64, color: Theme.of(context).colorScheme.secondary),
                     const SizedBox(height: 16),
                     Text('No quizzes created yet', style: Theme.of(context).textTheme.titleMedium),
                     const SizedBox(height: 8),
                     FilledButton.tonal(
                        onPressed: () => context.push('/teacher/create-quiz'),
                        child: const Text('Create Your First Quiz'),
                     ),
                   ],
                 ),
               );
            }
  
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = myQuizzes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Expanded(
                              child: Text(
                                quiz.title, 
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                              )
                             ),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                               decoration: BoxDecoration(
                                 color: quiz.isPaused ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: Text(
                                 quiz.isPaused ? 'Paused' : 'Active',
                                 style: TextStyle(
                                   color: quiz.isPaused ? Colors.red : Colors.green,
                                   fontWeight: FontWeight.bold
                                 ),
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                            children: [
                              Icon(Icons.help_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text('${quiz.questions.length} Questions', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(width: 16),
                              Icon(Icons.grade_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text('${quiz.totalMarks} Marks', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Live Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Switch(
                             value: !quiz.isPaused, 
                             activeColor: Colors.green,
                             onChanged: (val) {
                               firestoreService.toggleQuizStatus(quiz.id, quiz.isPaused);
                             }
                           ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/teacher/create-quiz');
        },
        label: const Text('New Quiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
