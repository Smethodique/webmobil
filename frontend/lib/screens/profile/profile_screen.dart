import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_code_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: isAdmin
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark])
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  (auth.username ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              auth.username ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Text(
                    'Étudiant',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 40),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.person, color: AppColors.primary),
                title: const Text("Nom d'utilisateur",
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(auth.username ?? '',
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: AppColors.primary),
                  title: const Text('Panneau d\'administration',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Générer des codes d\'activation',
                      style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AdminCodeScreen()),
                    );
                  },
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
