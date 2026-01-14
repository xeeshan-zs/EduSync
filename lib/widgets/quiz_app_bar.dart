import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart'; // Ensure this import exists for UserRole

class QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final bool isTransparent;

  const QuizAppBar({
    super.key,
    required this.user,
    this.isTransparent = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AppBar(
      backgroundColor: Colors.transparent, // Always transparent so the flexibleSpace gradient shows
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: !isDesktop, // Show hamburger/back on mobile automatically
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E236C), Color(0xFF433D8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
             BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ]
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/welcome'),
                  child: const Text(
                    'EduSync',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isDesktop) ..._buildDesktopNavItems(context),
        
        const SizedBox(width: 16),
        
        // Profile / Logout Dropdown (Only if logged in)
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      backgroundImage: user!.photoUrl != null && user!.photoUrl!.isNotEmpty
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user!.photoUrl == null || user!.photoUrl!.isEmpty
                          ? Text(
                              user!.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 12),
                      Text(
                        user!.name.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                    ],
                  ],
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<UserProvider>().logout();
                } else if (value == 'profile') {
                  context.push('/profile');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(user!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(user!.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [Icon(Icons.person_outline, size: 20, color: Colors.black87), SizedBox(width: 12), Text('My Profile', style: TextStyle(color: Colors.black87))]),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [Icon(Icons.logout, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.redAccent))]),
                ),
              ],
            ),
          )
        else
          // Login Button (If Guest)
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
              label: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDesktopNavItems(BuildContext context) {
    // Defines links based on Role
    final links = <Widget>[];
    final currentPath = GoRouterState.of(context).uri.path;

    // Home Link (Landing Page)
    links.add(_NavTextButton(
      label: 'Home',
      icon: Icons.home_rounded,
      isActive: currentPath == '/welcome' || currentPath == '/',
      onPressed: () => context.go('/welcome'),
    ));

    // Links for Logged In Users
    if (user != null) {
      // Dashboard Link
      final isDashboard = currentPath.startsWith('/student') && !currentPath.contains('history') ||
                          currentPath.startsWith('/teacher') && !currentPath.contains('create-quiz') ||
                          currentPath.startsWith('/admin') ||
                          currentPath.startsWith('/super_admin');

      links.add(_NavTextButton(
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        isActive: isDashboard,
        onPressed: () {
          // Go to dashboard based on role
          if (user!.role == UserRole.student) context.go('/student');
          if (user!.role == UserRole.teacher) context.go('/teacher');
          if (user!.role == UserRole.admin) context.go('/admin');
          if (user!.role == UserRole.super_admin) context.go('/super_admin');
        },
      ));

      if (user?.role == UserRole.student) {
        links.add(_NavTextButton(
          label: 'History',
          icon: Icons.history_edu,
          isActive: currentPath.contains('/student/history'),
          onPressed: () => context.push('/student/history'),
        ));
      }

      if (user?.role == UserRole.teacher) {
        links.add(_NavTextButton(
          label: 'Create Quiz',
          icon: Icons.add_circle_outline,
          isActive: currentPath.contains('/teacher/create-quiz'),
          onPressed: () => context.push('/teacher/create-quiz'),
        ));
      }

      if (user?.role == UserRole.admin || user?.role == UserRole.super_admin) {
        links.add(_NavTextButton(
          label: 'Quiz List',
           icon: Icons.assignment,
           isActive: currentPath == '/all-quizzes',
           onPressed: () => context.push('/all-quizzes', extra: true), // extra=true for canPause
        ));
      }
      

    }

    // Common Links (Guest & Logged In)
    links.add(_NavTextButton(
      label: 'Our App',
      icon: Icons.install_desktop,
      isActive: currentPath == '/our-app',
      onPressed: () => context.push('/our-app'),
    ));

    links.add(_NavTextButton(
      label: 'Guide',
      icon: Icons.help_outline,
      isActive: currentPath == '/user-guide',
      onPressed: () => context.push('/user-guide'),
    ));

    links.add(_NavTextButton(
      label: 'Contact Us',
      icon: Icons.contact_support_outlined,
      isActive: currentPath == '/contact',
      onPressed: () => context.push('/contact'),
    ));

    links.add(_NavTextButton(
      label: 'About',
      icon: Icons.info_outline,
      isActive: currentPath == '/about',
      onPressed: () => context.push('/about'),
    ));

    return links;
  }
}

class _NavTextButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _NavTextButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 20,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: isActive ? Colors.white.withOpacity(0.15) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
