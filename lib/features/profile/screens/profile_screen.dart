import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: AppColors.fondoPrincipal,
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.verdePrimario)),
        error: (_, __) => const Center(child: Text('Error')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.fondoCard,
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 32, color: AppColors.verdePrimario),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(user.username,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),
              // Stats
              _StatRow(label: 'Monedas actuales', value: '${user.coins}'),
              _StatRow(label: 'Total ganado (monedas)', value: '${user.totalEarned}'),
              _StatRow(label: 'Total ganado (USD)',
                  value: '\$${(user.totalEarned / 1000).toStringAsFixed(2)}'),
              _StatRow(label: 'Racha actual', value: '${user.streakDays} días 🔥'),
              const SizedBox(height: 24),
              // Cerrar sesión
              OutlinedButton(
                onPressed: () =>
                    ref.read(userNotifierProvider.notifier).signOut(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
