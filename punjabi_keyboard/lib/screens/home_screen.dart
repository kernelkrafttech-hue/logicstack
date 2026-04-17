import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../services/keyboard_channel.dart';
import '../services/premium_service.dart';
import 'emoji_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'speech_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _enabled = false;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    PremiumService.instance.addListener(_onPremium);
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_onPremium);
    super.dispose();
  }

  void _onPremium() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshStatus() async {
    try {
      final e = await KeyboardChannel.isKeyboardEnabled();
      final s = await KeyboardChannel.isKeyboardSelected();
      if (!mounted) return;
      setState(() {
        _enabled = e;
        _selected = s;
      });
    } catch (_) {
      // Method channel only exists on Android; ignore elsewhere.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ਪੰਜਾਬੀ Keyboard'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SetupCard(
              enabled: _enabled,
              selected: _selected,
              onChanged: _refreshStatus,
            ),
            const SizedBox(height: 16),
            _FeatureTile(
              icon: Icons.mic_rounded,
              title: 'Talk → Punjabi text',
              subtitle: 'Speak in Punjabi and convert to Gurmukhi text',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SpeechScreen()),
              ),
            ),
            _FeatureTile(
              icon: Icons.emoji_emotions_outlined,
              title: 'Punjabi Emojis & Stickers',
              subtitle: 'Browse food, festivals, and Gurmukhi stickers',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmojiScreen()),
              ),
            ),
            _FeatureTile(
              icon: Icons.workspace_premium_outlined,
              title: PremiumService.instance.isPremium
                  ? 'Premium: Active'
                  : 'Go Premium – remove ads',
              subtitle: 'Disable ads and unlock extras',
              color: theme.colorScheme.primaryContainer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.enabled,
    required this.selected,
    required this.onChanged,
  });

  final bool enabled;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Setup', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _StepRow(
              step: 1,
              done: enabled,
              text: 'Enable in system settings',
              cta: 'Open settings',
              onTap: () async {
                await KeyboardChannel.openKeyboardSettings();
                onChanged();
              },
            ),
            _StepRow(
              step: 2,
              done: selected,
              text: 'Select Punjabi Keyboard',
              cta: 'Choose keyboard',
              onTap: () async {
                await KeyboardChannel.showInputMethodPicker();
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.done,
    required this.text,
    required this.cta,
    required this.onTap,
  });

  final int step;
  final bool done;
  final String text;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: done
                ? const Icon(Icons.check, size: 16)
                : Text('$step', style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          TextButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
