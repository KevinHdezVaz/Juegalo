import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';

class BalanceCard extends ConsumerWidget {
  final AppUser user;
  const BalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B1A), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.verdePrimario.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu saldo',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${user.balanceUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5, left: 6),
                      child: Text('USD',
                          style: TextStyle(
                              color: AppColors.textoSecundario, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.coins} monedas',
                  style: const TextStyle(
                      color: AppColors.verdePrimario,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Botón cobrar
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.cashout),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdePrimario,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cobrar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
