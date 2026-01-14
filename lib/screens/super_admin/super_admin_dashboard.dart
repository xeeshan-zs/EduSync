import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/quiz_app_bar.dart';
import '../../widgets/quiz_app_drawer.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String _searchQuery = '';
  // Removed sort index for now as server-side sort is complex with other filters
  // int? _sortColumnIndex; 
  // bool _sortAscending = true;
  
  String _selectedRoleFilter = 'All';

  // Pagination State
  final List<UserModel> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  
  // Stats (Optional: fetch separately if needed, for now just what we have)
  int _totalLoaded = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      if (mounted) {
         setState(() {
          _users.clear();
          _lastDocument = null;
          _hasMore = true;
          _isLoading = true;
        });
      }
    } else {
      if (!_hasMore) return;
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final newUsers = await FirestoreService().getUsersPaginated(
        limit: 20,
        lastDocument: _lastDocument,
        roleFilter: _selectedRoleFilter,
        searchQuery: _searchQuery,
      );

      DocumentSnapshot? newLastDoc;
      if (newUsers.isNotEmpty) {
        // Optimization: In a real world scenario, you'd get the snapshot directly from the pagination service.
        // For now, to satisfy the signature and logic without rewriting everything, we fetch it.
        // But await cannot be in setState.
        newLastDoc = await FirestoreService().getUserDoc(newUsers.last.uid);
      }

      if (mounted) {
        setState(() {
          if (newUsers.length < 20) _hasMore = false;
          if (newLastDoc != null) {
            _lastDocument = newLastDoc;
          }
           _users.addAll(newUsers);
           _totalLoaded = _users.length;
           _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onFilterChanged(String val) {
    setState(() => _selectedRoleFilter = val);
    _fetchUsers(refresh: true);
  }

  void _onSearchChanged(String val) {
    // Basic debounce could be added here
    setState(() => _searchQuery = val);
    _fetchUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: QuizAppBar(user: user),
      drawer: QuizAppDrawer(user: user),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => _fetchUsers(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 120, 32, 40),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Main Content
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'System Overview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Full access stats and user management.',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildStatBadge(Icons.storage, '${_users.length} Loaded'),
                                  // Removed specific role counts as we don't have full list
                                  if (_isLoading) 
                                     _buildStatBadge(Icons.sync, 'Loading...'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Create Buttons (Responsive)
                        if (MediaQuery.of(context).size.width > 700) ...[
                           ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => context.push('/all-quizzes', extra: true), // true = canPause
                              icon: const Icon(Icons.assignment, size: 24),
                              label: const Text('Manage Quizzes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                           ),
                           const SizedBox(width: 16),
                           ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _showCreateUserDialog(context),
                              icon: const Icon(Icons.add_moderator, size: 24), 
                              label: const Text('Add User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                           ),
                        ],
                      ],
                    ),
                    // Mobile Buttons
                    if (MediaQuery.of(context).size.width <= 700) ...[
                       const SizedBox(height: 24),
                       Row(
                         children: [
                           Expanded(
                             child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.orangeAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => context.push('/all-quizzes', extra: true),
                                icon: const Icon(Icons.assignment),
                                label: const Text('Quizzes'),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => _showCreateUserDialog(context),
                                icon: const Icon(Icons.add_moderator), 
                                label: const Text('Add User'),
                             ),
                           ),
                         ],
                       ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Title & Search
             SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_chart_outlined, size: 28),
                        const SizedBox(width: 12),
                        Text('Master User List', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Role Filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoleFilter,
                                items: ['All', 'Student', 'Teacher', 'Admin', 'Super_admin']
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        ))
                                    .toList(),
                                onChanged: (val) => _onFilterChanged(val!),
                              ),
                            ),
                          ),
                          // Search Bar
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                              child: TextField(
                                onChanged: (v) => _onSearchChanged(v),
                                decoration: InputDecoration(
                                  hintText: 'Search Name...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.1),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                ),
                              ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // User List (Cards)
            if (_users.isEmpty && !_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No users found.')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _users.length) {
                         return _hasMore 
                           ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())) 
                           : const SizedBox(height: 40);
                      }

                      final u = _users[index];
                      final isSelf = u.uid == user?.uid;
                      final isSmallScreen = MediaQuery.of(context).size.width <= 600;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: isSmallScreen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Mobile Header
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: _getRoleColor(u.role).withOpacity(0.1),
                                          child: Icon(Icons.person, color: _getRoleColor(u.role)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(u.name + (isSelf ? ' (You)' : ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text(u.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text('UID: ${u.uid.substring(0, 8)}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    // Mobile Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(u.role).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(u.role.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(u.role))),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: u.isDisabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(u.isDisabled ? 'Disabled' : 'Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.isDisabled ? Colors.red : Colors.green)),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Switch(
                                              value: !u.isDisabled, 
                                              activeColor: Colors.green,
                                              onChanged: isSelf ? null : (val) {
                                                  firestoreService.toggleUserDisabled(u.uid, u.isDisabled);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                                              tooltip: 'Details',
                                              onPressed: () => _showUserDetails(context, u),
                                            ),
                                            if (!isSelf)
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                // Tooltip removed to prevent '_debugDuringDeviceUpdate' assertion
                                                onPressed: () => _confirmDeleteUser(context, u, firestoreService),
                                              ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              : Row(
                                  // Desktop Layout
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _getRoleColor(u.role).withOpacity(0.1),
                                      child: Icon(Icons.person, color: _getRoleColor(u.role)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u.name + (isSelf ? ' (You)' : ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(u.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('UID: ${u.uid.substring(0, 8)}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(u.role).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(u.role.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(u.role))),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: u.isDisabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(u.isDisabled ? 'Disabled' : 'Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.isDisabled ? Colors.red : Colors.green)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                             Switch(
                                              value: !u.isDisabled, 
                                              activeColor: Colors.green,
                                              onChanged: isSelf ? null : (val) {
                                                  firestoreService.toggleUserDisabled(u.uid, u.isDisabled);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                                              tooltip: 'Details',
                                              onPressed: () => _showUserDetails(context, u),
                                            ),
                                            if (!isSelf)
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                // Tooltip removed to prevent '_debugDuringDeviceUpdate' assertion
                                                onPressed: () => _confirmDeleteUser(context, u, firestoreService),
                                              ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                        ),
                      );
                    },
                    childCount: _users.length + 1, // +1 for loader
                  ),
                ),
              ),const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
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

  Widget _buildStatBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity( 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
      showDialog(context: context, builder: (c) => AlertDialog(
          title: Text(user.name),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                _detailRow('Email', user.email),
                _detailRow('Role', user.role.name),
                _detailRow('UID', user.uid),
                const Divider(),
                const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user.metadata.toString()),
             ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
      ));
  }

  void _confirmDeleteUser(BuildContext context, UserModel user, FirestoreService firestore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${user.name}"?'),
            const SizedBox(height: 12),
            const Text(
              'Warning:', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Text('• The user will be removed from the database.'),
            const Text('• They will immediately lose access.'),
            const Text('• They will strictly NOT be able to log in again.'),
            const SizedBox(height: 12),
            const Text('This action cannot be undone.', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
             style: FilledButton.styleFrom(backgroundColor: Colors.red),
             onPressed: () async {
               Navigator.pop(context); // Close Confirmation
               try {
                 await firestore.deleteUser(user.uid);
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User "${user.name}" deleted.')));
                 }
               } catch (e) {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
                 }
               }
             },
             child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
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
    final _passwordController = TextEditingController(); // Added
    final _nameController = TextEditingController();
    UserRole _selectedRole = UserRole.student;
    
    final _rollNoController = TextEditingController();
    final _classController = TextEditingController(); 
    
    bool _isSubmitting = false;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('New System User'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                  child: Form(
                      key: _formKey,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email', 
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField( // Password Field
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name', 
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<UserRole>(
                                  value: _selectedRole,
                                  items: UserRole.values
                                      .where((role) => role != UserRole.unknown)
                                      .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.name.toUpperCase()),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedRole = val!),
                                  decoration: InputDecoration(
                                    labelText: 'Role', 
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.shield_outlined),
                                  ),
                              ),
                              if (_selectedRole == UserRole.student) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                      controller: _rollNoController,
                                      decoration: InputDecoration(
                                        labelText: 'Roll Number', 
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        prefixIcon: const Icon(Icons.numbers),
                                      ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                      controller: _classController,
                                      decoration: InputDecoration(
                                        labelText: 'Class (e.g. BSCS-4B)', 
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        prefixIcon: const Icon(Icons.class_outlined),
                                      ),
                                  ),
                              ],
                          ],
                      ),
                  ),
              ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                    onPressed: _isSubmitting ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);
                        
                        try {
                           // 0. Check for Duplicates
                           final firestore = FirestoreService();
                           final emailExists = await firestore.checkEmailExists(_emailController.text);
                           if (emailExists) {
                             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Email already exists.')));
                             setState(() => _isSubmitting = false);
                             return;
                           }

                           if (_selectedRole == UserRole.student && _rollNoController.text.isNotEmpty) {
                              final rollExists = await firestore.checkRollNumberExists(_rollNoController.text);
                              if (rollExists) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Roll Number already exists.')));
                                setState(() => _isSubmitting = false);
                                return;
                              }
                           }

                           // 1. Create User in Auth to get UID
                           final uid = await AuthService().createUserByAdmin(
                             _emailController.text, 
                             _passwordController.text
                           );
                        
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
                        
                           // 2. Create User Document
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
