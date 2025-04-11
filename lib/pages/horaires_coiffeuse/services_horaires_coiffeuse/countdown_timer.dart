// import 'dart:async';
// import 'package:flutter/material.dart';
//
// class CountdownTimerWidget extends StatefulWidget {
//   final DateTime targetTime;
//
//   const CountdownTimerWidget({Key? key, required this.targetTime}) : super(key: key);
//
//   @override
//   _CountdownTimerWidgetState createState() => _CountdownTimerWidgetState();
// }
//
// class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
//   late Duration _timeLeft;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
//   }
//
//   void _updateTime() {
//     final now = DateTime.now();
//     final newTime = widget.targetTime.difference(now);
//     if (newTime.isNegative) {
//       _timer?.cancel();
//     }
//     setState(() {
//       _timeLeft = newTime;
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   String format(Duration d) {
//     final hours = d.inHours;
//     final minutes = d.inMinutes % 60;
//     final seconds = d.inSeconds % 60;
//     if (d.isNegative) return "⏰ Terminé";
//     return "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isUrgent = _timeLeft.inMinutes <= 30 && !_timeLeft.isNegative;
//     final isToday = widget.targetTime.day == DateTime.now().day;
//
//     Color color;
//     if (_timeLeft.isNegative) {
//       color = Colors.grey;
//     } else if (isUrgent) {
//       color = Colors.red;
//     } else if (isToday) {
//       color = Colors.orange;
//     } else {
//       color = Colors.green;
//     }
//
//     return Padding(
//       padding: const EdgeInsets.only(right: 6), // 👈 espace entre le bord droit
//       child: SizedBox(
//         width: 72, // 👌 un peu plus compact
//         height: 44, // ⬇️ réduit pour éviter overflow
//         child: FittedBox(
//           fit: BoxFit.scaleDown,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.timer, size: 18, color: color),
//               const SizedBox(height: 2),
//               Text(
//                 format(_timeLeft),
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: color,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
// }
