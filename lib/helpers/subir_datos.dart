import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';

Future<void> subirData(BuildContext context, List<AspiranteRecord> registrosEscaneados, {required VoidCallback onStart, required VoidCallback onEnd}) async {
  
  if (registrosEscaneados.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay registros para subir')),
    );
    return;
  }

  // 1. Recuperar últimos datos usados
  final prefs = await SharedPreferences.getInstance();
  String lastUrl = prefs.getString('api_url') ?? '';
  String lastClave = prefs.getString('api_clave') ?? '';

  final TextEditingController urlController = TextEditingController(text: lastUrl);
  final TextEditingController claveController = TextEditingController(text: lastClave);

  // 2. Mostrar Modal
  bool? confirmar = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Subir al Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Endpoint',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: claveController,
              decoration: const InputDecoration(
                labelText: 'Clave de Acceso',
              ),
              obscureText: true, 
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Subir Datos', style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );

  if (confirmar == true) {
    final url = urlController.text.trim();
    final clave = claveController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL no puede estar vacía')),
      );
      return;
    }

    // Activar estado de carga (asegúrate de tener _isScanning o una variable similar)
    onStart();

    try {
      await prefs.setString('api_url', url);
      await prefs.setString('api_clave', clave);     

      final dataList = registrosEscaneados.map((r) => {
        'cedula': r.cedula,
        'notas': jsonEncode(r.notas.map(
          (key, value) => MapEntry(key.toString(), value)
        )), 
        'createdAt': r.createdAt.toIso8601String(),
      }).toList();

      final payload = {
        'clave': clave,
        'data': dataList,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!context.mounted) return;

      String mensaje = '';
      Color colorFondo = Colors.grey;

      try {
        final Map<String, dynamic> bodyDecodificado = jsonDecode(response.body);
        
        mensaje = bodyDecodificado['message'] ?? bodyDecodificado['error'] ?? 'Sin mensaje del servidor';
        
      } catch (e) {
        mensaje = 'Respuesta no válida del servidor. Código: ${response.statusCode}';
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        colorFondo = Colors.green;
      } else {
        colorFondo = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: colorFondo,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      onEnd();
    }
  }
}