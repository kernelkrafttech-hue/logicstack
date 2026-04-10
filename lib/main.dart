import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const ContractionTrackerApp());

class ContractionTrackerApp extends StatelessWidget {
  const ContractionTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContractionTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F2FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// A single recorded contraction.
class Contraction {
  Contraction({
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.gapSeconds,
  });

  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;

  /// Seconds between the previous contraction's end and this one's start.
  /// `null` for the very first contraction in a session.
  final int? gapSeconds;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Contraction> _contractions = <Contraction>[];

  DateTime? _currentStart;
  Timer? _tickTimer;
  int _elapsedSeconds = 0;

  bool get _isActive => _currentStart != null;

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _toggleContraction() {
    if (_isActive) {
      _stopContraction();
    } else {
      _startContraction();
    }
  }

  void _startContraction() {
    final now = DateTime.now();
    setState(() {
      _currentStart = now;
      _elapsedSeconds = 0;
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentStart == null) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_currentStart!).inSeconds;
      });
    });
  }

  void _stopContraction() {
    _tickTimer?.cancel();
    _tickTimer = null;
    final end = DateTime.now();
    final start = _currentStart!;
    final duration = end.difference(start).inSeconds;
    int? gap;
    if (_contractions.isNotEmpty) {
      gap = start.difference(_contractions.last.endTime).inSeconds;
      if (gap < 0) gap = 0;
    }
    setState(() {
      _contractions.add(
        Contraction(
          startTime: start,
          endTime: end,
          durationSeconds: duration,
          gapSeconds: gap,
        ),
      );
      _currentStart = null;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _confirmReset() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text(
            'Reset Session?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'This will clear all recorded contractions. '
            'This action cannot be undone.',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _tickTimer?.cancel();
      _tickTimer = null;
      setState(() {
        _contractions.clear();
        _currentStart = null;
        _elapsedSeconds = 0;
      });
    }
  }

  /// Returns up to the last [count] items from the list.
  List<Contraction> _lastN(int count) {
    if (_contractions.length <= count) return List<Contraction>.from(_contractions);
    return _contractions.sublist(_contractions.length - count);
  }

  /// Average duration (in seconds) of the last 5 contractions.
  double get _avgDurationLast5 {
    final List<Contraction> window = _lastN(5);
    if (window.isEmpty) return 0;
    final int total = window.fold<int>(0, (int sum, Contraction c) => sum + c.durationSeconds);
    return total / window.length;
  }

  /// Average gap (in seconds) between the last 5 contractions.
  /// Excludes any entries whose gap is null (the very first contraction).
  double get _avgGapLast5 {
    final List<Contraction> window = _lastN(5);
    final List<int> gaps = <int>[
      for (final Contraction c in window)
        if (c.gapSeconds != null) c.gapSeconds!,
    ];
    if (gaps.isEmpty) return 0;
    return gaps.fold<int>(0, (int sum, int g) => sum + g) / gaps.length;
  }

  /// 5-1-1 style rule: if the last 3 contractions are each at least 60s long
  /// and the average gap between them is 300s or less, show the alert.
  bool get _shouldShowHospitalAlert {
    if (_contractions.length < 3) return false;
    final List<Contraction> last3 = _lastN(3);
    final bool allLongEnough = last3.every((Contraction c) => c.durationSeconds >= 60);
    if (!allLongEnough) return false;
    final List<int> gaps = <int>[
      for (final Contraction c in last3)
        if (c.gapSeconds != null) c.gapSeconds!,
    ];
    if (gaps.isEmpty) return false;
    final double avgGap = gaps.fold<int>(0, (int sum, int g) => sum + g) / gaps.length;
    return avgGap <= 300;
  }

  String _formatTimeOfDay(DateTime dt) {
    int hour = dt.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAny = _contractions.isNotEmpty || _isActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ContractionTracker'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: hasAny ? _confirmReset : null,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Reset Session',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                disabledForegroundColor: Colors.white54,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_shouldShowHospitalAlert) _buildHospitalAlert(),
            const SizedBox(height: 16),
            _buildLiveTimer(),
            const SizedBox(height: 8),
            _buildStartStopButton(),
            const SizedBox(height: 20),
            _buildSummaryBar(),
            const SizedBox(height: 12),
            Expanded(child: _buildContractionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalAlert() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFC62828),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: const Row(
        children: <Widget>[
          Icon(Icons.local_hospital, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Time to go to the hospital — call your doctor now.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTimer() {
    return SizedBox(
      height: 64,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _isActive
            ? Text(
                '$_elapsedSeconds s',
                key: const ValueKey<String>('active-timer'),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              )
            : const Text(
                'Tap to start',
                key: ValueKey<String>('idle-timer'),
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black54,
                ),
              ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: ElevatedButton(
          onPressed: _toggleContraction,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: _isActive
                ? const Color(0xFFD32F2F)
                : const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: Colors.black45,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _isActive ? 'Stop\nContraction' : 'Start\nContraction',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final bool hasData = _contractions.isNotEmpty;
    final bool hasGap = _contractions.length >= 2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _summaryItem(
            label: 'Avg duration',
            value: hasData ? '${_avgDurationLast5.round()} s' : '—',
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.deepPurple.shade100,
          ),
          _summaryItem(
            label: 'Avg gap',
            value: hasGap ? '${_avgGapLast5.round()} s' : '—',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const Text(
          '(last 5)',
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildContractionList() {
    if (_contractions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No contractions yet.\nTap the button above when one begins.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _contractions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        // Show newest first.
        final int originalIndex = _contractions.length - 1 - index;
        final Contraction c = _contractions[originalIndex];
        final int number = originalIndex + 1;
        final String gapText = c.gapSeconds == null
            ? 'First contraction'
            : 'Gap: ${c.gapSeconds} s';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            _formatTimeOfDay(c.startTime),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Duration: ${c.durationSeconds} s    •    $gapText',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        );
      },
    );
  }
}
