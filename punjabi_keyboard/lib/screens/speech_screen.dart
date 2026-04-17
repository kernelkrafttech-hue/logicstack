import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/speech_service.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final _service = SpeechService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _service.init();
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _service.stop();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listening = _service.listening;
    final transcript = _service.transcript;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk → Punjabi'),
        actions: [
          if (transcript.isNotEmpty)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: transcript));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              },
            ),
          if (transcript.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: _service.clear,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_service.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _service.error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    transcript.isEmpty
                        ? 'ਮਾਈਕ ਦਬਾਓ ਅਤੇ ਪੰਜਾਬੀ ਵਿੱਚ ਬੋਲੋ…\n(Tap the mic and speak in Punjabi.)'
                        : transcript,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 56),
                backgroundColor: listening ? theme.colorScheme.error : null,
              ),
              icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(listening ? 'Stop' : 'Start speaking'),
              onPressed: () =>
                  listening ? _service.stop() : _service.start(),
            ),
          ],
        ),
      ),
    );
  }
}
