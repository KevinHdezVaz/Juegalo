import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/cashout_provider.dart';
import '../../../shared/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Métodos de pago ───────────────────────────────────────────────
enum PaymentMethod { paypal, mercadopago }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.paypal      => 'PayPal',
    PaymentMethod.mercadopago => 'MercadoPago',
  };
  String get hint => switch (this) {
    PaymentMethod.paypal      => 'correo@ejemplo.com',
    PaymentMethod.mercadopago => 'Correo, teléfono o CVU/alias',
  };
  String subtitle(BuildContext context) => switch (this) {
    PaymentMethod.paypal      => context.l10n.cashoutPaypalSubtitle,
    PaymentMethod.mercadopago => context.l10n.walletComingSoonFull,
  };
  IconData get icon => switch (this) {
    PaymentMethod.paypal      => Icons.paypal_rounded,
    PaymentMethod.mercadopago => Icons.account_balance_rounded,
  };
  Color get color => switch (this) {
    PaymentMethod.paypal      => const Color(0xFF003087),
    PaymentMethod.mercadopago => const Color(0xFF009EE3),
  };
  bool get isAvailable => switch (this) {
    PaymentMethod.paypal      => true,
    PaymentMethod.mercadopago => false,
  };
  TextInputType get keyboardType => TextInputType.emailAddress;
}

// ── Pantalla ──────────────────────────────────────────────────────
class CashoutScreen extends ConsumerStatefulWidget {
  const CashoutScreen({super.key});

  @override
  ConsumerState<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends ConsumerState<CashoutScreen> {
  PaymentMethod _method = PaymentMethod.paypal;
  final _detailCtrl     = TextEditingController();
  int _coins            = -1; // -1 = no inicializado → se setea al máximo en el primer build
  bool _loading         = false;
  _Currency _currency   = _Currency.usd;

  // Convierte monedas a USD exacto (sin trailing zeros)
  static String _usd(int coins) =>
      (coins / AppConstants.coinsPerDollar).fmtUsd;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [Cashout] initState | _loading: $_loading');
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(int availableCoins) async {
    final coinsToSpend = _coins;
    debugPrint('🟡 [Cashout] _submit llamado | coinsToSpend: $coinsToSpend | disponibles: $availableCoins');

    if (coinsToSpend > availableCoins) {
      debugPrint('🔴 [Cashout] Bloqueado: saldo insuficiente');
      _showInsufficientCoinsDialog(context, availableCoins);
      return;
    }

    final detail = _detailCtrl.text.trim();
    if (detail.isEmpty) {
      debugPrint('🔴 [Cashout] Bloqueado: detail vacío');
      _snack('Ingresa los datos de tu cuenta', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('🟡 [Cashout] uid: $uid');
      if (uid == null) throw Exception('No autenticado');

      await Supabase.instance.client.rpc('request_cashout', params: {
        'p_user_id'       : uid,
        'p_amount_usd'    : coinsToSpend / AppConstants.coinsPerDollar,
        'p_coins'         : coinsToSpend,
        'p_method'        : _method.name,
        'p_payment_detail': '$detail | ${_currency.code}',
        'p_account'       : detail,
      });

      if (mounted) {
        // Refrescar saldo y solicitudes
        ref.invalidate(userProvider);
        ref.invalidate(userNotifierProvider);
        ref.invalidate(cashoutRequestsProvider);
        _snack(context.l10n.cashoutSentSuccess);
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('🔴 [Cashout] ERROR: $e');
      debugPrint('🔴 [Cashout] STACK: $stack');
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

  void _showInsufficientCoinsDialog(BuildContext context, int currentCoins) {
    final needed = AppConstants.minCashoutCoins - currentCoins;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.fondoElevado,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.azulPrimario),
            const SizedBox(width: 10),
            Text(context.l10n.walletAlmostThere, style: const TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          context.l10n.walletNeedCoins(
            AppConstants.minCashoutCoins.formatted,
            (needed > 0 ? needed : 0).formatted,
          ),
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.walletGotIt, style: const TextStyle(color: AppColors.azulPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final notifier  = ref.read(userNotifierProvider.notifier);

    debugPrint('🔵 [Cashout] build | isAnonymous: ${notifier.isAnonymous} | _loading: $_loading');

    // Detectar anónimo
    if (notifier.isAnonymous) {
      return Scaffold(
        backgroundColor: AppColors.fondoPrincipal,
        appBar: AppBar(
          title: const Text('Solicitar cobro'),
          backgroundColor: AppColors.fondoPrincipal,
          foregroundColor: AppColors.textoPrimario,
        ),
        body: _LinkAccountGate(notifier: notifier),
      );
    }

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
        error: (e, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textoSecundario),
                const SizedBox(height: 16),
                Text('No se pudo cargar tu información',
                    style: const TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700, fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Verifica tu conexión e intenta de nuevo',
                    style: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          debugPrint('🔵 [Cashout] userProvider data | user: ${user?.id} | coins: ${user?.coins}');
          if (user == null) {
            debugPrint('🔴 [Cashout] user es NULL → mostrando reintento');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.azulPrimario),
                    const SizedBox(height: 20),
                    const Text('Cargando tu cuenta...',
                        style: TextStyle(color: AppColors.textoSecundario, fontSize: 14)),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => ref.invalidate(userProvider),
                      child: const Text('Reintentar',
                          style: TextStyle(color: AppColors.azulPrimario, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }
          final maxCoins = user.coins.clamp(AppConstants.minCashoutCoins, 1000000);
          // Primera vez o si el saldo bajó → seleccionar el máximo disponible
          if (_coins < 0 || _coins > maxCoins) _coins = maxCoins;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Saldo disponible ───────────────────────────────
                _BalanceChip(coins: user.coins),
                const SizedBox(height: 24),

                // ── Monto ──────────────────────────────────────────
                const _SectionTitle('Monto a cobrar'),
                const SizedBox(height: 8),
                _AmountSelector(
                  coins: _coins,
                  maxCoins: maxCoins,
                  onChanged: (v) => setState(() => _coins = v),
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
                    onTap: m.isAvailable ? () {
                      if (user.coins < AppConstants.minCashoutCoins) {
                        _showInsufficientCoinsDialog(context, user.coins);
                        return;
                      }
                      setState(() {
                        _method = m;
                        _detailCtrl.clear();
                      });
                    } : null,
                  ),
                )),
                const SizedBox(height: 16),

                // ── Datos de cuenta ────────────────────────────────
                const _SectionTitle('Datos de tu cuenta'),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailCtrl,
                  keyboardType: _method.keyboardType,
                  inputFormatters: null,
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
                const SizedBox(height: 12),

                // ── Moneda ─────────────────────────────────────────
                const _SectionTitle('Moneda de pago'),
                const SizedBox(height: 8),
                _CurrencySelector(
                  selected: _currency,
                  onChanged: (c) => setState(() => _currency = c),
                ),
                const SizedBox(height: 28),

                // ── Resumen ────────────────────────────────────────
                _SummaryBox(
                  coins: _coins,
                  method: _method.label,
                  currency: _currency,
                ),
                const SizedBox(height: 20),

                // ── Botón ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () {
                    debugPrint('🟢 [Cashout] Botón Confirmar tocado | _loading: $_loading | coins: ${user.coins} | _coins: $_coins');
                    _submit(user.coins);
                  },
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
                            'Confirmar cobro de ${_CashoutScreenState._usd(_coins)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    context.l10n.cashoutProcessingNote,
                    style: const TextStyle(
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
  const _BalanceChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    final usdStr = _CashoutScreenState._usd(coins);
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
          Text('$usdStr USD disponibles',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(context.l10n.cashoutCoins(coins.formatted),
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
  final int coins;
  final int maxCoins;
  final ValueChanged<int> onChanged;
  const _AmountSelector(
      {required this.coins, required this.maxCoins, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final minCoins   = AppConstants.minCashoutCoins;
    final sliderMax  = maxCoins.toDouble();
    final sliderMin  = minCoins.toDouble();
    final divisions  = (maxCoins - minCoins).clamp(1, 100000);
    final usdStr     = _CashoutScreenState._usd(coins);
    final usdMaxStr  = _CashoutScreenState._usd(maxCoins);
    final usdMinStr  = _CashoutScreenState._usd(minCoins);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(children: [
        // USD grande
        Text(
          '$usdStr USD',
          style: const TextStyle(
              color: AppColors.azulPrimario,
              fontSize: 36,
              fontWeight: FontWeight.w900),
        ),
        // Monedas equivalentes
        Text(
          context.l10n.cashoutCoins(coins.formatted),
          style: const TextStyle(
              color: AppColors.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.azulPrimario,
            thumbColor: AppColors.azulPrimario,
            inactiveTrackColor: AppColors.fondoCardBorde,
            overlayColor: AppColors.azulPrimario.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: coins.toDouble().clamp(sliderMin, sliderMax),
            min: sliderMin,
            max: sliderMax,
            divisions: divisions,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.cashoutMinLabel(usdMinStr),
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12)),
            Text(context.l10n.cashoutMaxLabel(usdMaxStr),
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
  final VoidCallback? onTap;
  const _MethodCard(
      {required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final available = method.isAvailable;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !available
              ? AppColors.fondoElevado.withValues(alpha: 0.5)
              : selected
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
              color: method.color.withValues(alpha: available ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.icon,
                color: available ? method.color : AppColors.textoDeshabilitado,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.label,
                    style: TextStyle(
                        color: available
                            ? (selected ? AppColors.textoPrimario : AppColors.textoSecundario)
                            : AppColors.textoDeshabilitado,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14)),
                Text(method.subtitle(context),
                    style: TextStyle(
                        color: available
                            ? (selected ? method.color : AppColors.textoDeshabilitado)
                            : AppColors.textoDeshabilitado,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!available)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fondoCardBorde,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(context.l10n.walletComingSoon,
                  style: const TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            )
          else if (selected)
            Icon(Icons.check_circle_rounded, color: method.color, size: 20),
        ]),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final int coins;
  final String method;
  final _Currency currency;
  const _SummaryBox({required this.coins, required this.method, required this.currency});

  @override
  Widget build(BuildContext context) {
    final usdStr = _CashoutScreenState._usd(coins);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(children: [
        _Row('Monto', '$usdStr USD'),
        const SizedBox(height: 6),
        _Row(context.l10n.cashoutSummaryCoins, context.l10n.cashoutCoins(coins.formatted)),
        const SizedBox(height: 6),
        _Row('Método', method),
        const SizedBox(height: 6),
        _Row('Moneda', '${currency.flag}  ${currency.code} — ${currency.label}'),
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

// ── Gate de vinculación para usuarios anónimos ───────────────────
class _LinkAccountGate extends StatefulWidget {
  final UserNotifier notifier;
  const _LinkAccountGate({required this.notifier});

  @override
  State<_LinkAccountGate> createState() => _LinkAccountGateState();
}

class _LinkAccountGateState extends State<_LinkAccountGate> {
  bool _loading = false;

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
      if (mounted) _snack(context.l10n.cashoutGuestLinked);
    } catch (e) {
      if (mounted) _snack('Error al vincular con Google: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _linkApple() async {
    setState(() => _loading = true);
    try {
      await widget.notifier.linkWithApple();
      if (mounted) _snack(context.l10n.cashoutGuestLinked);
    } catch (e) {
      if (mounted) _snack('Error al vincular con Apple: $e', error: true);
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
        onLink: (email, password, firstName, lastName) async {
          Navigator.of(context).pop();
          setState(() => _loading = true);
          try {
            await widget.notifier.linkWithEmail(
              email: email,
              password: password,
              firstName: firstName,
              lastName: lastName,
            );
            if (mounted) _snack(context.l10n.cashoutGuestCreated);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Icono
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.azulPrimario.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppColors.azulPrimario, size: 38),
          ),
          const SizedBox(height: 20),

          // Título
          const Text(
            'Crea una cuenta para cobrar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.cashoutGuestSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Monedas actuales
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.cashoutGuestCurrentCoins,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Consumer(builder: (ctx, ref, __) {
                  final user = ref.watch(userProvider).valueOrNull;
                  return Text(
                    ctx.l10n.cashoutGuestCoins((user?.coins ?? 0).formatted),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          if (_loading)
            const CircularProgressIndicator(color: AppColors.azulPrimario)
          else ...[
            // Google
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _linkGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: const Center(
                      child: Text('G',
                          style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Continuar con Google',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // Apple (solo iOS)
            if (Platform.isIOS) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _linkApple,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple, size: 22, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Continuar con Apple',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Email
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _linkEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textoPrimario,
                  side: const BorderSide(
                      color: AppColors.fondoCardBorde, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Crear cuenta con correo',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            context.l10n.cashoutGuestNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de creación de cuenta con email ─────────────────
class _EmailLinkSheet extends StatefulWidget {
  final Future<void> Function(String email, String password, String firstName, String lastName) onLink;
  const _EmailLinkSheet({required this.onLink});

  @override
  State<_EmailLinkSheet> createState() => _EmailLinkSheetState();
}

class _EmailLinkSheetState extends State<_EmailLinkSheet> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _pass2Ctrl     = TextEditingController();
  bool _obscure        = true;
  bool _loading        = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final email     = _emailCtrl.text.trim();
    final pass      = _passCtrl.text;
    final pass2     = _pass2Ctrl.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa tu nombre y apellido'),
        backgroundColor: AppColors.colorVideos,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

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
    await widget.onLink(email, pass, firstName, lastName);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.fondoCardBorde,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Crear cuenta con correo',
              style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(context.l10n.cashoutCreateEmailSubtitle,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          const SizedBox(height: 20),

          // Nombre y Apellido en fila
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _firstNameCtrl,
                  label: context.l10n.profileFirstName,
                  icon: Icons.person_outline_rounded,
                  type: TextInputType.name,
                  action: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: _lastNameCtrl,
                  label: context.l10n.profileLastName,
                  icon: Icons.person_outline_rounded,
                  type: TextInputType.name,
                  action: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email
          _Field(
              controller: _emailCtrl,
              label: context.l10n.emailDialogEmail,
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),

          // Contraseña
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
            decoration: InputDecoration(
              labelText: context.l10n.emailDialogPassword,
              labelStyle: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textoSecundario, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textoSecundario,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true,
              fillColor: AppColors.fondoPrincipal,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.fondoCardBorde)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.fondoCardBorde)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.azulPrimario, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),

          // Confirmar contraseña
          _Field(
              controller: _pass2Ctrl,
              label: context.l10n.profileConfirmPassword,
              icon: Icons.lock_outline_rounded,
              type: TextInputType.visiblePassword,
              obscure: true),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(context.l10n.cashoutCreateEmailButton,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
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
  final TextInputAction action;
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.type,
    this.obscure = false,
    this.action = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        textInputAction: action,
        style:
            const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppColors.textoSecundario, fontSize: 13),
          prefixIcon:
              Icon(icon, color: AppColors.textoSecundario, size: 18),
          filled: true,
          fillColor: AppColors.fondoPrincipal,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.fondoCardBorde)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.fondoCardBorde)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.azulPrimario, width: 1.5)),
        ),
      );
}

// ── Monedas disponibles ───────────────────────────────────────────
enum _Currency {
  usd('USD', 'Dólares estadounidenses', '🇺🇸'),
  mxn('MXN', 'Pesos mexicanos',         '🇲🇽'),
  ars('ARS', 'Pesos argentinos',         '🇦🇷'),
  cop('COP', 'Pesos colombianos',        '🇨🇴'),
  brl('BRL', 'Reales brasileños',        '🇧🇷'),
  pen('PEN', 'Soles peruanos',           '🇵🇪'),
  clp('CLP', 'Pesos chilenos',           '🇨🇱'),
  eur('EUR', 'Euros',                    '🇪🇺');

  final String code;
  final String label;
  final String flag;
  const _Currency(this.code, this.label, this.flag);
}

// ── Selector de moneda ────────────────────────────────────────────
class _CurrencySelector extends StatelessWidget {
  final _Currency selected;
  final ValueChanged<_Currency> onChanged;
  const _CurrencySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fondoCardBorde),
        ),
        child: Row(
          children: [
            Text(selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.code,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(selected.label,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                color: AppColors.textoDeshabilitado, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fondoCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.fondoCardBorde,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Text('Selecciona la moneda',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            ..._Currency.values.map((c) => ListTile(
              onTap: () {
                onChanged(c);
                Navigator.pop(ctx);
              },
              leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
              title: Text('${c.code} — ${c.label}',
                  style: TextStyle(
                      color: c == selected
                          ? AppColors.azulPrimario
                          : AppColors.textoPrimario,
                      fontWeight: c == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14)),
              trailing: c == selected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.azulPrimario, size: 20)
                  : null,
            )),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }
}
