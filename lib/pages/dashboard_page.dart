import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'account_settings_page.dart';
import 'students_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  CollectionReference<Map<String, dynamic>> _students(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduSync'),
        actions: [
          IconButton(
            tooltip: 'Account settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountSettingsPage(),
              ),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hello, ${user.displayName?.trim().isNotEmpty == true ? user.displayName : user.email ?? 'there'}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage student information in one place.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _students(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _CountCard(
                  label: 'Total students',
                  value: '—',
                  error: 'Could not load student count: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const _CountCard(label: 'Total students', value: '…');
              }
              return _CountCard(
                label: 'Total students',
                value: '${snapshot.data!.docs.length}',
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
              title: const Text('Student records'),
              subtitle: const Text('Add, search, update, and remove records.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StudentsPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(
                child: Icon(Icons.manage_accounts_outlined),
              ),
              title: const Text('Account settings'),
              subtitle: Text(user.email ?? 'Manage your signed-in account.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountSettingsPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value, this.error});

  final String label;
  final String value;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (error != null)
                    Text(error!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
