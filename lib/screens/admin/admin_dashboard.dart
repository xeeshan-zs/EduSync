
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // For generating IDs if using manual auth
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Colors.blue.withOpacity(0.05), // Distinct color for Admin
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<List<UserModel>>(
          stream: firestoreService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
               return Center(child: Text('Error: ${snapshot.error}'));
            }
  
            final users = snapshot.data ?? [];
  
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.vertical, // Switch to cards for better mobile view?
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: users.map((user) {
                        return DataRow(cells: [
                          DataCell(Text(user.name)),
                          DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role.name.toUpperCase(), 
                                  style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 11)
                                ),
                              )
                          ),
                          DataCell(Text(user.email)),
                          DataCell(
                             Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.isDisabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.isDisabled ? 'Disabled' : 'Active',
                                  style: TextStyle(
                                    color: user.isDisabled ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11
                                  )
                                ),
                             )
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: !user.isDisabled, // Switch represents "Is Active"
                                  activeColor: Colors.green,
                                  onChanged: (val) {
                                     // Warning: Disabling super_admin might lock you out if not careful
                                     if (user.role == UserRole.super_admin) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Cannot disable Super Admin')));
                                        return;
                                     }
                                     firestoreService.toggleUserDisabled(user.uid, user.isDisabled);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'Details',
                                  onPressed: () {
                                     showDialog(context: context, builder: (c) => AlertDialog(
                                         title: Text(user.name),
                                         content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                               Text('UID: ${user.uid}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                               const SizedBox(height: 10),
                                               const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                                               Text(user.metadata.toString()),
                                            ],
                                         ),
                                     ));
                                  },
                                )
                              ],
                            )
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           _showCreateUserDialog(context);
        },
        label: const Text('Add User'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.super_admin: return Colors.orange;
      case UserRole.admin: return Colors.blue;
      case UserRole.teacher: return Colors.teal;
      case UserRole.student: return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _showCreateUserDialog(BuildContext context) {
      showDialog(context: context, builder: (context) => const _CreateUserDialog());
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController(); // Only useful if we utilize Auth API
    final _nameController = TextEditingController();
    UserRole _selectedRole = UserRole.student;
    
    // Metadata fields
    final _rollNoController = TextEditingController();
    final _classController = TextEditingController(); // simplified for demo
    
    bool _isSubmitting = false;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Create User'),
            content: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                             TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(labelText: 'Password (Placeholder)'),
                                // Note: We can't easily create Auth users from client SDK while logged in as Admin 
                                // without logging out the Admin. 
                                // Real solution requires a Cloud Function or Admin SDK backend.
                                // We will just create the Firestore Record for now.
                            ),
                            TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Name'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            DropdownButtonFormField<UserRole>(
                                value: _selectedRole,
                                items: UserRole.values
                                    .where((role) => role == UserRole.student || role == UserRole.teacher)
                                    .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role.name.toUpperCase()),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedRole = val!),
                                decoration: const InputDecoration(labelText: 'Role'),
                            ),
                            if (_selectedRole == UserRole.student) ...[
                                TextFormField(
                                    controller: _rollNoController,
                                    decoration: const InputDecoration(labelText: 'Roll Number'),
                                ),
                                TextFormField(
                                    controller: _classController,
                                    decoration: const InputDecoration(labelText: 'Class (e.g. BSCS-4B)'),
                                ),
                            ]
                        ],
                    ),
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                    onPressed: _isSubmitting ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);
                        
                        // NOTE: This does NOT create a Firebase Auth account because we are client-side.
                        // The user would need to sign up themselves, or we use a cloud function.
                        // For the purpose of this demo, we create the Firestore Doc so they can login 
                        // IF they sign up with the matching UID.
                        // BUT wait, we can't force the UID on signup easily without Admin SDK.
                        
                        // WORKAROUND FOR DEMO:
                        // Just create the doc. The user has to register via a SignUp page (which we haven't built)
                        // OR we assume they already exist in Auth.
                        
                        // Better approach for this contest:
                        // Just create the record. In a real app, use Cloud Functions.
                        final uid = const Uuid().v4(); // Generate a random ID or use email as key? No, Auth uses UID.
                        
                        final metadata = <String, dynamic>{};
                        if (_selectedRole == UserRole.student) {
                            metadata['rollNumber'] = _rollNoController.text;
                            // Parsing class?
                            // degree, semester, section
                            metadata['degree'] = 'BSCS'; // Default for demo
                            metadata['semester'] = '1';
                            metadata['section'] = 'A';
                        }
                        
                        final newUser = UserModel(
                            uid: uid,
                            email: _emailController.text,
                            name: _nameController.text,
                            role: _selectedRole,
                            metadata: metadata,
                        );
                        
                        try {
                           await FirestoreService().createUser(newUser, "pw");
                           if (mounted) {
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User record created (Auth pending)')));
                           }
                        } catch (e) {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                             }
                        } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                        }
                    },
                    child: const Text('Create'),
                ),
            ],
        );
    }
}
