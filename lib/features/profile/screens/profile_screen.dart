import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ── Dialog de confirmación ────────────────────────────────────────
  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Eliminar cuenta',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
          ],
        ),
        content: const Text(
          'Esta acción es irreversible.\n\n'
          'Se eliminarán tu perfil, historial y saldo de monedas. '
          'Las solicitudes de cobro pendientes se conservan 90 días '
          'por obligación legal.\n\n'
          '¿Estás seguro de que quieres continuar?',
          style: TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.azulPrimario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, eliminar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context, ref);
    }
  }

  // ── Llamada al API de Vercel para eliminar la cuenta ─────────────
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.azulPrimario),
      ),
    );

    try {
      final dio = Dio();
      final response = await dio.delete(
        '${AppConstants.apiBaseUrl}/api/account/delete',
        options: Options(
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
          validateStatus: (_) => true,
        ),
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // cerrar spinner

      if (response.statusCode == 200) {
        await Supabase.instance.client.auth.signOut();
      } else {
        final msg = (response.data as Map?)?['error'] ?? 'Error al eliminar la cuenta';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // cerrar spinner
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión. Intenta de nuevo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: AppColors.fondoPrincipal,
        foregroundColor: AppColors.textoPrimario,
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.azulPrimario)),
        error: (_, __) => const Center(child: Text('Error')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar ──────────────────────────────────────────
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.fondoCard,
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 32, color: AppColors.azulPrimario),
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

              // ── Stats ────────────────────────────────────────────
              _StatRow(label: 'Monedas actuales', value: '${user.coins}'),
              _StatRow(
                  label: 'Total ganado (USD)',
                  value: '\$${(user.totalEarned / 1000).toStringAsFixed(2)}'),
              _StatRow(
                  label: 'Racha actual', value: '${user.streakDays} días'),
              const SizedBox(height: 24),

              // ── Tarjeta de referidos ─────────────────────────────
              _ReferralCard(user: user),
              const SizedBox(height: 24),

              // ── Cerrar sesión ────────────────────────────────────
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
              const SizedBox(height: 12),

              // ── Eliminar cuenta ──────────────────────────────────
              TextButton(
                onPressed: () => _confirmDeleteAccount(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textoSecundario,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Eliminar mi cuenta',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ── Tarjeta de referidos ──────────────────────────────────────────
class _ReferralCard extends StatelessWidget {
  final dynamic user;
  const _ReferralCard({required this.user});

  void _share() {
    final code = user.referralCode as String;
    Share.share(
      '¡Únete a JUEGALO y gana dinero real jugando, completando encuestas y viendo videos! 🎮💰\n\n'
      'Usa mi código al registrarte y los dos ganamos 1,000 monedas cuando hagas tu primer cobro.\n\n'
      '📱 Código: $code\n\n'
      'Descarga la app: juegalo.app',
      subject: 'Gana dinero con JUEGALO',
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: user.referralCode as String));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        backgroundColor: AppColors.verdePrimario,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = user.referralCode as String;
    final count = user.referralsCount as int;
    final earnings = user.referralEarnings as int;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA8893C), Color(0xFFC9A84C), Color(0xFFD4B96A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.dorado.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_alt_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invita amigos',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text('Ganan 1,000 monedas los dos',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Código
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tu código',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      code.isNotEmpty ? code : '--------',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded,
                    color: Colors.white70, size: 20),
                tooltip: 'Copiar',
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Botón compartir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Compartir código',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.doradoOscuro,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Stats
          Row(children: [
            Expanded(
              child: _ReferralStat(
                label: 'Referidos',
                value: '$count',
                icon: Icons.people_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReferralStat(
                label: 'Monedas ganadas',
                value: '$earnings',
                icon: Icons.monetization_on_outlined,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ReferralStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReferralStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
        ]),
      );
}

// ── Stat row ──────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
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
