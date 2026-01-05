import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';

class AllQuizzesScreen extends StatelessWidget {
  final bool canPause;

  const AllQuizzesScreen({super.key, required this.canPause});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<List<QuizModel>>(
        stream: firestoreService.getAllQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final quizzes = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Connected AppBar
              SliverAppBar(
                floating: true,
                pinned: true,
                title: Text(canPause ? 'Manage All Quizzes' : 'All Quizzes'),
                backgroundColor: const Color(0xFF2E236C),
                foregroundColor: Colors.white,
                actions: [
                   if (canPause)
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Super Admin Access',
                      onPressed: () {},
                    ),
                ],
              ),
              
              if (quizzes.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No quizzes available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 240,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quiz = quizzes[index];
                        return _buildQuizCard(context, quiz, firestoreService);
                      },
                      childCount: quizzes.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz, FirestoreService firestoreService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Gradient decoration (subtle)
           Positioned(
            top: -20,
            right: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF2E236C).withOpacity(0.05),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                       decoration: BoxDecoration(
                         color: quiz.isPaused ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Text(
                         quiz.isPaused ? 'Paused' : 'Active',
                         style: TextStyle(
                           color: quiz.isPaused ? Colors.red : Colors.green,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                     ),
                     if (canPause)
                       SizedBox(
                         height: 24,
                         child: Switch(
                           value: !quiz.isPaused, 
                           onChanged: (val) => firestoreService.toggleQuizStatus(quiz.id, quiz.isPaused),
                           activeColor: Colors.green,
                           inactiveTrackColor: Colors.red.withOpacity(0.3),
                         ),
                       ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${quiz.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                ),
                const Spacer(),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       context.push('/quiz-results/${quiz.id}', extra: quiz);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E236C),
                      side: const BorderSide(color: Color(0xFF2E236C)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('View Results'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
