import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/app_snackbar.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key, this.documentId, this.initialData});

  final String? documentId;
  final Map<String, dynamic>? initialData;

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _nameController;
  late final TextEditingController _courseController;
  late final TextEditingController _yearController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  String? _studentNumberError;

  bool get _isEditing => widget.documentId != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _numberController = TextEditingController(
      text: data['studentNumber'] as String? ?? '',
    );
    _nameController = TextEditingController(
      text: data['fullName'] as String? ?? '',
    );
    _courseController = TextEditingController(
      text: data['course'] as String? ?? '',
    );
    _yearController = TextEditingController(
      text: data['yearLevel'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: data['email'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final collection = userReference.collection('students');
      final numberIndexes = userReference.collection('studentNumberIndexes');
      final studentNumber = _numberController.text.trim();
      final numberKey = _normalizedStudentNumber(studentNumber);
      final numberIndexId = _studentNumberIndexId(numberKey);
      final previousNumber =
          widget.initialData?['studentNumber'] as String? ?? '';
      final previousNumberKey = _normalizedStudentNumber(previousNumber);
      final numberIndexReference = numberIndexes.doc(numberIndexId);
      final studentReference = _isEditing
          ? collection.doc(widget.documentId)
          : collection.doc();

      final existingStudents = await collection.get();
      final hasDuplicate = existingStudents.docs.any((document) {
        if (document.id == widget.documentId) return false;
        final existingNumber = document.data()['studentNumber'];
        return _normalizedStudentNumber('$existingNumber') == numberKey;
      });
      if (hasDuplicate) {
        _markDuplicateStudentNumber();
        return;
      }

      final data = <String, dynamic>{
        'studentNumber': studentNumber,
        'fullName': _nameController.text.trim(),
        'course': _courseController.text.trim(),
        'yearLevel': _yearController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final numberIndex = await transaction.get(numberIndexReference);
        final indexedStudentId = numberIndex.data()?['studentDocumentId'];
        if (numberIndex.exists && indexedStudentId != studentReference.id) {
          throw const _DuplicateStudentNumberException();
        }

        if (_isEditing &&
            previousNumberKey.isNotEmpty &&
            previousNumberKey != numberKey) {
          final previousNumberIndexReference = numberIndexes.doc(
            _studentNumberIndexId(previousNumberKey),
          );
          final previousNumberIndex = await transaction.get(
            previousNumberIndexReference,
          );
          if (previousNumberIndex.data()?['studentDocumentId'] ==
              studentReference.id) {
            transaction.delete(previousNumberIndexReference);
          }
        }

        if (_isEditing) {
          transaction.update(studentReference, data);
        } else {
          transaction.set(studentReference, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(numberIndexReference, {
          'studentDocumentId': studentReference.id,
        });
      });
      if (mounted) Navigator.of(context).pop();
    } on _DuplicateStudentNumberException {
      _markDuplicateStudentNumber();
    } on FirebaseException catch (error) {
      _showMessage('Could not save student: ${error.message ?? error.code}');
    } catch (error) {
      _showMessage('Could not save student: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
  }

  void _markDuplicateStudentNumber() {
    if (!mounted) return;
    setState(
      () => _studentNumberError = 'This student number is already in use.',
    );
    _showMessage('A student with this number already exists.');
  }

  String _normalizedStudentNumber(String value) => value.trim().toLowerCase();

  String _studentNumberIndexId(String normalizedNumber) {
    return base64Url.encode(utf8.encode(normalizedNumber)).replaceAll('=', '');
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.sentences,
    String? errorText,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
        ),
        validator: validator ?? (value) => _validateRequired(value, label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit student' : 'Add student')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Student information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the student details below. All fields are required.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _field(
                controller: _numberController,
                label: 'Student number',
                icon: Icons.badge_outlined,
                capitalization: TextCapitalization.characters,
                maxLength: 64,
                errorText: _studentNumberError,
                onChanged: (_) {
                  if (_studentNumberError != null) {
                    setState(() => _studentNumberError = null);
                  }
                },
                validator: (value) {
                  final required = _validateRequired(value, 'Student number');
                  if (required != null) return required;
                  if (value!.trim().length > 64) {
                    return 'Student number must be 64 characters or fewer.';
                  }
                  return null;
                },
              ),
              _field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
              ),
              _field(
                controller: _courseController,
                label: 'Course',
                icon: Icons.menu_book_outlined,
              ),
              _field(
                controller: _yearController,
                label: 'Year level',
                icon: Icons.calendar_today_outlined,
              ),
              _field(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                capitalization: TextCapitalization.none,
                validator: (value) {
                  final required = _validateRequired(value, 'Email');
                  if (required != null) return required;
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value!.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save student'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuplicateStudentNumberException implements Exception {
  const _DuplicateStudentNumberException();
}
