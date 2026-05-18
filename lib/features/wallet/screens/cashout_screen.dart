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
import '../../profile/screens/phone_verification_screen.dart';
import '../../../shared/widgets/app_error_widget.dart';

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

// ── Pantalla principal ────────────────────────────────────────────
class CashoutScreen extends ConsumerStatefulWidget {
  const CashoutScreen({super.key});

  @override
  ConsumerState<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends ConsumerState<CashoutScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  PaymentMethod _method = PaymentMethod.paypal;
  final _detailCtrl     = TextEditingController();
  int _coins            = -1;
  bool _loading         = false;
  _Currency _currency   = _Currency.usd;

  // null = cargando, true = verificado, false = no verificado
  bool? _phoneVerified;

  static String _usd(int coins) =>
      (coins / AppConstants.coinsPerDollar).fmtUsd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPhone();
    debugPrint('🔵 [Cashout] initState');
  }

  /// Consulta el servidor para saber si el teléfono está verificado.
  /// Acepta tanto teléfono en auth.users.phone como el guardado en
  /// userMetadata['verified_phone'] (fallback email para Indonesia +62).
  Future<void> _checkPhone() async {
    try {
      final res = await Supabase.instance.client.auth.getUser();
      final phone = res.user?.phone?.isNotEmpty == true
          ? res.user!.phone!
          : (res.user?.userMetadata?['verified_phone'] as String? ?? '');
      if (mounted) setState(() => _phoneVerified = phone.isNotEmpty);
    } catch (_) {
      final u = Supabase.instance.client.auth.currentUser;
      final phone = u?.phone?.isNotEmpty == true
          ? u!.phone!
          : (u?.userMetadata?['verified_phone'] as String? ?? '');
      if (mounted) setState(() => _phoneVerified = phone.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  /// Verifica si el usuario tiene teléfono confirmado.
  /// Si no, abre la pantalla de verificación y espera el resultado.
  Future<bool> _ensurePhoneVerified() async {
    final user = Supabase.instance.client.auth.currentUser;
    final phone = user?.phone;
    if (phone != null && phone.isNotEmpty) return true; // ya verificado

    // Abrir pantalla de verificación
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PhoneVerificationScreen(),
      ),
    );
    return result == true;
  }

  Future<void> _submit(int availableCoins) async {
    final coinsToSpend = _coins;
    if (coinsToSpend > availableCoins) {
      _showInsufficientCoinsDialog(context, availableCoins);
      return;
    }
    final detail = _detailCtrl.text.trim();
    if (detail.isEmpty) {
      _snack(context.l10n.cashoutEnterAccount, error: true);
      return;
    }

    // ── Verificar teléfono antes de procesar ──────────────────────
    final phoneRequiredMsg = context.l10n.cashoutPhoneRequired;
    final phoneOk = await _ensurePhoneVerified();
    if (!phoneOk) {
      if (mounted) _snack(phoneRequiredMsg, error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('No autenticado');

      // p_amount_usd se calcula DENTRO del RPC (coins / coinsPerDollar)
      // No lo enviamos desde el cliente para evitar manipulación.
      await Supabase.instance.client.rpc('request_cashout', params: {
        'p_user_id': uid,
        'p_coins'  : coinsToSpend,
        'p_method' : _method.name,
        'p_account': '$detail | ${_currency.code}',
      });

      if (mounted) {
        ref.invalidate(userProvider);
        ref.invalidate(userNotifierProvider);
        ref.invalidate(cashoutRequestsProvider);
        _snack(context.l10n.cashoutSentSuccess);
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('🔴 [Cashout] ERROR: $e\n$stack');
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
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.azulPrimario),
          const SizedBox(width: 10),
          Text(context.l10n.walletAlmostThere,
              style: const TextStyle(
                  color: AppColors.textoPrimario, fontWeight: FontWeight.bold)),
        ]),
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
            child: Text(context.l10n.walletGotIt,
                style: const TextStyle(
                    color: AppColors.azulPrimario,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final notifier  = ref.read(userNotifierProvider.notifier);

    if (notifier.isAnonymous) {
      return Scaffold(
        backgroundColor: AppColors.fondoPrincipal,
        appBar: AppBar(
          title: Text(context.l10n.cashoutAppTitle),
          backgroundColor: AppColors.fondoPrincipal,
          foregroundColor: AppColors.textoPrimario,
        ),
        body: _LinkAccountGate(notifier: notifier),
      );
    }

    // ── Gate: esperando consulta al servidor ──────────────────────
    if (_phoneVerified == null) {
      return const Scaffold(
        backgroundColor: AppColors.fondoPrincipal,
        body: Center(child: CircularProgressIndicator(
            color: AppColors.azulPrimario, strokeWidth: 2.5)),
      );
    }

    // ── Gate: teléfono no verificado ──────────────────────────────
    if (_phoneVerified == false) {
      return Scaffold(
        backgroundColor: AppColors.fondoPrincipal,
        appBar: AppBar(
          title: Text(context.l10n.cashoutAppTitle),
          backgroundColor: AppColors.fondoPrincipal,
          foregroundColor: AppColors.textoPrimario,
        ),
        body: _PhoneGate(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: Text(context.l10n.walletRequestCashout),
        backgroundColor: AppColors.fondoPrincipal,
        foregroundColor: AppColors.textoPrimario,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.azulPrimario,
          unselectedLabelColor: AppColors.textoSecundario,
          indicatorColor: AppColors.azulPrimario,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            Tab(text: context.l10n.cashoutTabRequest),
            Tab(text: context.l10n.cashoutTabPayments),
          ],
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.azulPrimario)),
        error: (e, __) => _ErrorState(onRetry: () => ref.invalidate(userProvider)),
        data: (user) {
          if (user == null) {
            return _ErrorState(onRetry: () => ref.invalidate(userProvider));
          }
          final maxCoins = user.coins.clamp(AppConstants.minCashoutCoins, 1000000);
          if (_coins < 0 || _coins > maxCoins) _coins = maxCoins;

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Solicitar ───────────────────────────────
              _RequestTab(
                user: user,
                coins: _coins,
                maxCoins: maxCoins,
                method: _method,
                currency: _currency,
                detailCtrl: _detailCtrl,
                loading: _loading,
                onCoinsChanged: (v) => setState(() => _coins = v),
                onMethodChanged: (m) => setState(() {
                  _method = m;
                  _detailCtrl.clear();
                }),
                onCurrencyChanged: (c) => setState(() => _currency = c),
                onSubmit: () => _submit(user.coins),
                onInsufficientCoins: () =>
                    _showInsufficientCoinsDialog(context, user.coins),
              ),

              // ── Tab 2: Historial ───────────────────────────────
              const _HistoryTab(),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab 1: Formulario de cobro ────────────────────────────────────
class _RequestTab extends StatelessWidget {
  final dynamic user;
  final int coins;
  final int maxCoins;
  final PaymentMethod method;
  final _Currency currency;
  final TextEditingController detailCtrl;
  final bool loading;
  final ValueChanged<int> onCoinsChanged;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<_Currency> onCurrencyChanged;
  final VoidCallback onSubmit;
  final VoidCallback onInsufficientCoins;

  const _RequestTab({
    required this.user,
    required this.coins,
    required this.maxCoins,
    required this.method,
    required this.currency,
    required this.detailCtrl,
    required this.loading,
    required this.onCoinsChanged,
    required this.onMethodChanged,
    required this.onCurrencyChanged,
    required this.onSubmit,
    required this.onInsufficientCoins,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saldo disponible ─────────────────────────────────
          _BalanceChip(coins: user.coins),
          const SizedBox(height: 16),

          // ── Banner de confianza ──────────────────────────────
          const _TrustBanner(),
          const SizedBox(height: 24),

          // ── Monto ────────────────────────────────────────────
          _SectionTitle(context.l10n.cashoutSectionAmount),
          const SizedBox(height: 8),
          _AmountSelector(
            coins: coins,
            maxCoins: maxCoins,
            onChanged: onCoinsChanged,
          ),
          const SizedBox(height: 24),

          // ── Método de pago ───────────────────────────────────
          _SectionTitle(context.l10n.cashoutSectionMethod),
          const SizedBox(height: 10),
          ...PaymentMethod.values.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MethodCard(
              method: m,
              selected: method == m,
              onTap: m.isAvailable ? () {
                if (user.coins < AppConstants.minCashoutCoins) {
                  onInsufficientCoins();
                  return;
                }
                onMethodChanged(m);
              } : null,
            ),
          )),
          const SizedBox(height: 16),

          // ── Datos de cuenta y moneda ─────────────────────────
          _SectionTitle(context.l10n.cashoutSectionDetails),
          const SizedBox(height: 8),
          // Campo de cuenta y moneda en la misma card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuenta de ${method.label}',
                    style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: detailCtrl,
                  keyboardType: method.keyboardType,
                  style: const TextStyle(
                      color: AppColors.textoPrimario, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: method.hint,
                    hintStyle:
                        const TextStyle(color: AppColors.textoDeshabilitado),
                    prefixIcon:
                        Icon(method.icon, color: method.color, size: 20),
                    filled: true,
                    fillColor: AppColors.fondoPrincipal,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.fondoCardBorde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.fondoCardBorde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: method.color),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.fondoCardBorde, height: 1),
                const SizedBox(height: 14),
                Text(context.l10n.cashoutCurrencyLabel,
                    style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _CurrencySelector(
                  selected: currency,
                  onChanged: onCurrencyChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Resumen ──────────────────────────────────────────
          _SummaryBox(coins: coins, method: method.label, currency: currency),
          const SizedBox(height: 20),

          // ── Botón ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      'Confirmar cobro de ${_CashoutScreenState._usd(coins)}',
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
  }
}

// ── Banner de confianza ───────────────────────────────────────────
class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF064E3B),
            const Color(0xFF065F46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.cashoutTrustTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -.2,
                      ),
                    ),
                    Text(
                      'Tu dinero llega siempre. Sin excusas.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  '100% Real',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ]),
          ),

          // ── Divisor ─────────────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withValues(alpha: 0.1),
          ),

          // ── Stats en fila ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              _TrustStat(value: '\$12,847', label: 'USD pagados'),
              _TrustDivider(),
              _TrustStat(value: '1,000+', label: context.l10n.cashoutSuccessCount),
              _TrustDivider(),
              _TrustStat(value: '2–3', label: context.l10n.cashoutBusinessDays),
            ]),
          ),

          // ── Divisor ─────────────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withValues(alpha: 0.1),
          ),

          // ── Items de confianza ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _TrustItem(
                icon: Icons.payments_rounded,
                title: context.l10n.cashoutTrustPaypal,
                subtitle: context.l10n.cashoutTrustPaypalSub,
              ),
              const SizedBox(height: 12),
              _TrustItem(
                icon: Icons.shield_rounded,
                title: context.l10n.cashoutTrustSms,
                subtitle: context.l10n.cashoutTrustSmsSub,
              ),
              const SizedBox(height: 12),
              _TrustItem(
                icon: Icons.people_alt_rounded,
                title: context.l10n.cashoutTrustUsers,
                subtitle: context.l10n.cashoutTrustUsersSub,
              ),
              const SizedBox(height: 12),
              _TrustItem(
                icon: Icons.support_agent_rounded,
                title: context.l10n.cashoutTrustSupport,
                subtitle: context.l10n.cashoutTrustSupportSub,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  final String value;
  final String label;
  const _TrustStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -.5,
            )),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }
}

class _TrustDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11.5,
                    height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: Historial de pagos ─────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashoutAsync = ref.watch(cashoutRequestsProvider);

    return cashoutAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.azulPrimario)),
      error: (_, __) => AppErrorWidget(
        message: context.l10n.cashoutHistoryLoadError,
        onRetry: () => ref.invalidate(cashoutRequestsProvider),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const _EmptyHistory();
        }
        return RefreshIndicator(
          color: AppColors.azulPrimario,
          onRefresh: () async => ref.invalidate(cashoutRequestsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _HistoryCard(request: requests[i]),
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.textoPrimario.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.textoSecundario,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.cashoutHistoryEmpty,
              style: const TextStyle(
                color: AppColors.textoPrimario,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus cobros aparecerán aquí\ncuando los solicites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _HistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status     = request['status'] as String? ?? 'pending';
    final amountUsd  = (request['amount_usd'] as num?)?.toDouble() ?? 0;
    final coins      = (request['coins'] as num?)?.toInt() ?? 0;
    final method     = (request['method'] as String? ?? 'paypal').toUpperCase();
    final account    = request['account'] as String? ?? '—';
    final createdAt  = request['created_at'] as String?;

    final date = createdAt != null
        ? _formatDate(DateTime.parse(createdAt).toLocal())
        : '—';

    final (statusLabel, statusColor, statusIcon) = switch (status) {
      'paid'       => (context.l10n.cashoutStatusPaid,       AppColors.verdePrimario,         Icons.check_circle_rounded),
      'processing' => (context.l10n.cashoutStatusProcessing, AppColors.azulPrimario,          Icons.hourglass_top_rounded),
      'rejected'   => (context.l10n.cashoutStatusRejected,   AppColors.colorVideos,           Icons.cancel_rounded),
      _            => (context.l10n.cashoutStatusPending,    const Color(0xFFF59E0B),         Icons.schedule_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila superior: monto + badge ─────────────────────
          Row(
            children: [
              // Ícono método
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.azulPrimario.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.azulPrimario, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${amountUsd.toStringAsFixed(2)} USD',
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${coins.formatted} monedas • $method',
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Badge de estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.fondoCardBorde, height: 1),
          const SizedBox(height: 10),

          // ── Cuenta + fecha ───────────────────────────────────
          Row(
            children: [
              const Icon(Icons.alternate_email_rounded,
                  size: 13, color: AppColors.textoSecundario),
              const SizedBox(width: 5),
              Expanded(
                child: Text(account,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textoSecundario),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 12)),
            ],
          ),

          // Nota extra según estado
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.cashoutReviewNote,
              style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ] else if (status == 'rejected') ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.cashoutRejectedNote,
              style: const TextStyle(
                  color: AppColors.colorVideos,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Error state ───────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textoSecundario),
            const SizedBox(height: 16),
            Text(context.l10n.cashoutLoadError,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(context.l10n.cashoutLoadErrorSub,
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.errorRetry,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
          Text(context.l10n.cashoutAvailableBalance(usdStr),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(context.l10n.cashoutCoins(coins.formatted),
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
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
    final minCoins  = AppConstants.minCashoutCoins;
    final sliderMax = maxCoins.toDouble();
    final sliderMin = minCoins.toDouble();
    final divisions = (maxCoins - minCoins).clamp(1, 100000);
    final usdStr    = _CashoutScreenState._usd(coins);
    final usdMaxStr = _CashoutScreenState._usd(maxCoins);
    final usdMinStr = _CashoutScreenState._usd(minCoins);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(children: [
        Text(
          '$usdStr USD',
          style: const TextStyle(
              color: AppColors.azulPrimario,
              fontSize: 36,
              fontWeight: FontWeight.w900),
        ),
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
              color: method.color
                  .withValues(alpha: available ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.icon,
                color: available
                    ? method.color
                    : AppColors.textoDeshabilitado,
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
                            ? (selected
                                ? AppColors.textoPrimario
                                : AppColors.textoSecundario)
                            : AppColors.textoDeshabilitado,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14)),
                Text(method.subtitle(context),
                    style: TextStyle(
                        color: available
                            ? (selected
                                ? method.color
                                : AppColors.textoDeshabilitado)
                            : AppColors.textoDeshabilitado,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!available)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  const _SummaryBox(
      {required this.coins, required this.method, required this.currency});

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
        _Row(context.l10n.cashoutSummaryAmount, '$usdStr USD'),
        const SizedBox(height: 6),
        _Row(context.l10n.cashoutSummaryCoins,
            context.l10n.cashoutCoins(coins.formatted)),
        const SizedBox(height: 6),
        _Row(context.l10n.cashoutSummaryMethod, method),
        const SizedBox(height: 6),
        _Row(context.l10n.cashoutSummaryCurrency,
            '${currency.flag}  ${currency.code} — ${currency.label}'),
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
      backgroundColor:
          error ? AppColors.colorVideos : AppColors.verdePrimario,
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
          Text(
            context.l10n.cashoutCreateAccount,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textoPrimario,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.cashoutGuestSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textoSecundario, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.cashoutGuestCurrentCoins,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Consumer(builder: (ctx, ref, __) {
                  final user = ref.watch(userProvider).valueOrNull;
                  return Text(
                    ctx.l10n.cashoutGuestCoins(
                        (user?.coins ?? 0).formatted),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  );
                }),
              ]),
            ]),
          ),
          const SizedBox(height: 28),
          if (_loading)
            const CircularProgressIndicator(color: AppColors.azulPrimario)
          else ...[
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _linkGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      Text(context.l10n.cashoutGuestContinueGoogle,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
            const SizedBox(height: 10),
            if (Platform.isIOS) ...[
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _linkApple,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apple, size: 22, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(context.l10n.cashoutGuestContinueApple,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity, height: 54,
              child: OutlinedButton(
                onPressed: _linkEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textoPrimario,
                  side: const BorderSide(
                      color: AppColors.fondoCardBorde, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(context.l10n.cashoutGuestCreateEmail,
                          style: const TextStyle(
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
                color: AppColors.textoSecundario, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de creación de cuenta con email ─────────────────
class _EmailLinkSheet extends StatefulWidget {
  final Future<void> Function(
      String email, String password, String firstName, String lastName) onLink;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.cashoutNameDialogContent),
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
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.fondoCardBorde,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.cashoutGuestCreateEmail,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(context.l10n.cashoutCreateEmailSubtitle,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          const SizedBox(height: 20),
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
          _Field(
              controller: _emailCtrl,
              label: context.l10n.emailDialogEmail,
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(
                color: AppColors.textoPrimario, fontSize: 14),
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
                  color: AppColors.textoSecundario, size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true,
              fillColor: AppColors.fondoPrincipal,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 14),
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
          _Field(
              controller: _pass2Ctrl,
              label: context.l10n.profileConfirmPassword,
              icon: Icons.lock_outline_rounded,
              type: TextInputType.visiblePassword,
              obscure: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
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
        style: const TextStyle(
            color: AppColors.textoPrimario, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppColors.textoSecundario, fontSize: 13),
          prefixIcon: Icon(icon,
              color: AppColors.textoSecundario, size: 18),
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
  // Más usadas (primero)
  usd('USD', 'Dólares estadounidenses', '🇺🇸'),
  eur('EUR', 'Euros',                   '🇪🇺'),
  gbp('GBP', 'Libras esterlinas',       '🇬🇧'),
  // América Latina
  mxn('MXN', 'Pesos mexicanos',         '🇲🇽'),
  ars('ARS', 'Pesos argentinos',        '🇦🇷'),
  cop('COP', 'Pesos colombianos',       '🇨🇴'),
  brl('BRL', 'Reales brasileños',       '🇧🇷'),
  pen('PEN', 'Soles peruanos',          '🇵🇪'),
  clp('CLP', 'Pesos chilenos',          '🇨🇱'),
  uyu('UYU', 'Pesos uruguayos',         '🇺🇾'),
  bob('BOB', 'Bolivianos',              '🇧🇴'),
  pyg('PYG', 'Guaraníes paraguayos',    '🇵🇾'),
  vef('VES', 'Bolívares venezolanos',   '🇻🇪'),
  gtq('GTQ', 'Quetzales guatemaltecos', '🇬🇹'),
  crc('CRC', 'Colones costarricenses',  '🇨🇷'),
  hnl('HNL', 'Lempiras hondureños',     '🇭🇳'),
  nio('NIO', 'Córdobas nicaragüenses',  '🇳🇮'),
  pab('PAB', 'Balboas panameños',       '🇵🇦'),
  dop('DOP', 'Pesos dominicanos',       '🇩🇴'),
  // Europa
  chf('CHF', 'Francos suizos',          '🇨🇭'),
  sek('SEK', 'Coronas suecas',          '🇸🇪'),
  nok('NOK', 'Coronas noruegas',        '🇳🇴'),
  dkk('DKK', 'Coronas danesas',        '🇩🇰'),
  pln('PLN', 'Złoty polaco',            '🇵🇱'),
  czk('CZK', 'Coronas checas',          '🇨🇿'),
  huf('HUF', 'Forints húngaros',        '🇭🇺'),
  ron('RON', 'Leus rumanos',            '🇷🇴'),
  try_('TRY', 'Liras turcas',           '🇹🇷'),
  // Asia
  jpy('JPY', 'Yenes japoneses',         '🇯🇵'),
  cny('CNY', 'Yuanes chinos',           '🇨🇳'),
  krw('KRW', 'Wons surcoreanos',        '🇰🇷'),
  inr('INR', 'Rupias indias',           '🇮🇳'),
  idr('IDR', 'Rupias indonesias',       '🇮🇩'),
  php('PHP', 'Pesos filipinos',         '🇵🇭'),
  thb('THB', 'Bahts tailandeses',       '🇹🇭'),
  vnd('VND', 'Dongs vietnamitas',       '🇻🇳'),
  sgd('SGD', 'Dólares singapurenses',   '🇸🇬'),
  myr('MYR', 'Ringgits malayos',        '🇲🇾'),
  pkr('PKR', 'Rupias pakistaníes',      '🇵🇰'),
  aed('AED', 'Dírhams emiratíes',       '🇦🇪'),
  sar('SAR', 'Riyales saudíes',         '🇸🇦'),
  ils('ILS', 'Shékels israelíes',       '🇮🇱'),
  // Oceanía
  aud('AUD', 'Dólares australianos',    '🇦🇺'),
  nzd('NZD', 'Dólares neozelandeses',   '🇳🇿'),
  // África
  zar('ZAR', 'Rands sudafricanos',      '🇿🇦'),
  ngn('NGN', 'Nairas nigerianas',       '🇳🇬'),
  kes('KES', 'Chelines kenianos',       '🇰🇪'),
  // Otras
  cad('CAD', 'Dólares canadienses',     '🇨🇦'),
  rub('RUB', 'Rublos rusos',            '🇷🇺');

  final String code;
  final String label;
  final String flag;
  const _Currency(this.code, this.label, this.flag);
}

// ── Selector de moneda ────────────────────────────────────────────
class _CurrencySelector extends StatelessWidget {
  final _Currency selected;
  final ValueChanged<_Currency> onChanged;
  const _CurrencySelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fondoPrincipal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.fondoCardBorde),
        ),
        child: Row(
          children: [
            Text(selected.flag,
                style: const TextStyle(fontSize: 20)),
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
                          color: AppColors.textoSecundario,
                          fontSize: 12)),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CurrencyPickerSheet(
        selected: selected,
        onChanged: (c) {
          onChanged(c);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Sheet con buscador ────────────────────────────────────────────────────────
class _CurrencyPickerSheet extends StatefulWidget {
  final _Currency selected;
  final ValueChanged<_Currency> onChanged;
  const _CurrencyPickerSheet(
      {required this.selected, required this.onChanged});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_Currency> _filtered = _Currency.values;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _Currency.values
          : _Currency.values
              .where((c) =>
                  c.code.toLowerCase().contains(query) ||
                  c.label.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: maxH,
      child: Column(children: [
        // Handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.fondoCardBorde,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Título
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            const Icon(Icons.currency_exchange_rounded,
                color: AppColors.azulPrimario, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.cashoutCurrencyTitle,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const Spacer(),
            Text(context.l10n.cashoutCurrencyCount(_Currency.values.length),
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12)),
          ]),
        ),

        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            autofocus: false,
            decoration: InputDecoration(
              hintText: context.l10n.cashoutCurrencySearch,
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.azulPrimario, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.fondoPrincipal,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Lista
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(context.l10n.phoneVerifyNoResults,
                      style: TextStyle(color: Colors.grey.shade400)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    final isSelected = c == widget.selected;
                    return ListTile(
                      dense: true,
                      onTap: () => widget.onChanged(c),
                      leading: Text(c.flag,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(c.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.azulPrimario
                                : AppColors.textoPrimario,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          )),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.azulPrimario
                                : AppColors.fondoPrincipal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c.code,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textoSecundario,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              )),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_rounded,
                              color: AppColors.azulPrimario, size: 18),
                        ],
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Gate: verificación de teléfono requerida ──────────────────────────────────
class _PhoneGate extends StatefulWidget {
  const _PhoneGate();

  @override
  State<_PhoneGate> createState() => _PhoneGateState();
}

class _PhoneGateState extends State<_PhoneGate> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slideUp;
  late final Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fade    = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _goVerify() async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
    );
    if (!mounted) return;
    if (verified == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CashoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Fondo degradado ────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1F8A), Color(0xFF1A3FCC), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // ── Círculos decorativos ───────────────────────────────────
        Positioned(top: -60, right: -40,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(bottom: -50, left: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05)))),
        Positioned(top: size.height * 0.3, right: -20,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),

        // ── Contenido ──────────────────────────────────────────────
        FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slideUp,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                child: Column(
                  children: [

                    // Ícono con pulso
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.12),
                              blurRadius: 30, spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.phone_android_rounded,
                            size: 52, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Título
                    Text(
                      context.l10n.cashoutGateTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.25,
                        shadows: [Shadow(color: Colors.black26,
                            blurRadius: 8, offset: Offset(0, 3))],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      context.l10n.phoneVerifySubtitlePhone,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Pasos
                    _StepRow(
                      number: '1', icon: Icons.phone_android_rounded,
                      title: context.l10n.cashoutGateStep1Title,
                      subtitle: context.l10n.cashoutGateStep1Subtitle,
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      number: '2', icon: Icons.sms_rounded,
                      title: context.l10n.cashoutGateStep2Title,
                      subtitle: context.l10n.cashoutGateStep2Subtitle,
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                      number: '3', icon: Icons.payments_rounded,
                      title: context.l10n.cashoutGateStep3Title,
                      subtitle: context.l10n.cashoutGateStep3Subtitle,
                    ),

                    const SizedBox(height: 36),

                    // Botón principal
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _goVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A3FCC),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(context.l10n.cashoutGateButton,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nota de seguridad
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.shield_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.phoneVerifyPrivacyNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.80),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fila de paso ──────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String   number;
  final IconData icon;
  final String   title;
  final String   subtitle;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A3FCC),
                )),
          ),
        ),
        const SizedBox(width: 14),
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  )),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded,
            color: Colors.white.withValues(alpha: 0.30), size: 18),
      ]),
    );
  }
}

