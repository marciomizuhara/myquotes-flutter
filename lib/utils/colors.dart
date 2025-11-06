import 'package:flutter/material.dart';

Color colorByType(dynamic rawType) {
  int toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  final type = toInt(rawType);

  switch (type) {
    case 1:
      return const Color(0xCC5C2C2C); // vinho queimado translúcido
    case 2:
      return const Color(0xCCA88732); // dourado envelhecido translúcido
    case 3:
      return const Color(0xCC2D5F3A); // verde escuro neutro
    case 4:
      return const Color(0xCC2B4962); // azul acinzentado
    case 5:
      return const Color(0xCC27636F); // ciano acinzentado elegante
    case 6:
      return const Color(0xCC5A5A5A); // cinza médio neutro para "quotes de interesse"
    default:
      return const Color(0xCC1E1E1E); // fundo neutro translúcido
  }
}
