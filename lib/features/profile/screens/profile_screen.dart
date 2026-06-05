import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../shared/widgets/app_error_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ── Editar nombre ─────────────────────────────────────────────────
  Future<void> _editUsername(BuildContext context, WidgetRef ref,
      UserNotifier notifier, String current) async {
    final ctrl = TextEditingController(text: current);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.azulPrimario, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.profileEditNameTitle,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textoPrimario),
          decoration: InputDecoration(
            hintText: context.l10n.profileEditNameHint,
            hintStyle: const TextStyle(color: AppColors.textoDeshabilitado),
            filled: true,
            fillColor: AppColors.fondoPrincipal,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.azulPrimario, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.profileCancel,
                style: const TextStyle(color: AppColors.textoSecundario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulPrimario,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(context.l10n.profileSave,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final newName = ctrl.text.trim();
    if (newName.isEmpty || newName == current) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'username': newName})
          .eq('id', Supabase.instance.client.auth.currentUser!.id);
      ref.invalidate(userProvider);
      ref.invalidate(userNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profileNameUpdated),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profileConnectionError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Dialog de confirmación ────────────────────────────────────────
  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(ctx.l10n.profileDeleteTitle,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
          ],
        ),
        content: Text(
          ctx.l10n.profileDeleteContent,
          style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.profileCancel,
                style: const TextStyle(color: AppColors.azulPrimario)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(ctx.l10n.profileDeleteConfirm,
                style: const TextStyle(fontWeight: FontWeight.w700)),
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
        final msg = (response.data as Map?)?['error'] ?? context.l10n.profileDeleteError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // cerrar spinner
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profileConnectionError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync  = ref.watch(userProvider);
    final notifier   = ref.read(userNotifierProvider.notifier);
    final authUser   = Supabase.instance.client.auth.currentUser;
    final isAnon     = notifier.isAnonymous;
    final email      = authUser?.email;

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        backgroundColor: AppColors.fondoPrincipal,
        foregroundColor: AppColors.textoPrimario,
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.azulPrimario)),
        error: (_, __) => AppErrorWidget(
          onRetry: () => ref.invalidate(userProvider),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return RefreshIndicator(
            color: AppColors.azulPrimario,
            onRefresh: () async {
              ref.invalidate(userProvider);
              ref.invalidate(userNotifierProvider);
              await ref.read(userProvider.future);
            },
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar ──────────────────────────────────────────
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.fondoCard,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 32, color: AppColors.azulPrimario),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _editUsername(context, ref, notifier, user.username),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.username,
                          style: const TextStyle(
                              color: AppColors.textoPrimario,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textoDeshabilitado),
                    ],
                  ),
                ),
              ),
              if (!isAnon && email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(email,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 8),

              // ── ID del usuario (copiable) ────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.profileIdCopied),
                      backgroundColor: AppColors.verdePrimario,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.fondoCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fondoCardBorde),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint_rounded,
                            size: 13, color: AppColors.textoSecundario),
                        const SizedBox(width: 5),
                        Text(
                          'ID: ${user.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                            size: 11, color: AppColors.textoDeshabilitado),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjeta: invitado → vincular cuenta ──────────────
              if (isAnon)
                _LinkAccountCard(notifier: notifier)
              else if (email != null) ...[
                FutureBuilder(
                  future: Supabase.instance.client.auth.getUser(),
                  builder: (context, snap) {
                    final phone = snap.data?.user?.phone ?? '';
                    final phoneVerified = phone.isNotEmpty;
                    return _AccountInfoCard(
                      email: email,
                      phoneVerified: phoneVerified,
                      phone: phone.isNotEmpty ? phone : null,
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),

              // ── Selector de idioma ────────────────────────────────
              const _LanguageCard(),
              const SizedBox(height: 20),

              // ── Stats ────────────────────────────────────────────
              _StatRow(label: context.l10n.profileCurrentCoins, value: user.coins.formatted),
              _StatRow(
                  label: context.l10n.profileTotalEarned,
                  value: '\$${(user.totalEarned / AppConstants.coinsPerDollar).toStringAsFixed(2)}'),
              _StatRow(
                  label: context.l10n.profileCurrentStreak, value: context.l10n.profileStreakDays(user.streakDays)),
              const SizedBox(height: 24),

              // ── Tarjeta de referidos: OCULTA temporalmente ──
              // El sistema de bonos de referido fue removido. La sección queda
              // oculta para no prometer monedas que ya no se pagan. El widget
              // _ReferralCard se mantiene en código por si se reactiva.
              // if (!isAnon) ...[
              //   _ReferralCard(user: user),
              //   const SizedBox(height: 24),
              // ],

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
                child: Text(context.l10n.profileSignOut),
              ),
              const SizedBox(height: 12),

              // ── Eliminar cuenta ──────────────────────────────────
              TextButton(
                onPressed: () => _confirmDeleteAccount(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textoSecundario,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  context.l10n.profileDeleteAccount,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),

              // ── Versión de la app ────────────────────────────────
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  final version = snap.data?.version ?? '—';
                  final build   = snap.data?.buildNumber ?? '';
                  return Center(
                    child: Text(
                      'v$version${build.isNotEmpty ? ' ($build)' : ''}',
                      style: const TextStyle(
                        color: AppColors.textoDeshabilitado,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Banner "Desarrollado por" ────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.fondoElevado,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fondoCardBorde),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.profileMadeByTeam,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ));
        },
      ),
    );
  }
}

// ── Tarjeta de referidos ──────────────────────────────────────────
// ignore: unused_element
class _ReferralCard extends ConsumerWidget {
  final AppUser user;
  const _ReferralCard({required this.user});

  void _share(BuildContext context) {
    Share.share(
      context.l10n.referralShareMessage(user.referralCode),
      subject: context.l10n.referralShareSubject,
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: user.referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.referralCodeCopied),
        backgroundColor: AppColors.verdePrimario,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openRegisterDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => _RegisterReferralDialog(
        onSubmit: (code) async {
          final err = await ref
              .read(userNotifierProvider.notifier)
              .applyReferralCode(code);
          if (err == null) {
            await ref.read(userNotifierProvider.notifier).refreshUser();
          }
          return err;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code     = user.referralCode;
    final count    = user.referralsCount;
    final earnings = user.referralEarnings;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F8A), Color(0xFF1A3FCC), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A3FCC),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.referralInviteFriends,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(context.l10n.referralBothEarn,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                    Text(context.l10n.referralYourCode,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
                tooltip: context.l10n.referralCopy,
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Botón compartir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(context.l10n.referralShare,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0D1F8A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Código de referido ya usado / botón registrar ───
          if (user.referredBy != null) ...[
            // Banner: ya usaste el código
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(children: [
                const Text('🔒', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.referralAlreadyUsed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.referralAlreadyUsedDesc,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Estado del bono
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: user.referralBonusPaid
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.referralBonusPaid
                      ? Colors.white38
                      : Colors.amber.withValues(alpha: 0.6),
                ),
              ),
              child: Row(children: [
                Text(
                  user.referralBonusPaid ? '✅' : '⏳',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.referralBonusPaid
                            ? context.l10n.referralBonusPaid
                            : context.l10n.referralBonusPending,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.referralBonusPaid
                            ? context.l10n.referralBonusPaidDesc
                            : context.l10n.referralBonusPendingDesc,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],

          // ── Botón registrar código (solo si nunca lo usó) ───
          if (user.referredBy == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openRegisterDialog(context, ref),
                icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                label: Text(context.l10n.referralRegisterCode,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                label: context.l10n.referralCount,
                value: '$count',
                icon: Icons.people_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReferralStat(
                label: context.l10n.referralEarnings,
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

// ── Dialog para registrar código de referido ──────────────────────
class _RegisterReferralDialog extends StatefulWidget {
  /// Devuelve null si fue exitoso, o mensaje de error si falló.
  final Future<String?> Function(String code) onSubmit;
  const _RegisterReferralDialog({required this.onSubmit});

  @override
  State<_RegisterReferralDialog> createState() => _RegisterReferralDialogState();
}

class _RegisterReferralDialogState extends State<_RegisterReferralDialog> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    final err = await widget.onSubmit(code);

    if (!mounted) return;

    if (err == null) {
      // Éxito — cerrar y mostrar snackbar en el perfil
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.referralRegistered),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      setState(() { _loading = false; _error = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.referralDialogTitle,
                  style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      title: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded,
                              color: AppColors.dorado, size: 20),
                          const SizedBox(width: 8),
                          Text(context.l10n.referralHowTitle,
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.person_add_rounded,
                            text: context.l10n.referralHowStep1,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.monetization_on_rounded,
                            text: context.l10n.referralHowStep2,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.schedule_rounded,
                            text: context.l10n.referralHowStep3,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.warning_amber_rounded,
                            text: context.l10n.referralHowStep4,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.referralHowGotIt,
                              style: const TextStyle(
                                  color: AppColors.dorado,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.referralDialogSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3FCC), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.referralBothGet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.dorado,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                fontSize: 22,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                hintStyle: const TextStyle(
                    color: AppColors.textoDeshabilitado,
                    letterSpacing: 3,
                    fontSize: 17),
                filled: true,
                fillColor: const Color(0xFFFFFBEB),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.dorado.withValues(alpha: 0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.dorado.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.dorado, width: 2),
                ),
                errorText: _error,
                errorStyle: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Botón aplicar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dorado,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.dorado.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(context.l10n.referralApplyCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),

            // Cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.profileCancel,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 13)),
            ),
          ],
        ),
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

// ── Tarjeta info de cuenta ────────────────────────────────────────
class _AccountInfoCard extends StatelessWidget {
  final String? email;
  final bool    phoneVerified;
  final String? phone;
  const _AccountInfoCard({
    required this.email,
    this.phoneVerified = false,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: phoneVerified
                ? AppColors.verdePrimario.withValues(alpha: 0.3)
                : AppColors.fondoCardBorde),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: phoneVerified
                ? AppColors.verdePrimario.withValues(alpha: 0.12)
                : AppColors.fondoPrincipal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            phoneVerified ? Icons.shield_rounded : Icons.shield_outlined,
            color: phoneVerified
                ? AppColors.verdePrimario
                : AppColors.textoSecundario,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  phoneVerified
                      ? context.l10n.profileVerifiedAccount
                      : context.l10n.profileUnverifiedAccount,
                  style: TextStyle(
                      color: phoneVerified
                          ? AppColors.textoPrimario
                          : AppColors.textoSecundario,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                if (phoneVerified) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.verdePrimario.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('✓ SMS',
                        style: TextStyle(
                            color: AppColors.verdePrimario,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              Text(
                email ?? context.l10n.profileNoEmail,
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              if (phone != null) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.phone_rounded,
                      size: 11, color: AppColors.verdePrimario),
                  const SizedBox(width: 4),
                  Text(phone!,
                      style: const TextStyle(
                          color: AppColors.verdePrimario,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          ),
        ),
        Icon(
          phoneVerified
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: phoneVerified
              ? AppColors.verdePrimario
              : AppColors.textoDeshabilitado,
          size: 18,
        ),
      ]),
    );
  }
}

// ── Tarjeta para vincular cuenta de invitado ──────────────────────
class _LinkAccountCard extends StatefulWidget {
  final UserNotifier notifier;
  const _LinkAccountCard({required this.notifier});

  @override
  State<_LinkAccountCard> createState() => _LinkAccountCardState();
}

class _LinkAccountCardState extends State<_LinkAccountCard> {
  bool _loading = false;
  bool _expanded = false;

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? AppColors.colorVideos : AppColors.verdePrimario,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _linkGoogle() async {
    setState(() => _loading = true);
    try {
      await widget.notifier.linkWithGoogle();
      if (mounted) _snack(context.l10n.profileLinkedGoogle);
    } catch (e) {
      if (mounted) _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _linkApple() async {
    setState(() => _loading = true);
    try {
      await widget.notifier.linkWithApple();
      if (mounted) _snack(context.l10n.profileLinkedApple);
    } catch (e) {
      if (mounted) _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _linkEmail() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailLinkSheet(
        onLink: (email, password) async {
          Navigator.of(context).pop();
          setState(() => _loading = true);
          try {
            await widget.notifier.linkWithEmail(
                email: email, password: password);
            if (mounted) _snack(context.l10n.profileLinkedEmail);
          } catch (e) {
            if (mounted) _snack('Error: $e', error: true);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header (siempre visible) ──────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.profileGuestTitle,
                          style: const TextStyle(
                              color: AppColors.textoPrimario,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(context.l10n.profileGuestSubtitle,
                          style: const TextStyle(
                              color: AppColors.textoSecundario, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textoSecundario,
                ),
              ]),
            ),
          ),

          // ── Botones (expandibles) ─────────────────────────────────
          if (_expanded) ...[
            const Divider(
                height: 1, color: AppColors.fondoCardBorde, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(
                            color: AppColors.azulPrimario, strokeWidth: 2.5),
                      ),
                    )
                  : Column(children: [
                      // Google
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _linkGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulPrimario,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4)),
                                child: const Center(
                                  child: Text('G',
                                      style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(context.l10n.profileLinkGoogle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Apple (solo iOS)
                      if (Platform.isIOS) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _linkApple,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.apple, size: 20),
                                const SizedBox(width: 10),
                                Text(context.l10n.profileLinkApple,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Email
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _linkEmail,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textoPrimario,
                            side: const BorderSide(
                                color: AppColors.fondoCardBorde, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email_outlined, size: 18),
                              const SizedBox(width: 10),
                              Text(context.l10n.profileLinkEmail,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.profileCoinsPreserved,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textoDeshabilitado, fontSize: 11),
                      ),
                    ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet para vincular con correo ─────────────────────────
class _EmailLinkSheet extends StatefulWidget {
  final Future<void> Function(String email, String password) onLink;
  const _EmailLinkSheet({required this.onLink});

  @override
  State<_EmailLinkSheet> createState() => _EmailLinkSheetState();
}

class _EmailLinkSheetState extends State<_EmailLinkSheet> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.profilePasswordMismatch),
        backgroundColor: AppColors.colorVideos,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.profilePasswordTooShort),
        backgroundColor: AppColors.colorVideos,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    await widget.onLink(email, pass);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.fondoCardBorde,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(context.l10n.profileLinkEmailTitle,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(context.l10n.profileLinkEmailSubtitle,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          const SizedBox(height: 18),

          _Field(controller: _emailCtrl, label: context.l10n.emailDialogEmail,
              icon: Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 10),

          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
            decoration: InputDecoration(
              labelText: context.l10n.emailDialogPassword,
              labelStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textoSecundario, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textoSecundario, size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true, fillColor: AppColors.fondoPrincipal,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.azulPrimario, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),

          _Field(controller: _pass2Ctrl, label: context.l10n.profileConfirmPassword,
              icon: Icons.lock_outline_rounded,
              type: TextInputType.visiblePassword, obscure: true),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(context.l10n.profileLinkSave,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  const _Field({
    required this.controller, required this.label,
    required this.icon, required this.type, this.obscure = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textoSecundario, size: 18),
          filled: true, fillColor: AppColors.fondoPrincipal,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.azulPrimario, width: 1.5)),
        ),
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

// ── Fila de info con ícono ─────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.dorado),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Selector de idioma ────────────────────────────────────────────
class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l = context.l10n;

    // Etiqueta de la opción activa
    String activeLabel;
    if (currentLocale == null) {
      activeLabel = l.profileLanguageAuto;
    } else if (currentLocale.languageCode == 'es') {
      activeLabel = l.profileLanguageEs;
    } else if (currentLocale.languageCode == 'pt') {
      activeLabel = l.profileLanguagePt;
    } else {
      activeLabel = l.profileLanguageEn;
    }

    return GestureDetector(
      onTap: () => _showPicker(context, ref, currentLocale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fondoCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fondoCardBorde),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.azulPrimario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded,
                  color: AppColors.azulPrimario, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.profileLanguageTitle,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(activeLabel,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textoDeshabilitado, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref, Locale? current) {
    final l = context.l10n;
    final notifier = ref.read(localeProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fondoCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.fondoCardBorde,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(l.profileLanguageDialogTitle,
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 8),
              // Español
              _LangOption(
                label: l.profileLanguageEs,
                selected: current?.languageCode == 'es',
                onTap: () {
                  notifier.setLocale(const Locale('es'));
                  Navigator.pop(ctx);
                },
              ),
              // English
              _LangOption(
                label: l.profileLanguageEn,
                selected: current?.languageCode == 'en',
                onTap: () {
                  notifier.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              // Português
              _LangOption(
                label: l.profileLanguagePt,
                selected: current?.languageCode == 'pt',
                onTap: () {
                  notifier.setLocale(const Locale('pt'));
                  Navigator.pop(ctx);
                },
              ),
              // Automático
              _LangOption(
                label: l.profileLanguageAuto,
                selected: current == null,
                onTap: () {
                  notifier.clearLocale();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? AppColors.azulPrimario : AppColors.textoDeshabilitado,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.azulPrimario : AppColors.textoPrimario,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.azulPrimario, size: 20)
          : null,
    );
  }
}
