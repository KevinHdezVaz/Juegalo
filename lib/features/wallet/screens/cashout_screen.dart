import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CashoutScreen extends StatelessWidget {
  const CashoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Solicitar cobro'),
        backgroundColor: AppColors.fondoPrincipal,
      ),
      body: const Center(
        child: Text('Formulario de cobro — próximamente',
            style: TextStyle(color: AppColors.textoSecundario)),
      ),
    );
  }
}
