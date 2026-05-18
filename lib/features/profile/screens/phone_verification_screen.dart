import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';

/// Pantalla de verificación de teléfono via SMS OTP (Supabase + Twilio).
/// Se muestra antes de procesar un retiro si el usuario no tiene teléfono verificado.
///
/// Uso:
///   final verified = await Navigator.push<bool>(context,
///     MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()));
///   if (verified == true) { /* proceder con el retiro */ }
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  // ── Pasos ─────────────────────────────────────────────────────────
  bool _otpSent = false;

  // ── Controladores ─────────────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus   = FocusNode();
  final _emailFocus = FocusNode();

  // ── Estado ────────────────────────────────────────────────────────
  bool   _loading      = false;
  String _countryCode  = '+52'; // México por defecto
  String? _error;

  // ── Reenvío ───────────────────────────────────────────────────────
  int  _resendCountdown = 0;
  Timer? _resendTimer;

  // ── Indonesia email fallback ──────────────────────────────────────
  bool get _isIndonesia => _countryCode == '+62';
  String _verifiedEmail = '';

  // ── Países disponibles (global) ───────────────────────────────────
  static const _countries = [
    // América Latina
    ('+52', '🇲🇽', 'México'),
    ('+54', '🇦🇷', 'Argentina'),
    ('+55', '🇧🇷', 'Brasil'),
    ('+57', '🇨🇴', 'Colombia'),
    ('+56', '🇨🇱', 'Chile'),
    ('+51', '🇵🇪', 'Perú'),
    ('+58', '🇻🇪', 'Venezuela'),
    ('+502', '🇬🇹', 'Guatemala'),
    ('+503', '🇸🇻', 'El Salvador'),
    ('+504', '🇭🇳', 'Honduras'),
    ('+505', '🇳🇮', 'Nicaragua'),
    ('+506', '🇨🇷', 'Costa Rica'),
    ('+507', '🇵🇦', 'Panamá'),
    ('+591', '🇧🇴', 'Bolivia'),
    ('+593', '🇪🇨', 'Ecuador'),
    ('+595', '🇵🇾', 'Paraguay'),
    ('+598', '🇺🇾', 'Uruguay'),
    ('+53', '🇨🇺', 'Cuba'),
    ('+1787', '🇵🇷', 'Puerto Rico'),
    ('+1809', '🇩🇴', 'Rep. Dominicana'),
    // América del Norte
    ('+1',  '🇺🇸', 'Estados Unidos'),
    ('+1',  '🇨🇦', 'Canadá'),
    // Europa
    ('+34', '🇪🇸', 'España'),
    ('+44', '🇬🇧', 'Reino Unido'),
    ('+33', '🇫🇷', 'Francia'),
    ('+49', '🇩🇪', 'Alemania'),
    ('+39', '🇮🇹', 'Italia'),
    ('+351', '🇵🇹', 'Portugal'),
    ('+31', '🇳🇱', 'Países Bajos'),
    ('+32', '🇧🇪', 'Bélgica'),
    ('+41', '🇨🇭', 'Suiza'),
    ('+43', '🇦🇹', 'Austria'),
    ('+46', '🇸🇪', 'Suecia'),
    ('+47', '🇳🇴', 'Noruega'),
    ('+45', '🇩🇰', 'Dinamarca'),
    ('+358', '🇫🇮', 'Finlandia'),
    ('+48', '🇵🇱', 'Polonia'),
    ('+380', '🇺🇦', 'Ucrania'),
    ('+7',  '🇷🇺', 'Rusia'),
    ('+30', '🇬🇷', 'Grecia'),
    ('+420', '🇨🇿', 'República Checa'),
    ('+36', '🇭🇺', 'Hungría'),
    ('+40', '🇷🇴', 'Rumania'),
    ('+359', '🇧🇬', 'Bulgaria'),
    ('+385', '🇭🇷', 'Croacia'),
    ('+381', '🇷🇸', 'Serbia'),
    ('+90', '🇹🇷', 'Turquía'),
    // Asia
    ('+91', '🇮🇳', 'India'),
    ('+86', '🇨🇳', 'China'),
    ('+81', '🇯🇵', 'Japón'),
    ('+82', '🇰🇷', 'Corea del Sur'),
    ('+63', '🇵🇭', 'Filipinas'),
    ('+62', '🇮🇩', 'Indonesia'),
    ('+60', '🇲🇾', 'Malasia'),
    ('+66', '🇹🇭', 'Tailandia'),
    ('+84', '🇻🇳', 'Vietnam'),
    ('+65', '🇸🇬', 'Singapur'),
    ('+92', '🇵🇰', 'Pakistán'),
    ('+880', '🇧🇩', 'Bangladesh'),
    ('+94', '🇱🇰', 'Sri Lanka'),
    ('+977', '🇳🇵', 'Nepal'),
    ('+971', '🇦🇪', 'Emiratos Árabes'),
    ('+966', '🇸🇦', 'Arabia Saudita'),
    ('+972', '🇮🇱', 'Israel'),
    ('+98', '🇮🇷', 'Irán'),
    ('+964', '🇮🇶', 'Iraq'),
    ('+961', '🇱🇧', 'Líbano'),
    ('+962', '🇯🇴', 'Jordania'),
    ('+20', '🇪🇬', 'Egipto'),
    // África
    ('+27', '🇿🇦', 'Sudáfrica'),
    ('+234', '🇳🇬', 'Nigeria'),
    ('+254', '🇰🇪', 'Kenia'),
    ('+233', '🇬🇭', 'Ghana'),
    ('+212', '🇲🇦', 'Marruecos'),
    ('+213', '🇩🇿', 'Argelia'),
    ('+216', '🇹🇳', 'Túnez'),
    ('+251', '🇪🇹', 'Etiopía'),
    ('+255', '🇹🇿', 'Tanzania'),
    ('+256', '🇺🇬', 'Uganda'),
    // Oceanía
    ('+61', '🇦🇺', 'Australia'),
    ('+64', '🇳🇿', 'Nueva Zelanda'),
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _emailFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String get _fullPhone =>
      '$_countryCode${_phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '')}';

  void _setError(String? msg) => setState(() => _error = msg);

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  // ── Enviar OTP ────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (_isIndonesia) {
      await _sendEmailOtp();
    } else {
      await _sendSmsOtp();
    }
  }

  Future<void> _sendSmsOtp() async {
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) {
      _setError(context.l10n.phoneVerifyInvalidNumber);
      return;
    }
    _setError(null);
    setState(() => _loading = true);
    final unexpectedMsg = context.l10n.phoneVerifyUnexpectedError;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(phone: _fullPhone),
      );
      setState(() => _otpSent = true);
      _startResendTimer();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });
    } on AuthException catch (e) {
      _setError(_friendlyError(e.message));
    } catch (e) {
      _setError(unexpectedMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) {
      _setError(context.l10n.phoneVerifyInvalidNumber);
      return;
    }
    final email = _emailCtrl.text.trim();
    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailValid) {
      _setError(context.l10n.phoneVerifyEmailFallbackInvalid);
      return;
    }
    _setError(null);
    setState(() => _loading = true);
    final unexpectedMsg = context.l10n.phoneVerifyUnexpectedError;
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      _verifiedEmail = email;
      setState(() => _otpSent = true);
      _startResendTimer();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });
    } on AuthException catch (e) {
      _setError(_friendlyError(e.message));
    } catch (e) {
      _setError(unexpectedMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Verificar OTP ─────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_isIndonesia) {
      await _verifyEmailOtp();
    } else {
      await _verifySmsOtp();
    }
  }

  Future<void> _verifySmsOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      _setError(context.l10n.phoneVerifyCodeLength);
      return;
    }
    _setError(null);
    setState(() => _loading = true);
    final unexpectedMsg = context.l10n.phoneVerifyUnexpectedError;
    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: _fullPhone,
        token: code,
        type: OtpType.phoneChange,
      );
      await Supabase.instance.client.auth.refreshSession();
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      _setError(_friendlyError(e.message));
    } catch (e) {
      _setError(unexpectedMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      _setError(context.l10n.phoneVerifyCodeLength);
      return;
    }
    _setError(null);
    setState(() => _loading = true);
    final unexpectedMsg = context.l10n.phoneVerifyUnexpectedError;
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _verifiedEmail,
        token: code,
        type: OtpType.email,
      );
      // Guardar el teléfono en userMetadata para que el gate lo reconozca
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'verified_phone': _fullPhone}),
      );
      await Supabase.instance.client.auth.refreshSession();
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      _setError(_friendlyError(e.message));
    } catch (e) {
      _setError(unexpectedMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    final l = context.l10n;
    if (r.contains('invalid') || r.contains('expired')) {
      return l.phoneVerifyErrorInvalidExpired;
    }
    if (r.contains('rate') || r.contains('limit')) {
      return l.phoneVerifyErrorRateLimit;
    }
    if (r.contains('already') || r.contains('registered') || r.contains('exists') || r.contains('taken')) {
      return l.phoneVerifyErrorAlreadyRegistered;
    }
    if (r.contains('phone') || r.contains('number')) {
      return l.phoneVerifyErrorInvalidPhone;
    }
    if (r.contains('network') || r.contains('connection')) {
      return l.phoneVerifyErrorNetwork;
    }
    return l.phoneVerifyErrorGeneric;
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: const Color(0xFF1A3FCC),
      body: Column(
        children: [
          // ── Header azul ────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1F8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 20),

                    // Ícono animado
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_otpSent),
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: Icon(
                          _otpSent
                              ? Icons.mark_email_read_rounded
                              : Icons.phone_android_rounded,
                          color: Colors.white, size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        key: ValueKey('t$_otpSent$_isIndonesia'),
                        _otpSent
                            ? context.l10n.phoneVerifyTitleOtpSent
                            : _isIndonesia
                                ? context.l10n.phoneVerifyEmailFallbackTitle
                                : context.l10n.phoneVerifyTitleEnterPhone,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w900, letterSpacing: -.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _otpSent
                          ? _isIndonesia
                              ? context.l10n.phoneVerifyEmailFallbackSent(_verifiedEmail)
                              : context.l10n.phoneVerifySubtitleOtpSent(_fullPhone)
                          : _isIndonesia
                              ? context.l10n.phoneVerifyEmailFallbackSubtitle
                              : context.l10n.phoneVerifySubtitlePhone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14, height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Indicador de pasos
                    Row(children: [
                      _StepDot(active: true, done: _otpSent, label: '1'),
                      _StepLine(done: _otpSent),
                      _StepDot(active: _otpSent, done: false, label: '2'),
                      const Spacer(),
                      Text(
                        _otpSent
                            ? context.l10n.phoneVerifyStep2of2
                            : context.l10n.phoneVerifyStep1of2,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // ── Tarjeta blanca ─────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_otpSent) ..._buildPhoneStep(),
                    if (_otpSent)  ..._buildOtpStep(),

                    // ── Error ────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline_rounded,
                              color: Colors.red.shade400, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Botón principal ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : (_otpSent ? _verifyOtp : _sendOtp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3FCC),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF1A3FCC).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_otpSent
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.send_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _otpSent
                                        ? context.l10n.phoneVerifyButtonVerify
                                        : _isIndonesia
                                            ? context.l10n.phoneVerifyButtonSendEmail
                                            : context.l10n.phoneVerifyButtonSend,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // ── Reenviar ─────────────────────────────────
                    if (_otpSent) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: _resendCountdown > 0
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.timer_outlined,
                                    size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 5),
                                Text(
                                  context.l10n.phoneVerifyResendIn(_resendCountdown),
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                              ])
                            : TextButton.icon(
                                onPressed: _loading ? null : () {
                                  _otpCtrl.clear();
                                  setState(() => _otpSent = false);
                                },
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 16),
                                label: Text(context.l10n.phoneVerifyResend),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF1A3FCC)),
                              ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Info privacidad ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.phoneVerifyPrivacyNote,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── Paso 1: número de teléfono ────────────────────────────────────

  List<Widget> _buildPhoneStep() {
    final country = _countries.firstWhere(
        (c) => c.$1 == _countryCode, orElse: () => _countries.first);
    return [
      // Etiqueta
      Text(context.l10n.phoneVerifyLabelPhone,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textoSecundario)),
      const SizedBox(height: 8),

      // Contenedor unificado: país + número
      Container(
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          // Fila del país
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(children: [
                Text(country.$2, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(country.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.textoPrimario, fontSize: 14)),
                const SizedBox(width: 6),
                Text('· ${country.$3}',
                    style: const TextStyle(color: AppColors.textoSecundario,
                        fontSize: 13)),
                const Spacer(),
                Icon(Icons.unfold_more_rounded,
                    color: Colors.grey.shade400, size: 18),
              ]),
            ),
          ),
          // Campo número
          TextField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 15,
            style: const TextStyle(
                color: AppColors.textoPrimario, fontWeight: FontWeight.w600,
                fontSize: 20, letterSpacing: 3),
            decoration: InputDecoration(
              counterText: '',
              hintText: '55 1234 5678',
              hintStyle: TextStyle(color: Colors.grey.shade300,
                  letterSpacing: 1, fontWeight: FontWeight.w400, fontSize: 18),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(Icons.phone_rounded,
                    color: AppColors.azulPrimario, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _isIndonesia ? null : _sendOtp(),
          ),
        ]),
      ),

      // ── Campo de correo (solo Indonesia) ────────────────────────
      if (_isIndonesia) ...[
        const SizedBox(height: 16),
        Text(context.l10n.phoneVerifyEmailFallbackLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fondoElevado,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                color: AppColors.textoPrimario, fontWeight: FontWeight.w500,
                fontSize: 15),
            decoration: InputDecoration(
              hintText: context.l10n.phoneVerifyEmailFallbackHint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(Icons.email_outlined,
                    color: AppColors.azulPrimario, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _sendOtp(),
          ),
        ),
      ],
    ];
  }

  // ── Paso 2: código OTP (6 cajas individuales) ─────────────────────

  List<Widget> _buildOtpStep() {
    final code = _otpCtrl.text;
    return [
      // Etiqueta
      Text(context.l10n.phoneVerifyLabelCode,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textoSecundario)),
      const SizedBox(height: 12),

      // 6 cajas + TextField oculto
      Stack(children: [
        // Campo oculto que captura el input
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _otpCtrl,
            focusNode: _otpFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            onChanged: (v) {
              setState(() {});
              if (v.length == 6) _verifyOtp();
            },
          ),
        ),
        // Cajas visuales
        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_otpFocus),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final filled = i < code.length;
              final active = i == code.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46, height: 56,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.azulPrimario.withValues(alpha: 0.07)
                      : AppColors.fondoElevado,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppColors.azulPrimario
                        : filled
                            ? AppColors.azulPrimario.withValues(alpha: 0.4)
                            : Colors.grey.shade200,
                    width: active ? 2 : 1.5,
                  ),
                  boxShadow: active ? [
                    BoxShadow(
                      color: AppColors.azulPrimario.withValues(alpha: 0.15),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: filled
                      ? Text(code[i],
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: AppColors.textoPrimario,
                          ))
                      : active
                          ? Container(
                              width: 2, height: 22,
                              color: AppColors.azulPrimario,
                            )
                          : null,
                ),
              );
            }),
          ),
        ),
      ]),

      const SizedBox(height: 12),

      // Cambiar número
      Center(
        child: TextButton.icon(
          onPressed: () => setState(() {
            _otpSent = false;
            _otpCtrl.clear();
            _resendTimer?.cancel();
          }),
          icon: Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade500),
          label: Text(context.l10n.phoneVerifyChangeNumber,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
      ),
    ];
  }

  // ── Selector de país ──────────────────────────────────────────────

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fondoElevado,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CountryPickerSheet(
        onSelected: (code) => setState(() => _countryCode = code),
      ),
    );
  }
}

// ── Selector de país con búsqueda ─────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final void Function(String code) onSelected;
  const _CountryPickerSheet({required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<(String, String, String)> _filtered =
      _PhoneVerificationScreenState._countries;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _PhoneVerificationScreenState._countries
          : _PhoneVerificationScreenState._countries
              .where((c) =>
                  c.$3.toLowerCase().contains(query) ||
                  c.$1.contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: maxH,
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Icon(Icons.public_rounded, color: AppColors.azulPrimario, size: 20),
              const SizedBox(width: 8),
              Text(context.l10n.phoneVerifyCountryPickerTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.textoPrimario)),
            ]),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.l10n.phoneVerifyCountrySearch,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                fillColor: Colors.grey.shade100,
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
                        style: TextStyle(color: Colors.grey.shade400)),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      return ListTile(
                        dense: true,
                        leading: Text(c.$2,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(c.$3,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.azulPrimario.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c.$1,
                              style: const TextStyle(
                                  color: AppColors.azulPrimario,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                        onTap: () {
                          widget.onSelected(c.$1);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Indicador de paso ─────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool   active;
  final bool   done;
  final String label;
  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.verdePrimario
        : active
            ? AppColors.azulPrimario
            : Colors.grey.shade200;
    final fg = (done || active) ? Colors.white : Colors.grey.shade400;
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text(label,
                style: TextStyle(
                    color: fg, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: done ? AppColors.verdePrimario : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
