import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

abstract final class NumberFormatter {
  static String formatMontant(
    double valeur,
    String deviseCode, [
    Locale locale = const Locale('fr', 'FR'),
  ]) {
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: deviseCode == 'XOF' || deviseCode == 'XAF' ? 'FCFA' : '€',
      decimalDigits: (deviseCode == 'XOF' || deviseCode == 'XAF') ? 0 : 2,
    );
    return format.format(valeur);
  }

  static String formatQuantite(
    double valeur, [
    Locale locale = const Locale('fr', 'FR'),
    int fractionDigits = 2,
  ]) {
    final format = NumberFormat.decimalPattern(locale.toString())
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = fractionDigits;
    return format.format(valeur);
  }

  static String formatPourcentage(double ratio) {
    return '${(ratio * 100).toStringAsFixed(0)} %';
  }
}
