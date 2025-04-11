import 'dart:async';
import 'dart:ui'; // pour FontFeature
import 'package:flutter/material.dart';

class CountdownBoxTimer extends StatefulWidget {
  final DateTime targetTime;

  const CountdownBoxTimer({Key? key, required this.targetTime}) : super(key: key);

  @override
  State<CountdownBoxTimer> createState() => _CountdownBoxTimerState();
}

class _CountdownBoxTimerState extends State<CountdownBoxTimer> {
  late Duration remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      remaining = widget.targetTime.difference(now).isNegative
          ? Duration.zero
          : widget.targetTime.difference(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.deepPurple.shade600]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return SizedBox(
      width: 200,
      height: 70,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildTimeBox(days.toString().padLeft(2, '0'), "Jours"),
            const SizedBox(width: 6),
            buildTimeBox(hours.toString().padLeft(2, '0'), "Heures"),
            const SizedBox(width: 6),
            buildTimeBox(minutes.toString().padLeft(2, '0'), "Min"),
            const SizedBox(width: 6),
            buildTimeBox(seconds.toString().padLeft(2, '0'), "Sec"),
          ],
        ),
      ),
    );
  }
}
