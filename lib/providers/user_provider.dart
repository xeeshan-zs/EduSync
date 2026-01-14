
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  bool get isLoggedIn => _user != null;
  bool get isSuperAdmin => _user?.role == UserRole.super_admin;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isTeacher => _user?.role == UserRole.teacher;
  bool get isStudent => _user?.role == UserRole.student;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners(); // Notify loading start if needed
    try {
      _user = await _authService.getCurrentUser();
    } catch (e) {
      print("Error loading user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.signIn(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, {Map<String, dynamic>? metadata, String? photoUrl}) async {
    if (_user == null) return;
    
    // Create updated user object
    final updatedUser = UserModel(
      uid: _user!.uid,
      email: _user!.email,
      name: name,
      role: _user!.role,
      photoUrl: photoUrl ?? _user!.photoUrl,
      isDisabled: _user!.isDisabled,
      metadata: metadata ?? _user!.metadata,
    );

    _isLoading = true;
    notifyListeners();
    try {
      await FirestoreService().updateUser(updatedUser);
      _user = updatedUser; // Update local state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updatePassword(newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
     _isLoading = true;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
