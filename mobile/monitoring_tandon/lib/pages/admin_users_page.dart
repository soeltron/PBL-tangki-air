import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.adminUsers();
      final rows = response['data'];
      if (rows is! List) {
        throw const FormatException('Data pengguna tidak valid.');
      }
      if (!mounted) return;
      setState(() {
        _users = rows.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _createUser() async {
    final username = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah pengguna'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value == null || value.trim().length < 3
                      ? 'Username minimal 3 karakter.'
                      : null,
                ),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Masukkan email yang valid.'
                      : null,
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Password minimal 6 karakter.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Daftarkan'),
          ),
        ],
      ),
    );

    try {
      if (accepted == true) {
        await ApiService.createUser(
          username: username.text.trim(),
          email: email.text.trim(),
          password: password.text,
        );
        if (mounted) _showMessage('Pengguna berhasil ditambahkan.');
        await _loadUsers();
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      username.dispose();
      email.dispose();
      password.dispose();
    }
  }

  String _lastLoginLabel(dynamic timestamp) {
    if (timestamp is! String || timestamp.isEmpty) return 'Belum pernah login';
    final date = DateTime.tryParse(timestamp)?.toLocal();
    if (date == null) return 'Waktu login tidak tersedia';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Login terakhir: $day/$month/$year $hour:$minute';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola User')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah pengguna'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(child: Text(_error!)),
                  Center(
                    child: TextButton(
                      onPressed: _loadUsers,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
              )
            : _users.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Belum ada pengguna.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          '${user['name'] ?? '?'}'.characters.first
                              .toUpperCase(),
                        ),
                      ),
                      title: Text('${user['name'] ?? ''}'),
                      subtitle: Text(
                        '${user['email'] ?? ''}\n'
                        '${user['role'] == 'admin' ? 'Admin' : 'Pengguna'} · '
                        '${_lastLoginLabel(user['last_login_at'])}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
