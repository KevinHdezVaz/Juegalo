import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/l10n_ext.dart';

/// Pantalla de verificación de identidad por email OTP.
/// Se muestra antes de procesar un retiro.
///
/// Uso:
///   final verified = await Navigator.push<bool>(context,
///     MaterialPageRoute(builder: (_) => const EmailVerificationScreen()));
///   if (verified == true) { /* proceder con el retiro */ }
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  // ── Controladores ─────────────────────────────────────────────────
  final _hiddenCtrl = TextEditingController();
  final _hiddenFocus = FocusNode();

  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  String _digits = '';

  int _resendCountdown = 0;
  Timer? _resendTimer;

  // ── Animaciones ───────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _successCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _shake;
  late final Animation<double> _successScale;

  String get _userEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  String get _maskedEmail {
    if (_userEmail.isEmpty) return '';
    final parts = _userEmail.split('@');
    if (parts.length != 2) return _userEmail;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name[0]}${name[1]}***@$domain';
  }

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _successScale = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);

    _hiddenCtrl.addListener(_onTextChanged);
    _sendOtp();
  }

  @override
  void dispose() {
    _hiddenCtrl.removeListener(_onTextChanged);
    _hiddenCtrl.dispose();
    _hiddenFocus.dispose();
    _resendTimer?.cancel();
    _entryCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final raw = _hiddenCtrl.text.replaceAll(RegExp(r'\D'), '');
    final clamped = raw.length > 8 ? raw.substring(0, 8) : raw;
    if (clamped != _digits) {
      setState(() { _digits = clamped; _error = null; });
      if (clamped.length == 8) _verify();
    }
  }

  // ── Enviar OTP ───────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    debugPrint('📧 [EmailVerif] _sendOtp() iniciado');
    debugPrint('📧 [EmailVerif] email: $_userEmail');
    debugPrint('📧 [EmailVerif] email vacío: ${_userEmail.isEmpty}');
    setState(() { _loading = true; _error = null; _digits = ''; });
    _hiddenCtrl.clear();
    try {
      debugPrint('📧 [EmailVerif] Llamando signInWithOtp...');
      await Supabase.instance.client.auth.signInWithOtp(
        email: _userEmail,
        shouldCreateUser: false,
      );
      debugPrint('📧 [EmailVerif] ✅ OTP enviado exitosamente a $_userEmail');
      if (mounted) {
        setState(() {
          _otpSent = true;
          _loading = false;
          _resendCountdown = 60;
        });
        _startResendTimer();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _openKeyboard();
        });
      }
    } catch (e) {
      debugPrint('📧 [EmailVerif] ❌ Error enviando OTP: $e');
      debugPrint('📧 [EmailVerif] Error tipo: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.l10n.emailVerifErrorSend;
        });
      }
    }
  }

  void _openKeyboard() {
    _hiddenFocus.unfocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_hiddenFocus);
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── Verificar código ─────────────────────────────────────────────
  Future<void> _verify() async {
    final code = _digits;
    if (code.length < 8) {
      setState(() => _error = context.l10n.emailVerifErrorLength);
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('🔐 [OTP] Verificando → email=$_userEmail token=$code type=email');
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _userEmail,
        token: code,
        type: OtpType.email,
      );
      if (mounted) {
        await _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      debugPrint('🔴 [OTP] AuthException → ${e.message} | code=${e.statusCode}');
      if (mounted) {
        _shakeCtrl.forward(from: 0);
        setState(() {
          _loading = false;
          _digits = '';
          _hiddenCtrl.clear();
          _error = e.message.contains('expired') || e.message.contains('invalid')
              ? context.l10n.emailVerifErrorWrong
              : context.l10n.emailVerifErrorGeneric;
        });
      }
    } catch (e) {
      debugPrint('🔴 [OTP] Error inesperado → $e');
      if (mounted) {
        _shakeCtrl.forward(from: 0);
        setState(() {
          _loading = false;
          _digits = '';
          _hiddenCtrl.clear();
          _error = context.l10n.emailVerifErrorGeneric;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Fondo degradado ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0F2044),
                  Color(0xFF1A3FCC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Círculos decorativos ─────────────────────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── AppBar custom ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: _otpSent
                                  ? const Color(0xFF34D399)
                                  : Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _otpSent ? context.l10n.emailVerifCodeSent : context.l10n.emailVerifSending,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slideUp,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                        child: Column(
                          children: [
                            // ── Ícono principal ──────────────────────
                            ScaleTransition(
                              scale: _successScale.status == AnimationStatus.completed
                                  ? _successScale
                                  : const AlwaysStoppedAnimation(1.0),
                              child: Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _successCtrl.value > 0.5
                                        ? [
                                            const Color(0xFF059669),
                                            const Color(0xFF10B981),
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.15),
                                            Colors.white.withValues(alpha: 0.08),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 30,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: AnimatedBuilder(
                                  animation: _successCtrl,
                                  builder: (_, __) => Icon(
                                    _successCtrl.value > 0.5
                                        ? Icons.check_rounded
                                        : Icons.mark_email_read_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Título ───────────────────────────────
                            Text(
                              context.l10n.emailVerifTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _otpSent
                                  ? context.l10n.emailVerifSentTo
                                  : context.l10n.emailVerifSending,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            if (_otpSent) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.email_rounded,
                                      color: Colors.white, size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    _maskedEmail,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 36),

                            // ── Cajas OTP ────────────────────────────
                            if (_loading && !_otpSent)
                              Column(children: [
                                const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.emailVerifSendingBtn,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13),
                                ),
                              ])
                            else ...[
                              // Campo oculto que captura el input
                              SizedBox(
                                width: 0, height: 0,
                                child: TextField(
                                  controller: _hiddenCtrl,
                                  focusNode: _hiddenFocus,
                                  keyboardType: TextInputType.number,
                                  maxLength: 8,
                                  enabled: _otpSent && !_loading,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: ''),
                                  onSubmitted: (_) => _verify(),
                                ),
                              ),

                              // Cajas de dígitos visibles
                              AnimatedBuilder(
                                animation: _shake,
                                builder: (_, child) {
                                  final offset = _shake.value *
                                      10 *
                                      (0.5 - _shake.value).sign;
                                  return Transform.translate(
                                      offset: Offset(offset * 2, 0),
                                      child: child);
                                },
                                child: GestureDetector(
                                  onTap: _openKeyboard,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(8, (i) {
                                      final hasDigit = i < _digits.length;
                                      final isCurrent = i == _digits.length &&
                                          _hiddenFocus.hasFocus;
                                      final digit =
                                          hasDigit ? _digits[i] : '';

                                      return Padding(
                                        padding: EdgeInsets.only(
                                            right: i < 7 ? (i == 3 ? 12 : 4) : 0),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 150),
                                          width: 34,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: hasDigit
                                                ? Colors.white
                                                    .withValues(alpha: 0.18)
                                                : Colors.white
                                                    .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : hasDigit
                                                      ? Colors.white
                                                          .withValues(alpha: 0.5)
                                                      : Colors.white
                                                          .withValues(alpha: 0.15),
                                              width: isCurrent ? 2 : 1.5,
                                            ),
                                            boxShadow: isCurrent
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.2),
                                                      blurRadius: 12,
                                                      spreadRadius: 0,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              digit,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),

                              // ── Error ──────────────────────────────
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFFC8181), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Color(0xFFFC8181),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ]),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // ── Botón verificar ────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: (_loading ||
                                          !_otpSent ||
                                          _digits.length < 8)
                                      ? null
                                      : _verify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A3FCC),
                                    disabledBackgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    disabledForegroundColor:
                                        Colors.white.withValues(alpha: 0.4),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                             BorderRadius.circular(16)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              color: Color(0xFF1A3FCC),
                                              strokeWidth: 2.5))
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.verified_rounded,
                                                size: 20),
                                            const SizedBox(width: 10),
                                            Text(
                                              context.l10n.emailVerifConfirmBtn,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Reenviar ───────────────────────────
                              _resendCountdown > 0
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(
                                            value: _resendCountdown / 60,
                                            strokeWidth: 2,
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          context.l10n.emailVerifResendIn(_resendCountdown),
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.55),
                                              fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: _loading ? null : _sendOtp,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.refresh_rounded,
                                                color: Colors.white
                                                    .withValues(alpha: 0.85),
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              context.l10n.emailVerifResend,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.85),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                              const SizedBox(height: 36),

                              // ── Badge de seguridad ─────────────────
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFF10B981).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.shield_rounded,
                                          color: Color(0xFF34D399), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.emailVerifProtected,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            context.l10n.emailVerifProtectedSub,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.55),
                                              fontSize: 11,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
