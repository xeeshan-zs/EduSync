
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../models/result_model.dart';
import '../models/app_settings_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user: $e");
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  Future<DocumentSnapshot> getUserDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // --- Quiz Methods ---

  Future<void> createQuiz(QuizModel quiz) async {
    await _db.collection('quizzes').doc(quiz.id).set(quiz.toMap());
  }

  Stream<List<QuizModel>> getQuizzesForStudent() {
    return _db
        .collection('quizzes')
        .where('isPaused', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return QuizModel.fromMap(data);
            })
            .toList());
  }
  
  // Method for teacher/admin to see all quizzes
  // Paginated Quizzes Fetch
  Future<List<QuizModel>> getQuizzesPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
  }) async {
    Query query = _db.collection('quizzes');

    // Search or Default Sort
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .orderBy('title')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff']);
    } else {
      // Default: Newest first
      query = query.orderBy('createdAt', descending: true);
    }

    // Pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    try {
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return QuizModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Firestore Page Quiz Error: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getQuizDoc(String quizId) async {
    return await _db.collection('quizzes').doc(quizId).get();
  }

  Stream<List<QuizModel>> getAllQuizzes() {
    // Deprecated for large datasets, kept for backward compatibility if needed
    // or small lists.
    return _db
        .collection('quizzes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return QuizModel.fromMap(data);
            })
            .toList());
  }

  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      final doc = await _db.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        return QuizModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleQuizStatus(String quizId, bool currentStatus) async {
      await _db.collection('quizzes').doc(quizId).update({'isPaused': !currentStatus});
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection('quizzes').doc(quizId).delete();
  }

  // --- Result Methods ---

  Future<void> submitResult(ResultModel result) async {
    await _db.collection('results').doc(result.id).set(result.toMap());
  }

  Stream<List<ResultModel>> getResultsForStudent(String studentId) {
    return _db
        .collection('results')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResultModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<ResultModel>> getResultsByQuizId(String quizId) {
    return _db
        .collection('results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResultModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> cancelResult(String resultId) async {
    await _db.collection('results').doc(resultId).update({'isCancelled': true});
  }

  Future<int> getAttemptCount(String studentId, String quizId) async {
    final snapshot = await _db.collection('results')
        .where('studentId', isEqualTo: studentId)
        .where('quizId', isEqualTo: quizId)
        .get();
    return snapshot.docs.length;
  }
  
  // --- User Management (Admin) ---
  
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> toggleUserDisabled(String uid, bool currentStatus) async {
    await _db.collection('users').doc(uid).update({'isDisabled': !currentStatus});
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }
  
  Future<void> createUser(UserModel user, String password) async {
     // NOTE: This usually runs in cloud function or secondary app, 
     // but here we might use the client SDK if the signed in user is admin 
     // HOWEVER, client SDK creating another user signs out the current user.
     // For this simulation, we'll assume we just create the document and Auth is handled separately 
     // OR we rely on a specific flow. 
     // Since this is a detailed app, we simply save the user doc here.
     await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Paginated Users Fetch
  Future<List<UserModel>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? roleFilter,
    List<String>? allowedRoles, // New: For "whereIn" queries
    String? searchQuery,
  }) async {
    Query query = _db.collection('users');

    // Applied Filters
    if (roleFilter != null && roleFilter != 'All') {
       // specific role selected
       query = query.where('role', isEqualTo: roleFilter.toLowerCase());
    } else if (allowedRoles != null && allowedRoles.isNotEmpty) {
       // list of allowed roles (e.g. for Admin who can't see Super Admin)
       query = query.where('role', whereIn: allowedRoles.map((e) => e.toLowerCase()).toList());
    }

    // Search or Sort
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Case-sensitive prefix search (limitations apply)
      // Best practice: store a 'name_lowercase' field. 
      query = query
          .orderBy('name')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff']);
    } else {
      // Default Sort
      query = query.orderBy('name');
    }

    // Pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // Limit
    query = query.limit(limit);

    try {
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
         final data = doc.data() as Map<String, dynamic>;
         return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Firestore Pagination Error: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    // 1. Delete associated results (optional but good for cleanup)
    final resultsSnapshot = await _db.collection('results').where('studentId', isEqualTo: uid).get();
    for (final doc in resultsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 2. Delete the user document
    await _db.collection('users').doc(uid).delete();
  }

  Future<bool> checkEmailExists(String email) async {
    final snapshot = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> checkRollNumberExists(String rollNumber) async {
    // Note: 'metadata.rollNumber' requires an index or map navigation. 
    // If metadata is a map field, we use dot notation.
    final snapshot = await _db.collection('users').where('metadata.rollNumber', isEqualTo: rollNumber).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
  
  // --- App Settings (Links) ---
  
  Future<Map<String, String>> getAppLinks() async {
    try {
      final doc = await _db.collection('settings').doc('app_links').get();
      if (doc.exists && doc.data() != null) {
        return Map<String, String>.from(doc.data()!);
      }
    } catch (e) {
      print('Error fetching app links: $e');
    }
    return {
      'windows': '',
      'android': '',
      'web': '',
    };
  }

  Future<void> updateAppLinks(String windows, String android, String web) async {
    await _db.collection('settings').doc('app_links').set({
      'windows': windows,
      'android': android,
      'web': web,
    }, SetOptions(merge: true));
  }

  // --- App Content / Team Management ---

  Stream<AppSettingsModel> getAppSettings() {
    return _db.collection('app_settings').doc('general').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppSettingsModel.fromMap(doc.data()!);
      }
      return AppSettingsModel(teamName: 'Runtime Terrors'); // Default
    });
  }

  Future<void> updateAppSettings(AppSettingsModel settings) async {
    await _db.collection('app_settings').doc('general').set(
          settings.toMap(),
          SetOptions(merge: true),
        );
  }

  Stream<List<TeamMemberModel>> getTeamMembers() {
    return _db.collection('team_members').orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamMemberModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addTeamMember(TeamMemberModel member) async {
    // Auto-increment order
    final snapshot = await _db.collection('team_members').orderBy('order', descending: true).limit(1).get();
    int nextOrder = 0;
    if (snapshot.docs.isNotEmpty) {
      nextOrder = (snapshot.docs.first.data()['order'] as int? ?? 0) + 1;
    }

    final newMemberData = member.toMap();
    newMemberData['order'] = nextOrder;

    if (member.id.isEmpty) {
      await _db.collection('team_members').add(newMemberData);
    } else {
      await _db.collection('team_members').doc(member.id).set(newMemberData);
    }
  }

  Future<void> updateTeamOrder(List<TeamMemberModel> members) async {
    final batch = _db.batch();
    for (int i = 0; i < members.length; i++) {
        // Create a new map with the updated order
        // We can't modify the model directly as it might be final, so we create a map update
        batch.update(_db.collection('team_members').doc(members[i].id), {'order': i});
    }
    await batch.commit();
  }

  Future<void> updateTeamMember(TeamMemberModel member) async {
    await _db.collection('team_members').doc(member.id).update(member.toMap());
  }

  Future<void> deleteTeamMember(String id) async {
    await _db.collection('team_members').doc(id).delete();
  }
}
