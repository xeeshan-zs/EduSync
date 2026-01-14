
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/quiz_app_bar.dart';
import '../../widgets/quiz_app_drawer.dart';
import '../../utils/pwa_helper.dart';

class OurAppScreen extends StatefulWidget {
  const OurAppScreen({super.key});

  @override
  State<OurAppScreen> createState() => _OurAppScreenState();
}

class _OurAppScreenState extends State<OurAppScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, String> _links = {
    'windows': '',
    'android': '',
    'web': '',
  };
  bool _isLoading = true;
  final PwaInstallManager _pwaManager = PwaInstallManager();

  @override
  void initState() {
    super.initState();
    _loadLinks();
    _pwaManager.init(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadLinks() async {
    final links = await _firestoreService.getAppLinks();
    if (mounted) {
      setState(() {
        _links = links;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.super_admin;

    return Scaffold(
      appBar: QuizAppBar(user: user),
      drawer: QuizAppDrawer(user: user),
      backgroundColor: Colors.grey[50],
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.edit),
        label: const Text('Manage Links'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ) : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Download Our App',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Experience EduSync on your favorite devices.',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildAppCard(
                    title: 'Windows Desktop',
                    icon: Icons.desktop_windows,
                    description: 'Download the .msi installer for Windows 10/11. Native performance and offline capabilities.',
                    buttonText: 'Download for Windows',
                    link: _links['windows'] ?? '',
                    color: Colors.blue[700]!,
                  ),
                  _buildAppCard(
                    title: 'Android App',
                    icon: Icons.android,
                    description: 'Get the .apk file for your Android phone or tablet. Learning on the go.',
                    buttonText: 'Download APK',
                    link: _links['android'] ?? '',
                    color: Colors.green[600]!,
                  ),
                  _buildAppCard(
                    title: 'Web / Desktop App',
                    icon: Icons.web_asset,
                    description: 'Install this website as a native app on your device for quick access. No download needed.',
                    buttonText: 'Install',
                    link: '', 
                    color: Colors.orange[600]!,
                    isPrimary: true, 
                    onPressedOverride: () => _attemptInstall(),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  void _attemptInstall() {
    if (_pwaManager.canInstall) {
      _pwaManager.promptInstall();
    } else {
      _showPwaInstructions();
    }
  }

  void _showPwaInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.install_mobile), SizedBox(width: 12), Text('Install App')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You can install this app directly from your browser!'),
            const SizedBox(height: 16),
            const Text('On Desktop (Chrome/Edge):', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Click the "Install" icon in the address bar (top right).'),
            const SizedBox(height: 12),
            const Text('On Mobile (Chrome):', style: TextStyle(fontWeight: FontWeight.bold)),
             const Text('Tap the menu (⋮) -> "Add to Home Screen" or "Install App".'),
             const SizedBox(height: 12),
             const Text('On iOS (Safari):', style: TextStyle(fontWeight: FontWeight.bold)),
             const Text('Tap the Share button -> "Add to Home Screen".'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildAppCard({
    required String title,
    required IconData icon,
    required String description,
    required String buttonText,
    required String link,
    required Color color,
    bool isPrimary = true,
    VoidCallback? onPressedOverride,
  }) {
    final bool hasLink = link.trim().isNotEmpty;
    final bool isActionable = hasLink || onPressedOverride != null;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 24),
          if (isActionable)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressedOverride ?? () => _launchUrl(link),
                icon: Icon(isPrimary ? Icons.download : Icons.info_outline),
                label: Text(buttonText),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Coming Soon', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final windowsController = TextEditingController(text: _links['windows']);
    final androidController = TextEditingController(text: _links['android']);
    // Web controller removed

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage App Links'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(controller: windowsController, decoration: const InputDecoration(labelText: 'Windows (.msi) URL', hintText: 'https://github.com/...')),
             const SizedBox(height: 16),
             TextField(controller: androidController, decoration: const InputDecoration(labelText: 'Android (.apk) URL', hintText: 'https://github.com/...')),
             const SizedBox(height: 16),
             const Text('Note: The Web App card uses generic "Add to Home Screen" instructions and does not require a link.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _firestoreService.updateAppLinks(
                windowsController.text.trim(),
                androidController.text.trim(),
                _links['web'] ?? '', // Keep existing if any, or empty. We don't update it anymore.
              );
              if (mounted) {
                Navigator.pop(context);
                _loadLinks(); // Refresh
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Links updated successfully')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
