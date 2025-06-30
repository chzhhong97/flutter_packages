import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jc_utils/src/print_color.dart';

extension DateOnlyCompare on DateTime{
  bool isSameDate(DateTime other){
    return year == other.year && month == other.month && day == other.day;
  }
  
  DateTime getDateOnly(){
    return DateTime(year, month, day);
  }

  String toStringFormat(String format){
    try{
      return DateFormat(format).format(this);
    }
    catch(e){
      return toString();
    }

  }
}

extension FancyIterable on Iterable<int> {
  int get largest => reduce(math.max);

  int get smallest => reduce(math.min);
}

extension DateTimeExt on DateTime{
  bool isAfterTime(DateTime other) => timeInSecond > other.timeInSecond;

  bool isBeforeTime(DateTime other) => timeInSecond < other.timeInSecond;

  int get timeInSecond => (((hour * 60) + minute) * 60) + second;
}


extension DecimalEx on double{
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
  String toCommasFormat() {
    return NumberFormat.decimalPattern().format(this);
  }

  int toIntWithDecimal(int decimalPlace){
    return (this * math.pow(10, 2)).toInt();
  }
}

extension JsonPrinterExtension on Object{

  void printJson({PrintColor color = PrintColor.green, void Function(String msg)? print}) {
    var printMsg = print ?? (msg) => debugPrint(msg);
    try {

      dynamic jsonMap;
      if (this is Map || this is List) {
        jsonMap = this;
      } else {
        jsonMap = (this as dynamic).toJson();
      }
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(jsonMap);
      printMsg("$color======Json Model======");
      prettyJson.split('\n').forEach(printMsg);
      printMsg("======================${PrintColor.reset}");
    } catch (e) {
      printMsg('Error: Object does not have a toJson method');
    }
  }
}

extension ColorExtension on Color{
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}