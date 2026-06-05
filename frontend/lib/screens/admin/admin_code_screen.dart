import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

class AdminCodeScreen extends ConsumerStatefulWidget {
  const AdminCodeScreen({super.key});

  @override
  ConsumerState<AdminCodeScreen> createState() => _AdminCodeScreenState();
}

class _AdminCodeScreenState extends ConsumerState<AdminCodeScreen> {
  List<Map<String, dynamic>> _codes = [];
  bool _loading = false;
  int _count = 1;

  Future<void> _generate() async {
    setState(() => _loading = true);
    final codes = await AuthService.generateCodes(_count);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (codes != null) {
        _codes = [...codes, ..._codes];
      }
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes d\'activation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nombre de codes',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: _count.toString()),
                            onChanged: (v) {
                              _count = int.tryParse(v) ?? 1;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _generate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(_loading ? '...' : 'Générer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_codes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${_codes.length} code(s) généré(s)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _codes.clear()),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Effacer'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _codes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.vpn_key_outlined,
                              size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Aucun code généré',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Cliquez sur "Générer" pour créer des codes',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _codes.length,
                      itemBuilder: (ctx, i) {
                        final code = _codes[i];
                        final codeStr = code['code'] ?? '';
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.vpn_key,
                                color: AppColors.primary),
                            title: Text(
                              codeStr,
                              style: const TextStyle(
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Créé à ${code['created_at']?.toString().substring(11, 19) ?? ''}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy,
                                  color: AppColors.textSecondary),
                              onPressed: () => _copyCode(codeStr),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
