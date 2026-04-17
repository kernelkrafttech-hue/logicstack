import 'package:flutter/material.dart';

import '../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // In-app-purchase wiring is scaffolded — product id must exist in Play
  // Console before a real purchase flow can succeed. For now, a simple toggle
  // lets QA exercise the premium vs free UI without Play billing.
  static const _productId = 'punjabi_keyboard_premium';

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService.instance;
    return AnimatedBuilder(
      animation: premium,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Premium')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premium.isPremium ? 'You are premium' : 'Go Premium',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const _Bullet('No ads, anywhere in the app'),
                      const _Bullet('Extra keyboard themes'),
                      const _Bullet('Priority sticker packs'),
                      const _Bullet('Unlimited speech-to-text length'),
                      const SizedBox(height: 16),
                      if (!premium.isPremium)
                        FilledButton(
                          onPressed: () => _purchase(context),
                          child: const Text('Unlock for \$2.99'),
                        )
                      else
                        OutlinedButton(
                          onPressed: () => premium.setPremium(false),
                          child: const Text('Disable (debug)'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Product id: $_productId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _purchase(BuildContext context) async {
    // TODO: replace with real in_app_purchase flow.
    await PremiumService.instance.setPremium(true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium unlocked (debug)')),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
