import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/user_provider.dart';
import '../../widgets/quiz_app_bar.dart';
import '../../widgets/quiz_app_drawer.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  final String _phoneNumber = '+923109233844';
  final String _email = 'zeeshan303.3.1@gmail.com';

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchPhone() async {
    final Uri url = Uri(scheme: 'tel', path: _phoneNumber);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchWhatsApp() async {
    // WhatsApp URL format: https://wa.me/number (clean formatting)
    final cleanNumber = _phoneNumber.replaceAll(RegExp(r'\D'), ''); // Remove all non-digts
    final Uri url = Uri.parse('https://wa.me/$cleanNumber');
     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       // Fallback or retry? Usually http works.
       debugPrint('Could not launch WhatsApp');
     }
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=Inquiry from EduSync App',
    );
     if (!await launchUrl(url)) {
      debugPrint('Could not launch $_email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: QuizAppBar(user: user, isTransparent: false),
      drawer: QuizAppDrawer(user: user),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final padding = isMobile 
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 40);

          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, isMobile),
                    SizedBox(height: isMobile ? 32 : 48),
                    _buildContactCards(context, isMobile),
                    SizedBox(height: isMobile ? 40 : 60),
                    _buildFAQSection(context, isMobile),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Icon(Icons.support_agent_rounded, size: isMobile ? 48 : 64, color: const Color(0xFF2E236C))
            .animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          'Contact Us',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 32 : null,
                color: const Color(0xFF2E236C),
              ),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'We\'re here to help! Reach out to us via any of the platforms below.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontSize: isMobile ? 14 : null,
              ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildContactCards(BuildContext context, bool isMobile) {
    // On mobile, we might want full-width cards in a column
    // On desktop, we want a wrap or row
    
    final children = [
       _buildContactCard(
         icon: Icons.phone_rounded,
         title: 'Call Us',
         value: _phoneNumber,
         color: Colors.blue,
         onTap: _launchPhone,
         isMobile: isMobile,
       ),
       _buildContactCard(
         icon: FontAwesomeIcons.whatsapp,
         title: 'WhatsApp',
         value: 'Chat with us',
         color: Colors.green,
         onTap: _launchWhatsApp,
         isMobile: isMobile,
       ),
       _buildContactCard(
         icon: Icons.email_rounded,
         title: 'Email Us',
         value: _email,
         color: Colors.redAccent,
         onTap: _launchEmail,
         isMobile: isMobile,
       ),
    ];

    if (isMobile) {
      return Column(
        children: children.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: c,
        )).toList(),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: children,
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        hoverColor: color.withOpacity(0.05),
        child: Container(
          width: isMobile ? double.infinity : 250, // Full width on mobile
          padding: const EdgeInsets.all(24),
          child: isMobile 
            ? Row( // Row layout for mobile cards
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          value,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                ],
              )
            : Column( // Column layout for desktop cards
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
        ),
      ),
    ).animate().scale(delay: 300.ms);
  }

  Widget _buildFAQSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 22 : null,
            color: const Color(0xFF2E236C),
          ),
        ),
        const SizedBox(height: 24),
        _buildFAQTile(
          question: 'How do I take a quiz?',
          answer: 'Log in as a student, go to the dashboard, and click "Attempt" on any available quiz.',
        ),
        _buildFAQTile(
          question: 'Can I reset my password?',
          answer: 'Yes, go to settings or click "Forgot Password" on the login screen (if enabled by admin).',
        ),
        _buildFAQTile(
          question: 'Who do I contact for technical support?',
          answer: 'You can contact the Super Admin or use the WhatsApp link above for immediate assistance.',
        ),
        _buildFAQTile(
          question: 'Is EduSync free to use?',
          answer: 'EduSync is provided to institutions. Please check with your administration for access details.',
        ),
      ],
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
