import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/theme_service.dart';

class FillingHistoryPage extends StatefulWidget {
  const FillingHistoryPage({super.key});

  @override
  State<FillingHistoryPage> createState() => _FillingHistoryPageState();
}

class _FillingHistoryPageState extends State<FillingHistoryPage> {
  static const _perPage = 10;

  List<Map<String, dynamic>> _fillings = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.fillingHistory(
        page: page,
        perPage: _perPage,
      );
      final rows = response['data'];
      if (rows is! List) {
        throw const FormatException('Data riwayat pengisian tidak valid.');
      }
      if (!mounted) return;
      setState(() {
        _fillings = rows.whereType<Map<String, dynamic>>().toList();
        _currentPage = (response['current_page'] as num?)?.toInt() ?? page;
        _lastPage = (response['last_page'] as num?)?.toInt() ?? 1;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  String _dateLabel(dynamic value) {
    if (value is! String) return '-';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  String _number(dynamic value, {String suffix = ''}) =>
      value is num ? '${value.toStringAsFixed(1)}$suffix' : '-';

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;
    final primary = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return RefreshIndicator(
      onRefresh: () => _loadPage(_currentPage),
      child: _isLoading
          ? ListView(
              children: const [
                SizedBox(height: 180),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _error != null
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Text(_error!, textAlign: TextAlign.center),
                Center(
                  child: TextButton(
                    onPressed: () => _loadPage(_currentPage),
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Riwayat Pengisian Tandon',
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menampilkan pengisian terbaru terlebih dahulu.',
                  style: TextStyle(color: secondary),
                ),
                const SizedBox(height: 14),
                if (_fillings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat pengisian.',
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  )
                else
                  for (final filling in _fillings)
                    Card(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dateLabel(filling['started_at']),
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              filling['ended_at'] is String
                                  ? 'Selesai: ${_dateLabel(filling['ended_at'])}'
                                  : 'Sedang berlangsung',
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                            const Divider(height: 18),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _Measurement(
                                  label: 'Level',
                                  value:
                                      '${_number(filling['start_level'])} → '
                                      '${_number(filling['end_level'])}%',
                                ),
                                _Measurement(
                                  label: 'Suhu',
                                  value:
                                      '${_number(filling['start_suhu'])} → '
                                      '${_number(filling['end_suhu'])} °C',
                                ),
                                _Measurement(
                                  label: 'Debit',
                                  value:
                                      '${_number(filling['start_debit'])} → '
                                      '${_number(filling['end_debit'])} L/m',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentPage > 1
                          ? () => _loadPage(_currentPage - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Sebelumnya'),
                    ),
                    Text(
                      'Halaman $_currentPage dari $_lastPage',
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                    OutlinedButton.icon(
                      onPressed: _currentPage < _lastPage
                          ? () => _loadPage(_currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Berikutnya'),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Measurement extends StatelessWidget {
  const _Measurement({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    '$label: $value',
    style: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF334155),
      fontSize: 12,
    ),
  );
}
