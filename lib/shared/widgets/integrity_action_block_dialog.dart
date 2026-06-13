import 'package:flutter/material.dart';
import '../../core/utils/l10n_ext.dart';

/// Dialog que se muestra cuando Play Integrity rechaza una acción crítica
/// (cobro o daily bonus). Mismo estilo "autoritativo" del PayPal duplicado.
class IntegrityActionBlockDialog extends StatelessWidget {
  const IntegrityActionBlockDialog({super.key});

  /// Atajo para mostrar el dialog.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final scale = Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(anim);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: scale,
            child: const IntegrityActionBlockDialog(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F1330), Color(0xFF14091F)],
                ),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.55),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    blurRadius: 45,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con franja roja
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFDC2626).withValues(alpha: 0.20),
                          const Color(0xFF7F1D1D).withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Badge "BLOQUEO DE SEGURIDAD"
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(100),
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
                              const SizedBox(width: 6),
                              Text(
                                l.integrityBlockBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(0xFFDC2626),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.do_not_disturb_on_rounded,
                            color: Color(0xFFFCA5A5),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.integrityBlockTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.integrityBlockReason,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.policy_outlined,
                                    color: Color(0xFFFCA5A5),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.integrityBlockPolicy,
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.integrityBlockPolicyDesc,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFFDC2626),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            l.integrityBlockConsequence,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l.integrityBlockClose,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
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
      ),
    );
  }
}
