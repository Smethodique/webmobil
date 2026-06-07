import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import 'dart:html' as html;

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  static const _whatsappNumber = '+212771281276';
  static const _whatsappMessage =
      'Bonjour, je souhaite m\'abonner à FMP Prep AI — '
      'la plateforme de préparation au concours avec IA et profs experts. '
      'Pouvez-vous m\'activer ?';
  static const _whatsappGreen = Color(0xFF075E54);

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

  Future<void> _openWhatsApp() async {
    final encoded = Uri.encodeComponent(_whatsappMessage);
    final url = 'https://wa.me/$_whatsappNumber?text=$encoded';

    if (kIsWeb) {
      // Web: use dart:html window.open() — reliable, no popup blocking
      html.window.open(url, '_blank');
      return;
    }

    // Mobile: use url_launcher
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        _showError();
      }
    } catch (_) {
      if (mounted) _showError();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Impossible d\'ouvrir WhatsApp. '
            'Contactez-nous au $_whatsappNumber'),
        backgroundColor: AppColors.error,
      ),
    );
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
              const SizedBox(height: 12),
              const Text(
                "Votre compte n'est pas encore activé.\n"
                'Abonnez-vous via WhatsApp pour recevoir\n'
                'votre code d\'activation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── WhatsApp Subscribe ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    "S'abonner via WhatsApp",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _whatsappGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '300 DH — Discussion & activation via WhatsApp',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 28),

              // ── Divider ──
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.surfaceBorder),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Déjà abonné ?',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.surfaceBorder),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Activation Code Input ──
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: "Code d'activation",
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
