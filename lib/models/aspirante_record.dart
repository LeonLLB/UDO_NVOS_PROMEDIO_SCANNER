import 'dart:convert';

class AspiranteRecord {
  final int? id; 
  final int cedula;
  final Map<int, List<int>> notas;
  final DateTime createdAt;

  AspiranteRecord({
    this.id,
    required this.cedula,
    required this.notas,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedula': cedula,
      'notas': jsonEncode(notas),       
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    final Map<String, dynamic> notasParaJson = notas.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    
    return "CEDULA: $cedula - NOTAS ${jsonEncode(notasParaJson)}";
  }

  factory AspiranteRecord.fromMap(Map<String, dynamic> map) {

    final Map<String, dynamic> rawNotas = jsonDecode(map['notas'] as String);
    final Map<int, List<int>> parsedNotas = rawNotas.map(
      (key, value) => MapEntry(
        int.parse(key), 
        (value as List).map((e) => e as int).toList(),
      ),
    );

    return AspiranteRecord(
      id: map['id'] as int?,
      cedula: map['cedula'] as int,
      notas: parsedNotas,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.now(),
    );
  }
}