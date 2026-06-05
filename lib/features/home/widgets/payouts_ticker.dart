import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';

/// Banner tipo "teletipo" que muestra cobros recientes de otros usuarios.
/// Aumenta la confianza social — si otros cobran, el usuario también lo hará.
class PayoutsTicker extends StatefulWidget {
  const PayoutsTicker({super.key});

  @override
  State<PayoutsTicker> createState() => _PayoutsTickerState();
}

class _PayoutsTickerState extends State<PayoutsTicker> {
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _scrollTimer;
  Timer? _refreshTimer;
  List<_Payout> _payouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Refrescar cada 2 minutos
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) => _fetch());
    // Auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  Future<void> _fetch() async {
    try {
      final res = await Dio().get(
        '${AppConstants.apiBaseUrl}/api/payouts/recent',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final list = (res.data['payouts'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _payouts = list.map((j) => _Payout.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_scrollCtrl.hasClients || _payouts.isEmpty) return;
      final maxExtent = _scrollCtrl.position.maxScrollExtent;
      final current = _scrollCtrl.offset;
      // Si llega al final, regresa al inicio
      if (current >= maxExtent) {
        _scrollCtrl.jumpTo(0);
      } else {
        _scrollCtrl.jumpTo(current + 0.5);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _refreshTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _payouts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Duplicamos la lista para crear efecto de loop infinito
    final items = [..._payouts, ..._payouts];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.verdePrimario.withValues(alpha: 0.15),
            AppColors.azulPrimario.withValues(alpha: 0.10),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.fondoCardBorde.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Etiqueta "EN VIVO"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'EN VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Ticker scrolling
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (_, i) => _PayoutChip(payout: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutChip extends StatelessWidget {
  final _Payout payout;
  const _PayoutChip({required this.payout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.verdePrimario, size: 13),
          const SizedBox(width: 4),
          Text(
            '\$${payout.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.verdePrimario,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'a ${payout.name}',
            style: const TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              color: AppColors.textoSecundario.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Payout {
  final String name;
  final String country;
  final double amount;
  final String at;

  const _Payout({
    required this.name,
    required this.country,
    required this.amount,
    required this.at,
  });

  factory _Payout.fromJson(Map<String, dynamic> j) => _Payout(
        name:    (j['name'] as String?) ?? 'Jugador',
        country: (j['country'] as String?) ?? 'MX',
        amount:  ((j['amount'] as num?) ?? 0).toDouble(),
        at:      (j['at'] as String?) ?? '',
      );
}
