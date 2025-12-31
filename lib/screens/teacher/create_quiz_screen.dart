
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/quiz_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import 'package:go_router/go_router.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();

  final List<Question> _questions = [];
  bool _isSubmitting = false;

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        onAdd: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = context.read<UserProvider>().user;
      final quizId = const Uuid().v4();

      // If user manually enters total marks, use it. 
      // OR calculate from questions (e.g. 1 mark each). 
      // For now, let's respect the controller input, 
      // but if empty/zero, maybe auto-calc? 
      // Let's stick to the form input for simplicity as per requirements.
      int totalMarks = int.tryParse(_marksController.text) ?? 0;

      final quiz = QuizModel(
        id: quizId,
        title: _titleController.text.trim(),
        createdByUid: user?.uid ?? 'unknown',
        createdAt: DateTime.now(),
        totalMarks: totalMarks,
        durationMinutes: int.parse(_durationController.text),
        questions: _questions,
        isPaused: false,
      );

      await FirestoreService().createQuiz(quiz);
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz Created!')));
         context.pop();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Quiz')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Quiz Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(labelText: 'Duration (Mins)'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _marksController,
                          decoration: const InputDecoration(labelText: 'Total Marks'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions (${_questions.length})', style: Theme.of(context).textTheme.titleMedium),
                      IconButton.filledTonal(
                        onPressed: _addQuestion, 
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Question',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_questions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No questions added yet.')),
                    )
                  else
                    ..._questions.map((q) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(q.text),
                            subtitle: Text('Correct: ${q.options[q.correctOptionIndex]}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _questions.remove(q);
                                });
                              },
                            ),
                          ),
                        )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitQuiz,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save & Publish Quiz'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final Function(Question) onAdd;
  const _AddQuestionDialog({required this.onAdd});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _qTextController = TextEditingController();
  // Fixed 4 options for simplicity, can be dynamic
  final List<TextEditingController> _optionControllers = 
      List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _qTextController,
              decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Options:'),
            ...List.generate(4, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: _correctIndex,
                onChanged: (val) => setState(() => _correctIndex = val!),
                title: TextFormField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(hintText: 'Option ${index + 1}'),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_qTextController.text.isEmpty) return;
            // Basic validation: ensure options aren't empty
            if (_optionControllers.any((c) => c.text.isEmpty)) return;

            final q = Question(
              id: const Uuid().v4(),
              text: _qTextController.text,
              options: _optionControllers.map((c) => c.text).toList(),
              correctOptionIndex: _correctIndex,
            );
            widget.onAdd(q);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
