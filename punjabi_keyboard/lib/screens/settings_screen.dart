import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kVibrate = 'setting_vibrate';
  static const _kSound = 'setting_sound';
  static const _kAutoCap = 'setting_auto_cap';
  static const _kNumRow = 'setting_number_row';

  bool _vibrate = true;
  bool _sound = false;
  bool _autoCap = true;
  bool _numRow = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _vibrate = p.getBool(_kVibrate) ?? true;
      _sound = p.getBool(_kSound) ?? false;
      _autoCap = p.getBool(_kAutoCap) ?? true;
      _numRow = p.getBool(_kNumRow) ?? true;
    });
  }

  Future<void> _set(String k, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        SwitchListTile(
          title: const Text('Vibrate on key press'),
          value: _vibrate,
          onChanged: (v) {
            setState(() => _vibrate = v);
            _set(_kVibrate, v);
          },
        ),
        SwitchListTile(
          title: const Text('Key-press sound'),
          value: _sound,
          onChanged: (v) {
            setState(() => _sound = v);
            _set(_kSound, v);
          },
        ),
        SwitchListTile(
          title: const Text('Auto-capitalize (English mode)'),
          value: _autoCap,
          onChanged: (v) {
            setState(() => _autoCap = v);
            _set(_kAutoCap, v);
          },
        ),
        SwitchListTile(
          title: const Text('Show number row'),
          value: _numRow,
          onChanged: (v) {
            setState(() => _numRow = v);
            _set(_kNumRow, v);
          },
        ),
        const Divider(),
        const AboutListTile(
          applicationName: 'ਪੰਜਾਬੀ Keyboard',
          applicationVersion: '0.1.0',
          icon: Icon(Icons.info_outline),
        ),
      ]),
    );
  }
}
