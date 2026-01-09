import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/user_model.dart'; // For UserRole

class QuizAppDrawer extends StatelessWidget {
  final UserModel? user;

  const QuizAppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
               gradient: LinearGradient(
                  colors: [Color(0xFF2E236C), Color(0xFF433D8B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            ),
            accountName: Text(user!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(user!.email),
            currentAccountPicture: InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user!.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E236C)),
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); 
              context.push('/profile');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close drawer
               if (user!.role == UserRole.student) context.go('/student-dashboard');
               if (user!.role == UserRole.teacher) context.go('/teacher-dashboard');
               if (user!.role == UserRole.admin) context.go('/admin-dashboard');
               if (user!.role == UserRole.super_admin) context.go('/super-admin-dashboard');
            },
          ),
          
          if (user!.role == UserRole.student)
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text('My History'),
              onTap: () {
                Navigator.pop(context);
                context.push('/student/history');
              },
            ),

          if (user!.role == UserRole.teacher || user!.role == UserRole.admin || user!.role == UserRole.super_admin)
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Quiz'),
              onTap: () {
                Navigator.pop(context);
                context.push('/teacher/create-quiz');
              },
            ),

          if (user!.role == UserRole.admin || user!.role == UserRole.super_admin)
             ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('User Directory'),
              onTap: () {
                 Navigator.pop(context);
                 // Already on dashboard usually for admins
              },
            ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              context.push('/about');
            },
          ),
          
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.deepPurple),
            title: const Text('Logout', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            onTap: () {
               context.read<UserProvider>().logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
