import 'dart:convert';

class AspirantePromedio {
  final int? id; 
  final int cedula;
  final double promedioGeneral;
  final Map<int, List<int>> notas;
  final Map<int, double> promedios;
  final DateTime createdAt;

  AspirantePromedio({
    this.id,
    required this.cedula,
    required this.promedios,
    required this.notas,
    required this.promedioGeneral,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedula': cedula,
      'promedios': jsonEncode(promedios), 
      'notas': jsonEncode(notas),         
      'promedio_general': promedioGeneral,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AspirantePromedio.fromMap(Map<String, dynamic> map) {

    final Map<String, dynamic> rawNotas = jsonDecode(map['notas'] as String);
    final Map<int, List<int>> parsedNotas = rawNotas.map(
      (key, value) => MapEntry(
        int.parse(key), 
        (value as List).map((e) => e as int).toList(),
      ),
    );

    final Map<String, dynamic> rawPromedios = jsonDecode(map['promedios'] as String);
    final Map<int, double> parsedPromedios = rawPromedios.map(
      (key, value) => MapEntry(
        int.parse(key), 
        (value as num).toDouble(),
      ),
    );

    return AspirantePromedio(
      id: map['id'] as int?,
      cedula: map['cedula'] as int,
      promedioGeneral: (map['promedio_general'] as num).toDouble(),
      notas: parsedNotas,
      promedios: parsedPromedios,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}