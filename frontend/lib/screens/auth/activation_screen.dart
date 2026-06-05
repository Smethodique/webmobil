import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _codeCtrl.text.trim().toUpperCase().replaceAll(' ', '');
    if (code.isEmpty) return;

    setState(() => _loading = true);
    final err = await ref.read(authProvider.notifier).activate(code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.vpn_key, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Activation du compte',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez le code d\'activation reçu\npar le support pour commencer',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: 'Code d\'activation',
                  hintText: 'XXXX-XXXX-XXXX',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _activate,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Activer'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
