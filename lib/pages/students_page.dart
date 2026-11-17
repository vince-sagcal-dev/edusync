import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'student_form_page.dart';
import '../widgets/app_snackbar.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final name = document.data()['fullName'] as String? ?? 'this student';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Delete $name? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final studentNumber = document.data()['studentNumber'] as String? ?? '';
      final index = studentNumber.trim().isEmpty
          ? null
          : userReference
                .collection('studentNumberIndexes')
                .doc(_studentNumberIndexId(studentNumber));
      final student = _collection.doc(document.id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (index != null) {
          final indexSnapshot = await transaction.get(index);
          if (indexSnapshot.data()?['studentDocumentId'] == document.id) {
            transaction.delete(index);
          }
        }
        transaction.delete(student);
      });
    } on FirebaseException catch (error) {
      _showMessage('Delete failed: ${error.message ?? error.code}');
    } catch (error) {
      _showMessage('Delete failed: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
  }

  String _studentNumberIndexId(String studentNumber) {
    final normalizedNumber = studentNumber.trim().toLowerCase();
    return base64Url.encode(utf8.encode(normalizedNumber)).replaceAll('=', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const StudentFormPage()),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search name, number, course, or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _collection.orderBy('fullName').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load records.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _query.toLowerCase();
                final documents = snapshot.data!.docs.where((document) {
                  if (query.isEmpty) return true;
                  final data = document.data();
                  return [
                    data['fullName'],
                    data['studentNumber'],
                    data['course'],
                    data['yearLevel'],
                    data['email'],
                  ].any((value) => '$value'.toLowerCase().contains(query));
                }).toList();
                if (documents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        query.isEmpty
                            ? 'No student records yet.\nTap Add student to get started.'
                            : 'No records match "$_query".',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  itemCount: documents.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final data = document.data();
                    final name = data['fullName'] as String? ?? '';
                    final trimmedName = name.trim();
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 4,
                          top: 8,
                          bottom: 8,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            trimmedName.isEmpty
                                ? '?'
                                : trimmedName.characters.first.toUpperCase(),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          '${data['studentNumber'] ?? ''} • '
                          '${data['course'] ?? ''} • '
                          '${data['yearLevel'] ?? ''}\n'
                          '${data['email'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Student actions',
                          onSelected: (action) {
                            if (action == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StudentFormPage(
                                    documentId: document.id,
                                    initialData: data,
                                  ),
                                ),
                              );
                            } else if (action == 'delete') {
                              _deleteStudent(document);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
