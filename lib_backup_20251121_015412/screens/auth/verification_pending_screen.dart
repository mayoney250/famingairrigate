import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/l10n_extensions.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.accountVerification),
<<<<<<< HEAD
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.offAllNamed('/')),
=======
        automaticallyImplyLeading: false,
>>>>>>> 2ea7d6eeb20bbc31d75fb4a5e80bb55b84fa95a4
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top, size: 72, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                context.l10n.verificationPendingTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.verificationPendingMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
