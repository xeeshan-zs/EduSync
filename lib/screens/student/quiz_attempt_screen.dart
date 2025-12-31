
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/quiz_model.dart';
import '../../models/result_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class QuizAttemptScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizAttemptScreen({super.key, required this.quiz});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  late Timer _timer;
  late int _remainingSeconds;
  final PageController _pageController = PageController();
  final Map<String, int> _answers = {}; // questionId : selectedIndex
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.quiz.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _timer.cancel();

    final user = context.read<UserProvider>().user!;
    
    // Calculate Score
    int score = 0;
    for (var question in widget.quiz.questions) {
        final selected = _answers[question.id];
        if (selected != null && selected == question.correctOptionIndex) {
            score++; // Assuming 1 mark per question for simplicity, or handle complex marking
        }
    }
    
    // Adjust if totalMarks logic is different (e.g., evenly distributed)
    // For now assuming simplified logic: score is count of correct answers.
    // If totalMarks is fixed, we might scale it.
    // Let's assume question weight = totalMarks / questionCount
    double scoreValue = 0;
    if (widget.quiz.questions.isNotEmpty) {
       final double marksPerQ = widget.quiz.totalMarks / widget.quiz.questions.length;
       for (var question in widget.quiz.questions) {
          final selected = _answers[question.id];
          if (selected != null && selected == question.correctOptionIndex) {
              scoreValue += marksPerQ;
          }
       }
    }

    final result = ResultModel(
      id: const Uuid().v4(),
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      studentId: user.uid,
      studentName: user.name,
      studentRollNumber: user.rollNumber ?? 'N/A',
      className: user.className,
      score: scoreValue.round(),
      totalMarks: widget.quiz.totalMarks,
      answers: _answers,
      submittedAt: DateTime.now(),
    );

    try {
      await FirestoreService().submitResult(result);
      if (mounted) {
         // Show success and pop
         showDialog(
             context: context, 
             barrierDismissible: false,
             builder: (c) => AlertDialog(
                 title: const Text('Quiz Submitted'),
                 content: Text('Your score: ${result.score} / ${result.totalMarks}'),
                 actions: [
                     TextButton(
                         onPressed: () { 
                             context.go('/student'); // Return to dashboard
                         },
                         child: const Text('OK'),
                     )
                 ],
             ),
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
         setState(() => _isSubmitting = false);
      }
    }
  }

  String get _timerText {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _timerText,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.quiz.questions.length,
        itemBuilder: (context, index) {
          final question = widget.quiz.questions[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1} of ${widget.quiz.questions.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ...List.generate(question.options.length, (optIndex) {
                  final option = question.options[optIndex];
                  final isSelected = _answers[question.id] == optIndex;

                  return Card(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<int>(
                      value: optIndex,
                      groupValue: _answers[question.id],
                      title: Text(option),
                      onChanged: _isSubmitting ? null : (val) {
                        setState(() {
                          _answers[question.id] = val!;
                        });
                      },
                    ),
                  );
                }),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      FilledButton.tonal(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox.shrink(),
                    
                    if (index < widget.quiz.questions.length - 1)
                      FilledButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Next'),
                      )
                    else
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _submitQuiz,
                        child: _isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Text('Submit'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
