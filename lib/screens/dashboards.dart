
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// Generic Scaffold for Dashboards
class DashboardScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const DashboardScaffold({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<UserProvider>().logout();
            },
          ),
        ],
      ),
      body: body,
    );
  }
}






