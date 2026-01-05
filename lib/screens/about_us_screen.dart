import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B2E),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E236C),
                    Color(0xFF433D8B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       // Brand
                       const Row(
                         children: [
                           Icon(Icons.info_outline, color: Colors.white, size: 28),
                           SizedBox(width: 8),
                           Text(
                             'About QuizApp', 
                             style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                           ),
                         ],
                       ),
                       // Back Button
                       FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                      ),
                    ],
                   ),
                   const SizedBox(height: 60),
                   const Text(
                     'Empowering Education',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 32,
                       fontWeight: FontWeight.bold,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 16),
                   const Text(
                     'QuizApp is a comprehensive platform designed to streamline assessments and enhance learning outcomes for students and teachers alike.',
                     style: TextStyle(color: Colors.white70, fontSize: 16),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // About App Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Our goal is to provide a seamless, secure, and engaging environment for online examinations. With features like real-time grading, detailed analytics, and role-based access control, we ensure that the focus remains on what matters most: learning.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // Meet the Team Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                   Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary),
                   const SizedBox(width: 8),
                   Text(
                     'Meet the Team',
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                   ),
                ],
              ),
            ),
          ),

          // Team Grid
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 380, // Taller for avatars
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildListDelegate([
                 _buildTeamCard(
                   context, 
                   'Zeeshan Sarfraz', 
                   '', 
                   '',
                   'assets/images/team/zeeshan_avatar.png',
                   0,
                   socialLinks: {
                     'web': 'https://zeeshan-sarfraz.web.app',
                     'linkedin': 'https://linkedin.com/in/xeeshan-zs',
                     'github': 'https://github.com/xeeshan-zs',
                   }
                 ),
                 _buildTeamCard(
                   context, 
                   'Hammad Saleem', 
                   '', 
                   '',
                   'assets/images/team/hammad_avatar.png',
                   1,
                 ),
                 _buildTeamCard(
                   context, 
                   'Muneeb Ali', 
                   '', 
                   '',
                   'assets/images/team/muneeb_avatar.png',
                   2,
                 ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, String name, String role, String description, String imagePath, int index, {Map<String, String>? socialLinks}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120), // Spacer to push text down
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (role.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.blueAccent.shade100,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (socialLinks != null && socialLinks.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Social Icons
                Row(
                  children: [
                    if (socialLinks.containsKey('web'))
                      _buildSocialIcon(socialLinks['web']!, Icons.language),
                    if (socialLinks.containsKey('linkedin'))
                      _buildSocialIcon(socialLinks['linkedin']!, FontAwesomeIcons.linkedin),
                    if (socialLinks.containsKey('github'))
                      _buildSocialIcon(socialLinks['github']!, FontAwesomeIcons.github),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 150 * index))
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSocialIcon(String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
