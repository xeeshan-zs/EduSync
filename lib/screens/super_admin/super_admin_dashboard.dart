
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Colors.deepPurple.shade100, // Distinctive color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UserProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           _showCreateUserDialog(context);
        },
        label: const Text('Add User'),
        icon: const Icon(Icons.admin_panel_settings),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
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
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Disabled')),
                DataColumn(label: Text('Actions')),
              ],
              rows: users.map((user) {
                final isSelf = user.uid == context.read<UserProvider>().user?.uid;
                
                return DataRow(
                  color: isSelf ? MaterialStateProperty.all(Colors.deepPurple.withOpacity(0.1)) : null,
                  cells: [
                  DataCell(Text(user.name + (isSelf ? ' (You)' : ''))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(), 
                        style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold)
                      ),
                    )
                  ),
                  DataCell(Text(user.email)),
                  DataCell(
                    Switch(
                      value: user.isDisabled,
                      onChanged: isSelf ? null : (val) { // Prevent disabling self
                         firestoreService.toggleUserDisabled(user.uid, user.isDisabled);
                      },
                    )
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                         showDialog(context: context, builder: (c) => AlertDialog(
                             title: Text('Details: ${user.name}'),
                             content: Column(
                               mainAxisSize: MainAxisSize.min,
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('ID: ${user.uid}'),
                                 const SizedBox(height: 8),
                                 Text('Metadata: ${user.metadata}'),
                               ],
                             ),
                         ));
                      },
                    )
                  ),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.super_admin: return Colors.orange;
      case UserRole.admin: return Colors.blue;
      case UserRole.teacher: return Colors.green;
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
    final _nameController = TextEditingController();
    UserRole _selectedRole = UserRole.student;
    
    // Metadata fields
    final _rollNoController = TextEditingController();
    final _classController = TextEditingController(); 
    
    bool _isSubmitting = false;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Create New User'),
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
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Name'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            DropdownButtonFormField<UserRole>(
                                value: _selectedRole,
                                items: UserRole.values.map((role) => DropdownMenuItem(
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
                            ],
                            const SizedBox(height: 10),
                            const Text(
                              'Note: This creates a Firestore record. The user must Sign Up or be created in Auth separately to verify credentials.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
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
                        
                        // NOTE: Super Admin creates any role including Admin/Teacher
                        final uid = const Uuid().v4(); 
                        
                        final metadata = <String, dynamic>{};
                        if (_selectedRole == UserRole.student) {
                            metadata['rollNumber'] = _rollNoController.text;
                            metadata['className'] = _classController.text;
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
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User record created')));
                           }
                        } catch (e) {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                             }
                        } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                        }
                    },
                    child: const Text('Create User'),
                ),
            ],
        );
    }
}
