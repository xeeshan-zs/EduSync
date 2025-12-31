
import 'package:cloud_firestore/cloud_firestore.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.isNaN ? 0 : value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  return 0;
}

class ResultModel {
  final String id;
  final String quizId;
  final String quizTitle; // Added field
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final String className;
  final int score;
  final int totalMarks;
  final Map<String, int> answers; // QuestionId : SelectedIndex
  final DateTime submittedAt;

  ResultModel({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    required this.className,
    required this.score,
    required this.totalMarks,
    required this.answers,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'className': className,
      'score': score,
      'totalMarks': totalMarks,
      'answers': answers,
      'submittedAt': submittedAt.millisecondsSinceEpoch,
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    return ResultModel(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      quizTitle: map['quizTitle'] ?? 'Unknown Quiz',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRollNumber: map['studentRollNumber'] ?? '',
      className: map['className'] ?? '',
      score: _parseInt(map['score']),
      totalMarks: _parseInt(map['totalMarks']),
      answers: Map<String, int>.from(map['answers'] ?? {}),
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['submittedAt'] ?? 0),
    );
  }
}
