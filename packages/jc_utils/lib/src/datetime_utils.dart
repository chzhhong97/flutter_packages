class DatetimeUtils{
  DatetimeUtils._internal();

  // Define time conversions
  static const int millisInSecond = 1000;
  static const int secondsInMinute = 60;
  static const int minutesInHour = 60;
  static const int hoursInDay = 24;
  static const int daysInMonth = 30;  // Approximation
  static const int monthsInYear = 12;

  static String convertTime(int value, TimeUnitEnum fromType, Set<TimeUnitEnum> range, {bool showFull = false}) {

    // Calculate time components from smallest to largest
    int years = 0, months = 0, days = 0, hours = 0, minutes = 0, seconds = 0, milliseconds = 0;

    switch (fromType) {
      case TimeUnitEnum.milliseconds:
        seconds = value ~/ Duration.millisecondsPerSecond;
        milliseconds = value % Duration.millisecondsPerSecond;
        value = seconds;
    // fall-through
      case TimeUnitEnum.seconds:
        minutes = value ~/ Duration.secondsPerMinute;
        seconds = value % Duration.secondsPerMinute;
        value = minutes;
    // fall-through
      case TimeUnitEnum.minutes:
        hours = value ~/ Duration.minutesPerHour;
        minutes = value % Duration.minutesPerHour;
        value = hours;
    // fall-through
      case TimeUnitEnum.hours:
        days = value ~/ Duration.hoursPerDay;
        hours = value % Duration.hoursPerDay;
        value = days;
    // fall-through
      case TimeUnitEnum.days:
        months = value ~/ daysInMonth;
        days = value % daysInMonth;
        value = months;
    // fall-through
      case TimeUnitEnum.months:
        years = value ~/ monthsInYear;
        months = value % monthsInYear;
      default:
    }

    // Build the formatted string based on range and calculated values
    String result = '';
    if (range.contains(TimeUnitEnum.years) && years > 0) result += '$years${TimeUnitEnum.years.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.months) && months > 0) result += '$months${TimeUnitEnum.months.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.days) && days > 0) result += '$days${TimeUnitEnum.days.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.hours) && hours > 0) result += '$hours${TimeUnitEnum.hours.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.minutes) && minutes > 0) result += '$minutes${TimeUnitEnum.minutes.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.seconds) && seconds > 0) result += '$seconds${TimeUnitEnum.seconds.getName(short: !showFull)} ';
    if (range.contains(TimeUnitEnum.milliseconds) && milliseconds > 0) result += '$milliseconds${TimeUnitEnum.milliseconds.getName(short: !showFull)} ';

    return result.trim();
  }
}

enum TimeUnitEnum{
  milliseconds("milliseconds", "ms"),
  seconds("seconds", "s"),
  minutes("minutes", "min"),
  hours("hours", "h"),
  days("days", "d"),
  months("months", "mo"),
  years("years", "y");

  final String full;
  final String short;

  String getName({bool short = false}) => short ? this.short : full;

  const TimeUnitEnum(this.full, this.short);
}