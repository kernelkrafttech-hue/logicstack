import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/punjabi_emojis.dart';

class EmojiScreen extends StatelessWidget {
  const EmojiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Punjabi Emojis'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Expressions'),
            Tab(text: 'Culture'),
            Tab(text: 'Food'),
            Tab(text: 'Stickers'),
          ]),
        ),
        body: TabBarView(children: [
          _EmojiGrid(items: PunjabiEmojis.expressions),
          _EmojiGrid(items: PunjabiEmojis.culture),
          _EmojiGrid(items: PunjabiEmojis.food),
          _EmojiGrid(items: PunjabiEmojis.stickers, textSticker: true),
        ]),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.items, this.textSticker = false});

  final List<String> items;
  final bool textSticker;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: textSticker ? 180 : 72,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: textSticker ? 2.6 : 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final value = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied: $value')),
            );
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: textSticker ? 18 : 32),
            ),
          ),
        );
      },
    );
  }
}
