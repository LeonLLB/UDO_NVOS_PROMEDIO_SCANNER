

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
    String notasJson = jsonEncode(registro.notas); 
    
    filas.add([
      registro.cedula,
      notasJson,
      registro.createdAt.toIso8601String()
    ]);
  }

  // 3. Convertir a String CSV
  String csv = const ListToCsvConverter().convert(filas);

  // 4. Guardar en un archivo temporal
  final directorio = await getTemporaryDirectory();
  final rutaArchivo = '${directorio.path}/aspirantes_escaneados.csv';
  final archivo = File(rutaArchivo);
  
  await archivo.writeAsString(csv);

  // 5. Compartir el archivo
  if (context.mounted) {
    await SharePlus.instance.share(
      [XFile(rutaArchivo)], 
      text: 'Aquí están los registros escaneados de los aspirantes.',
    );
  }

}