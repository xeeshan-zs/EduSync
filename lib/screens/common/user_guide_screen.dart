import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/quiz_app_bar.dart';
import '../../widgets/quiz_app_drawer.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final role = user?.role ?? UserRole.unknown;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: QuizAppBar(user: user, isTransparent: false),
      drawer: QuizAppDrawer(user: user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, role),
                const SizedBox(height: 32),
                _buildGuideContent(context, role),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserRole role) {
    String title = 'User Guide';
    String subtitle = 'Learn how to use EduSync effectively.';
    IconData icon = Icons.help_outline;

    switch (role) {
      case UserRole.student:
        title = 'Student Guide';
        subtitle = 'Everything you need to know about taking quizzes and tracking your progress.';
        icon = Icons.school;
        break;
      case UserRole.teacher:
        title = 'Teacher Guide';
        subtitle = 'How to create, manage, and review quizzes for your students.';
        icon = Icons.menu_book;
        break;
      case UserRole.admin:
        title = 'Admin Guide';
        subtitle = 'Managing the system, users, and overseeing quiz operations.';
        icon = Icons.admin_panel_settings;
        break;
      case UserRole.super_admin:
        title = 'Super Admin Guide';
        subtitle = 'Full system control, user management, and advanced configurations.';
        icon = Icons.security;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2E236C),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildGuideContent(BuildContext context, UserRole role) {
    List<GuideSection> sections = [];

    if (role == UserRole.student) {
      sections = [
        GuideSection(
          title: 'Taking Quizzes',
          content: 'Navigate to your Dashboard to see "Available Quizzes". Click "Attempt" to start a quiz. Make sure to submit before the timer runs out!',
          icon: Icons.timer,
        ),
        GuideSection(
          title: 'Viewing Results',
          content: 'After submitting a quiz, you can immediately see your score. For detailed feedback and to see correct answers, go to the "History" section or click "Review" on the result page.',
          icon: Icons.analytics,
        ),
        GuideSection(
          title: 'Managing Profile',
          content: 'You can update your profile details and change your password from the "My Profile" section in the menu.',
          icon: Icons.person,
        ),
      ];
    } else if (role == UserRole.teacher) {
      sections = [
        GuideSection(
          title: 'Creating Quizzes',
          content: 'Use the "Create Quiz" button on your dashboard. You can set the title, duration, marks, and add multiple-choice questions. You can edit quizzes later if needed.',
          icon: Icons.add_circle,
        ),
        GuideSection(
          title: 'Monitoring Results',
          content: 'In your dashboard, you can see all quizzes you have created. Click on "View Results" to see a list of students who attempted the quiz and their scores.',
          icon: Icons.people,
        ),
        GuideSection(
          title: 'Reviewing Attempts',
          content: 'Click on a specific student result to see their detailed attempt, including which questions they got right or wrong.',
          icon: Icons.rate_review,
        ),
      ];
    } else if (role == UserRole.admin) {
      sections = [
        GuideSection(
          title: 'Managing Quizzes',
          content: 'You have access to all quizzes in the system via the "Quiz List". you can pause quizzes to prevent students from taking them.',
          icon: Icons.library_books,
        ),
        GuideSection(
          title: 'User Overview',
          content: 'The Admin Dashboard gives you a quick overview of system stats, including active quizzes and total users.',
          icon: Icons.dashboard,
        ),
        GuideSection(
          title: 'Pausing Quizzes',
          content: 'If a quiz has errors or needs to be stopped, use the toggle switch in the Quiz List to pause it instantly.',
          icon: Icons.pause_circle_filled,
        ),
      ];
    } else if (role == UserRole.super_admin) {
      sections = [
        GuideSection(
          title: 'User Management',
          content: 'You have full control over users. You can "Add User" (Students, Teachers, Admins) and disable/enable accounts from the "Master User List".',
          icon: Icons.supervised_user_circle,
        ),
        GuideSection(
          title: 'Full Quiz Control',
          content: 'You can Edit and Delete ANY quiz in the system. Go to the "Quiz List" to manage them. Be careful, deletion is permanent!',
          icon: Icons.delete_forever,
        ),
        GuideSection(
          title: 'System Health',
          content: 'Monitor the total number of records and active users directly from your dashboard.',
          icon: Icons.monitor_heart,
        ),
      ];
    } else {
      sections = [
        GuideSection(
          title: 'Getting Started',
          content: 'Please log in to access the features available for your role.',
          icon: Icons.login,
        ),
      ];
    }

    return Column(
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _GuideCard(section: section, delay: index * 100),
        );
      }).toList(),
    );
  }
}

class GuideSection {
  final String title;
  final String content;
  final IconData icon;

  GuideSection({required this.title, required this.content, required this.icon});
}

class _GuideCard extends StatelessWidget {
  final GuideSection section;
  final int delay;

  const _GuideCard({required this.section, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(section.icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.1, end: 0);
  }
}
