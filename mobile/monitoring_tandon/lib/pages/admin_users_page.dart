import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _authService = AuthService();
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
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

    if (accepted == true) {
      try {
        await ApiService.createUser(
          username: username.text.trim(),
          email: email.text.trim(),
          password: password.text,
        );
        if (mounted) _showMessage('Pengguna berhasil ditambahkan.');
        await _loadUsers();
      } catch (error) {
        if (mounted) _showMessage(error.toString());
      }
    }
    username.dispose();
    email.dispose();
    password.dispose();
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final username = TextEditingController(text: '${user['name'] ?? ''}');
    final email = TextEditingController(text: '${user['email'] ?? ''}');
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var hasUserApproval = false;
    var approvalError = false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Ubah akun ${user['name']}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: username,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
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
                    decoration: const InputDecoration(
                      labelText: 'Password baru (opsional)',
                    ),
                    validator: (value) =>
                        value != null && value.isNotEmpty && value.length < 6
                        ? 'Password minimal 6 karakter.'
                        : null,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hasUserApproval,
                    onChanged: (value) => setDialogState(() {
                      hasUserApproval = value ?? false;
                      approvalError = false;
                    }),
                    title: const Text(
                      'Saya sudah mendapat izin pengguna untuk perubahan ini.',
                      style: TextStyle(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (approvalError)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Konfirmasi izin pengguna wajib diisi.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
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
                if (!formKey.currentState!.validate()) return;
                if (!hasUserApproval) {
                  setDialogState(() => approvalError = true);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (accepted == true) {
      final data = <String, dynamic>{
        'username': username.text.trim(),
        'email': email.text.trim(),
        'user_approved': true,
        if (password.text.isNotEmpty) 'password': password.text,
      };
      try {
        final updated = await ApiService.updateUser(user['id'] as int, data);
        if (user['id'] == _authService.userId && updated['name'] is String) {
          await _authService.updateUsername(updated['name'] as String);
        }
        if (mounted) _showMessage('Akun berhasil diperbarui.');
        await _loadUsers();
      } catch (error) {
        if (mounted) _showMessage(error.toString());
      }
    }
    username.dispose();
    email.dispose();
    password.dispose();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengguna?'),
        content: Text('Akun ${user['name']} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    try {
      await ApiService.deleteUser(user['id'] as int);
      if (mounted) _showMessage('Pengguna berhasil dihapus.');
      await _loadUsers();
    } catch (error) {
      if (mounted) _showMessage(error.toString());
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
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
                  final id = user['id'] as int;
                  final isCurrentUser = id == _authService.userId;
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
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') _editUser(user);
                          if (action == 'delete') _deleteUser(user);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Ubah akun'),
                          ),
                          if (!isCurrentUser)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus akun'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}
