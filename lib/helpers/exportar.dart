

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';

Future<void> exportarCsv(BuildContext context, List<AspiranteRecord> registrosEscaneados) async {

  if (registrosEscaneados.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay registros para exportar')),
    );
    return;
  }

  // 1. Crear las cabeceras del CSV
  List<List<dynamic>> filas = [
    ['Cédula', 'Notas (JSON)', 'Fecha de Escaneo']
  ];

  // 2. Llenar los datos
  for (var registro in registrosEscaneados) {
    final notasConvertidas = registro.notas.map(
      (key, value) => MapEntry(key.toString(), value)
    );
    
    String notasJson = jsonEncode(notasConvertidas);
    
    filas.add([
      registro.cedula,
      notasJson,
      registro.createdAt.toIso8601String()
    ]);
  }

  String csv = Csv.excel().encode(filas);

  final directorio = await getTemporaryDirectory();
  final rutaArchivo = '${directorio.path}/aspirantes_escaneados.csv';
  final archivo = File(rutaArchivo);
  
  await archivo.writeAsString(csv);

  if (context.mounted) {
  await SharePlus.instance.share(
    ShareParams( files: [XFile(rutaArchivo)])
  );
}

}