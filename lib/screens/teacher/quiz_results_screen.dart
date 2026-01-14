import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../models/result_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/quiz_app_bar.dart';
import '../../widgets/quiz_app_drawer.dart';

class QuizResultsScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizResultsScreen({super.key, required this.quiz});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterClass = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: QuizAppBar(user: user, isTransparent: true),
      drawer: QuizAppDrawer(user: user),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Header / Hero Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 120, 32, 40), // Increased top padding
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B2E), // Match Teacher Dashboard Dark Theme
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E236C),
                    Color(0xFF433D8B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Removed Manual Row
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                                'Quiz Results',
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             'Results for: ${widget.quiz.title}',
                             style: const TextStyle(color: Colors.white70, fontSize: 18),
                           ),
                         ],
                       ),
                       FilledButton.icon(
                         onPressed: () => _showAnswerKey(context),
                         icon: const Icon(Icons.key), 
                         label: const Text('Answer Key'),
                         style: FilledButton.styleFrom(
                           backgroundColor: Colors.white.withOpacity(0.2), 
                           foregroundColor: Colors.white,
                         ),
                       ),
                     ],
                   ),
                ],
              ),
            ),
          ),

          // Search / Filter and Table
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Modern Search Bar
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(30),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: TextField(
                       controller: _searchController,
                       decoration: InputDecoration(
                         hintText: 'Filter by Class (e.g. BSCS-4B)',
                         hintStyle: TextStyle(color: Colors.grey[400]),
                         prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                         border: InputBorder.none,
                         enabledBorder: InputBorder.none,
                         focusedBorder: InputBorder.none,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                         fillColor: Colors.transparent, 
                       ),
                       onChanged: (val) {
                         setState(() {
                           _filterClass = val;
                         });
                       },
                     ),
                   ),
                   const SizedBox(height: 32),

                   // Results Table Container
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 15,
                           offset: const Offset(0, 5),
                         )
                       ],
                     ),
                     clipBehavior: Clip.antiAlias,
                     child: StreamBuilder<List<ResultModel>>(
                       stream: firestoreService.getResultsByQuizId(widget.quiz.id),
                       builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          final allResults = snapshot.data ?? [];
                          // Filter results
                          final filteredByClass = allResults.where((r) {
                            if (_filterClass.isEmpty) return true;
                            return r.className.toLowerCase().contains(_filterClass.toLowerCase());
                          }).toList();
                          
                          // Group by Student ID to show only latest attempt
                          final Map<String, ResultModel> latestResultsMap = {};
                          for (var result in filteredByClass) {
                              if (!latestResultsMap.containsKey(result.studentId) || 
                                  result.attemptNumber > latestResultsMap[result.studentId]!.attemptNumber) {
                                  latestResultsMap[result.studentId] = result;
                              }
                          }
                          
                          final filteredResults = latestResultsMap.values.toList();

                          // Sort by submitted time (newest first)
                          filteredResults.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

                          if (filteredResults.isEmpty) {
                             return Container(
                               padding: const EdgeInsets.all(60),
                               alignment: Alignment.center,
                               child: Column(
                                 children: [
                                   Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                                   const SizedBox(height: 16),
                                   Text('No results found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                                 ],
                               ),
                             );
                          }

                          final isMobile = MediaQuery.of(context).size.width < 800;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48), 
                              child: DataTable(
                                showCheckboxColumn: false,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFF2E236C)), 
                                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), // Smaller font
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                                columnSpacing: isMobile ? 16 : 40, // Tight spacing on mobile
                                horizontalMargin: isMobile ? 10 : 30, // Less margin on mobile
                                dividerThickness: 0.5,
                                columns: isMobile 
                                  ? const [
                                      DataColumn(label: Text('Roll No')),
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('Marks')),
                                      DataColumn(label: Text('Info')),
                                    ]
                                  : const [
                                      DataColumn(label: Text('Student Name')),
                                      DataColumn(label: Text('Roll No')),
                                      DataColumn(label: Text('Class')),
                                      DataColumn(label: Text('Score')),
                                      DataColumn(label: Text('Attempts')),
                                      DataColumn(label: Text('Submitted At')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                rows: filteredResults.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final result = entry.value;
                                  final isEven = index % 2 == 0;
                                  
                                  List<DataCell> cells;
                                  
                                  if (isMobile) {
                                    cells = [
                                      DataCell(Text(result.studentRollNumber, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12))),
                                      DataCell(
                                        SizedBox(
                                          width: 80, // Limit width to prevent overflow
                                          child: Text(
                                            result.studentName.isNotEmpty ? result.studentName : 'Unknown', 
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937), fontSize: 12)
                                          ),
                                        )
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE9FE), // Light Purple
                                            borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Text(
                                            '${result.score} / ${result.totalMarks}', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6), fontSize: 11)
                                          ),
                                        )
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
                                          onPressed: () => _showResultDetails(context, result),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      ),
                                    ];
                                  } else {
                                    cells = [
                                      DataCell(
                                        Text(
                                          result.studentName.isNotEmpty ? result.studentName : 'Unknown', 
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))
                                        )
                                      ),
                                      DataCell(Text(result.studentRollNumber, style: const TextStyle(color: Color(0xFF4B5563)))),
                                      DataCell(Text(result.className, style: const TextStyle(color: Color(0xFF4B5563)))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE9FE), // Light Purple
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                          child: Text(
                                            '${result.score} / ${result.totalMarks}', 
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              color: Color(0xFF5B21B6), // Darker Purple
                                              fontSize: 13
                                            )
                                          ),
                                        )
                                      ),
                                      DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: result.attemptNumber > 1 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${result.attemptNumber}', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                color: result.attemptNumber > 1 ? Colors.orange : Colors.green,
                                              )
                                            ),
                                          )
                                      ),
                                      DataCell(Text(
                                        DateFormat('MMM dd, yyyy, hh:mm a').format(result.submittedAt),
                                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)
                                      )),
                                      DataCell(
                                          result.isCancelled 
                                          ? const Text('Cancelled', style: TextStyle(color: Colors.red, fontSize: 12))
                                          : IconButton(
                                              icon: const Icon(Icons.replay_outlined, color: Colors.orange),
                                              tooltip: 'Reset/Allow Re-attempt',
                                              onPressed: () => _confirmCancelResult(context, result),
                                            )
                                      ),
                                    ];
                                  }

                                  return DataRow(
                                    onSelectChanged: (_) {
                                       context.push('/review-quiz', extra: result);
                                    },
                                    color: WidgetStateProperty.resolveWith((states) {
                                      // Alternating row colors
                                      return isEven ? const Color(0xFFF9FAFB) : Colors.white; 
                                    }),
                                    cells: cells,
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                       },
                     ),
                   ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showAnswerKey(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer Key'),
        content: SizedBox(
          width: 500,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.quiz.questions.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final q = widget.quiz.questions[index];
              return ListTile(
                title: Text('Q${index + 1}: ${q.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ...List.generate(q.options.length, (optIndex) {
                      final isCorrect = optIndex == q.correctOptionIndex;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: isCorrect ? BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)) : null,
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.circle_outlined, 
                              size: 16, 
                              color: isCorrect ? Colors.green : Colors.grey
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(q.options[optIndex], style: TextStyle(color: isCorrect ? Colors.green.shade900 : Colors.black87))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
  void _confirmCancelResult(BuildContext context, ResultModel result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow Re-attempt?'),
        content: Text('Are you sure you want to cancel the result for ${result.studentName}? This will allow the student to take the quiz again. The previous score will be marked as cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().cancelResult(result.id);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result cancelled. Student can now re-attempt.')));
                }
              } catch (e) {
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              }
            },
            child: const Text('Yes, Cancel Result'),
          ),
        ],
      ),
    );
  }

  void _showResultDetails(BuildContext context, ResultModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent for custom container
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header: Name & Roll No
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEDE9FE),
                  child: Text(
                    result.studentName.isNotEmpty ? result.studentName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.studentName, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        result.studentRollNumber, 
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                // Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B21B6), 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                       BoxShadow(color: const Color(0xFF5B21B6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    children: [
                      Text('${result.score}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('/ ${result.totalMarks}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Details Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                 color: const Color(0xFFF9FAFB),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.class_outlined, 'Class', result.className),
                  const Divider(height: 24, thickness: 0.5),
                  _buildDetailRow(Icons.history, 'Attempt', '#${result.attemptNumber}'),
                  const Divider(height: 24, thickness: 0.5),
                  _buildDetailRow(Icons.calendar_today, 'Submitted', DateFormat('MMM dd, hh:mm a').format(result.submittedAt)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push('/review-quiz', extra: result);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEDE9FE),
                      foregroundColor: const Color(0xFF5B21B6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.remove_red_eye, size: 20),
                    label: const Text('View Answers'),
                  ),
                ),
                if (!result.isCancelled) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF7ED),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                         context.pop();
                         _confirmCancelResult(context, result);
                      },
                      icon: const Icon(Icons.replay, size: 20),
                      label: const Text('Re-attempt'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ],
          ),
        )
      ],
    );
  }
}
