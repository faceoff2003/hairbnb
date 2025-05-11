// 📁 lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  // Formatage simple de date (jour/mois/année)
  static String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  // Formatage de date avec heure
  static String formatDateWithTime(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  // Extraction de la partie date uniquement (sans heure)
  static String getDateOnly(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  // Formatage relatif (aujourd'hui, demain, dans X jours, etc.)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) {
      return "Aujourd'hui";
    } else if (difference == 1) {
      return "Demain";
    } else if (difference == -1) {
      return "Hier";
    } else if (difference > 1 && difference < 7) {
      return "Dans $difference jours";
    } else if (difference < 0 && difference > -7) {
      return "Il y a ${-difference} jours";
    } else {
      return formatDate(date);
    }
  }

  // Formatage pour l'affichage des durées
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return "$minutes min";
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? "${hours}h ${mins}min" : "${hours}h";
    }
  }
}