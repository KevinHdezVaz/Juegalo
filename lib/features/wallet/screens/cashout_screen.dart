import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Métodos de pago ───────────────────────────────────────────────
enum PaymentMethod { paypal, mercadopago, oxxo, giftcard }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.paypal      => 'PayPal',
    PaymentMethod.mercadopago => 'MercadoPago',
    PaymentMethod.oxxo        => 'OXXO Pay',
    PaymentMethod.giftcard    => 'Gift Card',
  };
  String get hint => switch (this) {
    PaymentMethod.paypal      => 'correo@ejemplo.com',
    PaymentMethod.mercadopago => 'correo o teléfono',
    PaymentMethod.oxxo        => '10 dígitos (55 1234 5678)',
    PaymentMethod.giftcard    => 'Amazon, Steam, Google Play…',
  };
  IconData get icon => switch (this) {
    PaymentMethod.paypal      => Icons.paypal_rounded,
    PaymentMethod.mercadopago => Icons.account_balance_rounded,
    PaymentMethod.oxxo        => Icons.store_rounded,
    PaymentMethod.giftcard    => Icons.card_giftcard_rounded,
  };
  Color get color => switch (this) {
    PaymentMethod.paypal      => const Color(0xFF003087),
    PaymentMethod.mercadopago => const Color(0xFF009EE3),
    PaymentMethod.oxxo        => const Color(0xFFE2001A),
    PaymentMethod.giftcard    => AppColors.dorado,
  };
  TextInputType get keyboardType => switch (this) {
    PaymentMethod.oxxo => TextInputType.phone,
    _                  => TextInputType.emailAddress,
  };
}

// ── Pantalla ──────────────────────────────────────────────────────
class CashoutScreen extends ConsumerStatefulWidget {
  const CashoutScreen({super.key});

  @override
  ConsumerState<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends ConsumerState<CashoutScreen> {
  PaymentMethod _method = PaymentMethod.paypal;
  final _detailCtrl = TextEditingController();
  double _amount     = 1.0;
  bool _loading      = false;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(int availableCoins) async {
    final detail = _detailCtrl.text.trim();
    if (detail.isEmpty) {
      _snack('Ingresa los datos de tu cuenta', error: true);
      return;
    }

    final coinsToSpend = (_amount * AppConstants.coinsPerDollar).round();
    if (coinsToSpend > availableCoins) {
      _snack('Saldo insuficiente', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('No autenticado');

      await Supabase.instance.client.rpc('request_cashout', params: {
        'p_user_id'       : uid,
        'p_amount_usd'    : _amount,
        'p_coins'         : coinsToSpend,
        'p_method'        : _method.name,
        'p_payment_detail': detail,
      });

      if (mounted) {
        _snack('¡Solicitud enviada! Procesamos en 1-3 días hábiles');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? AppColors.colorVideos : AppColors.verdePrimario,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Solicitar cobro'),
        backgroundColor: AppColors.fondoPrincipal,
        foregroundColor: AppColors.textoPrimario,
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.azulPrimario)),
        error: (_, __) => const Center(
            child: Text('Error', style: TextStyle(color: AppColors.textoSecundario))),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          final maxUsd   = user.coins / AppConstants.coinsPerDollar;
          final maxSlider = maxUsd.clamp(1.0, 100.0);
          if (_amount > maxSlider) _amount = maxSlider;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Saldo disponible ───────────────────────────────
                _BalanceChip(coins: user.coins, usd: maxUsd),
                const SizedBox(height: 24),

                // ── Monto ──────────────────────────────────────────
                const _SectionTitle('Monto a cobrar'),
                const SizedBox(height: 8),
                _AmountSelector(
                  amount: _amount,
                  max: maxSlider,
                  onChanged: (v) => setState(() => _amount = v),
                ),
                const SizedBox(height: 24),

                // ── Método de pago ─────────────────────────────────
                const _SectionTitle('Método de cobro'),
                const SizedBox(height: 10),
                ...PaymentMethod.values.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MethodCard(
                    method: m,
                    selected: _method == m,
                    onTap: () => setState(() {
                      _method = m;
                      _detailCtrl.clear();
                    }),
                  ),
                )),
                const SizedBox(height: 16),

                // ── Datos de cuenta ────────────────────────────────
                const _SectionTitle('Datos de tu cuenta'),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailCtrl,
                  keyboardType: _method.keyboardType,
                  inputFormatters: _method == PaymentMethod.oxxo
                      ? [FilteringTextInputFormatter.digitsOnly,
                         LengthLimitingTextInputFormatter(10)]
                      : null,
                  style: const TextStyle(color: AppColors.textoPrimario),
                  decoration: InputDecoration(
                    hintText: _method.hint,
                    hintStyle: const TextStyle(color: AppColors.textoDeshabilitado),
                    prefixIcon: Icon(_method.icon, color: _method.color, size: 20),
                    filled: true,
                    fillColor: AppColors.fondoElevado,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.fondoCardBorde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.fondoCardBorde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _method.color),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Resumen ────────────────────────────────────────
                _SummaryBox(
                  amount: _amount,
                  coins: (_amount * AppConstants.coinsPerDollar).round(),
                  method: _method.label,
                ),
                const SizedBox(height: 20),

                // ── Botón ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _submit(user.coins),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            'Confirmar cobro de \$${_amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Procesamos tu pago en 1–3 días hábiles',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

class _BalanceChip extends StatelessWidget {
  final int coins;
  final double usd;
  const _BalanceChip({required this.coins, required this.usd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulPrimario.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white, size: 28),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\$${usd.toStringAsFixed(2)} USD disponibles',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text('$coins monedas',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textoPrimario,
            fontWeight: FontWeight.w700,
            fontSize: 15),
      );
}

class _AmountSelector extends StatelessWidget {
  final double amount;
  final double max;
  final ValueChanged<double> onChanged;
  const _AmountSelector(
      {required this.amount, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(children: [
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
              color: AppColors.azulPrimario,
              fontSize: 36,
              fontWeight: FontWeight.w900),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.azulPrimario,
            thumbColor: AppColors.azulPrimario,
            inactiveTrackColor: AppColors.fondoCardBorde,
            overlayColor: AppColors.azulPrimario.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: amount,
            min: 1.0,
            max: max < 1.0 ? 1.0 : max,
            divisions: max > 1.0 ? ((max - 1.0) * 10).round().clamp(1, 990) : 1,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('\$1.00',
                style: TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12)),
            Text('\$${max.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12)),
          ],
        ),
      ]),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _MethodCard(
      {required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? method.color.withValues(alpha: 0.1)
              : AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? method.color : AppColors.fondoCardBorde,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: method.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.icon, color: method.color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(method.label,
              style: TextStyle(
                  color: selected
                      ? AppColors.textoPrimario
                      : AppColors.textoSecundario,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14)),
          const Spacer(),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: method.color, size: 20),
        ]),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final double amount;
  final int coins;
  final String method;
  const _SummaryBox(
      {required this.amount, required this.coins, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(children: [
        _Row('Monto', '\$${amount.toStringAsFixed(2)} USD'),
        const SizedBox(height: 6),
        _Row('Monedas a descontar', '$coins monedas'),
        const SizedBox(height: 6),
        _Row('Método', method),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      );
}
