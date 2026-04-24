import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Ícono
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colorJuegos.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sports_esports_rounded,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 28),

          // Título
          const Text(
            'Ofertas y Juegos',
            style: TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Badge próximamente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.colorJuegos.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.colorJuegos.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '🚀 Próximamente',
              style: TextStyle(
                color: AppColors.colorJuegos,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Instala juegos y apps para ganar\nmonedas extra sin ver anuncios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // Cards de lo que viene
          _ComingSoonCard(
            icon: Icons.videogame_asset_rounded,
            title: 'Instala juegos',
            description: 'Gana monedas por instalar y jugar nuevos juegos.',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          _ComingSoonCard(
            icon: Icons.download_rounded,
            title: 'Descarga apps',
            description: 'Completa tareas en apps y recibe monedas al instante.',
            color: const Color(0xFF5B21B6),
          ),
          const SizedBox(height: 12),
          _ComingSoonCard(
            icon: Icons.star_rounded,
            title: 'Completa misiones',
            description: 'Llega a un nivel específico en un juego y gana mucho más.',
            color: const Color(0xFF4C1D95),
          ),
          const SizedBox(height: 40),

          // Aviso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: const Row(children: [
              Icon(Icons.notifications_outlined,
                  color: AppColors.azulPrimario, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Te avisaremos cuando esta sección esté disponible.',
                  style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 3),
              Text(description,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded,
            color: AppColors.textoDeshabilitado, size: 18),
      ]),
    );
  }
}
