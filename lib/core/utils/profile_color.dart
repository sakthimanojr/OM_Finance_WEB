import 'package:flutter/material.dart';

/// Day-of-the-week profile colors as requested:
/// - Monday: Pink
/// - Tuesday: Green
/// - Wednesday: Brown
/// - Thursday: Orange
/// - Friday: Sky Blue
/// - Saturday: Red
/// - Sunday: Black
class ProfileDayColor {
  ProfileDayColor._();

  static const Color monday = Color(0xFFE91E63);    // Pink
  static const Color tuesday = Color(0xFF2E7D32);   // Green
  static const Color wednesday = Color(0xFF795548); // Brown
  static const Color thursday = Color(0xFFFF9800);  // Orange
  static const Color friday = Color(0xFF03A9F4);    // Sky Blue
  static const Color saturday = Color(0xFFE53935);  // Red
  static const Color sunday = Color(0xFF212121);    // Black

  /// Resolves the color based on the given [DateTime]'s day of the week.
  static Color forDateTime(DateTime? dateTime) {
    if (dateTime == null) return monday;
    switch (dateTime.weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return monday;
    }
  }

  /// Returns the day name (e.g., "Monday", "Tuesday").
  static String dayName(DateTime? dateTime) {
    if (dateTime == null) return 'Monday';
    switch (dateTime.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  /// Short day abbreviation (e.g. "Mon", "Tue").
  static String shortDay(DateTime? dateTime) {
    if (dateTime == null) return 'Mon';
    switch (dateTime.weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Mon';
    }
  }
}
