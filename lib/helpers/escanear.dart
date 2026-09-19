import 'dart:ui';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';

Future<Map<String,dynamic>> irAEscanear() async {

  try {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return {'success': false,"msg":"Operación abortada"}; 
    }

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    String textoCrudo = recognizedText.text;

    String textoLimpio = textoCrudo.toLowerCase()
    .replaceAll('\n', ' ')
    .replaceAll(RegExp(r'\s+'), ' '); 

    List<String> palabrasClave = [
      "zona educativa",
      "emite la certificaci",
      "pensum de estudio",
      "plan de estudio",
      "planteles donde",
      "asignaturas",
      "año o grado"
      "año"
    ];

    int coincidencias = 0;
    for (String palabra in palabrasClave) {
      if (textoLimpio.contains(palabra)) {
        coincidencias++;
      }
    }

    if (coincidencias < 2) {
        return {'success': false,"msg":"No es una nota certificada válida"}; 
      }

      RegExp regexCedula = RegExp(r'[vve]\s*[-_.:]?\s*([0-9]{6,8})', caseSensitive: false);
      Match? matchCedula = regexCedula.firstMatch(textoLimpio);
      
    if (matchCedula == null) {
        return {'success': false,"msg":"No se ha detectado una cédula de identidad"}; 
    }
      
    int cedulaExtraida = int.parse(matchCedula.group(1)!);

      List<Map<String, dynamic>> coordenadasAnios = [];
      List<Map<String, dynamic>> notasEncontradas = [];

      final mapNotasRegEx = {
        r'\bdiez\b': 10, r'\bonce\b': 11, r'\bdoce\b': 12, r'\btrece\b': 13, r'\bcatorce\b': 14,
        r'\bquince\b': 15, r'\bdiecis[eé]is\b|\bdieci\s*s[eé]is\b': 16, r'\bdiecisiete\b|\bdieci\s*siete\b': 17,
        r'\bdieciocho\b|\bdieci\s*ocho\b': 18, r'\bdiecinueve\b|\bdieci\s*nueve\b': 19, r'\bveinte\b': 20
      };

      int? determinarAnio(String texto) {
        if (texto.contains("primer") || texto.contains("séptim") || texto.contains("septim")) return 1;
        if (texto.contains("segund") || texto.contains("octav")) return 2;
        if (texto.contains("tercer") || texto.contains("noven")) return 3;
        if (texto.contains("cuart") || texto.contains("1er ciclo") || texto.contains("1 ciclo") || texto.contains("ciclo diversificado")) return 4;
        if (texto.contains("quint") || texto.contains("2do ciclo") || texto.contains("2 ciclo")) return 5;
        return null;
      }

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String textoLinea = line.text.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), ' ');
          textoLinea = textoLinea.replaceAll(RegExp(r'\s+'), ' '); 
          
          int? anioDetectado = determinarAnio(textoLinea);
          if (anioDetectado != null && textoLinea.length < 50) {
            coordenadasAnios.add({'anio': anioDetectado, 'rect': line.boundingBox});
          }

          mapNotasRegEx.forEach((regexString, valorNota) {
            Iterable<RegExpMatch> matches = RegExp(regexString).allMatches(textoLinea);
            for (var match in matches) {
              notasEncontradas.add({'valor': valorNota, 'rect': line.boundingBox});
            }
          });
        }
      }

      Map<int, List<int>> notasPorAno = {1: [], 2: [], 3: [], 4: [], 5: []};

      for (var nota in notasEncontradas) {
        final rectNota = nota['rect'];
        Map<String, dynamic>? anioAsignado;
        double menorDistancia = double.infinity;

        for (var anio in coordenadasAnios) {
          final rectAnio = anio['rect'];
          
          if (rectAnio.bottom <= rectNota.bottom + 30) { 
            double dx = (rectAnio.center.dx - rectNota.center.dx).abs();
            double dy = (rectNota.center.dy - rectAnio.center.dy).abs();
            double distancia = (dx * 10) + dy;
            
            if (distancia < menorDistancia) {
              menorDistancia = distancia;
              anioAsignado = anio;
            }
          }
        }

        if (anioAsignado != null) {
          notasPorAno[anioAsignado['anio']]!.add(nota['valor']);
        }
      }

      notasPorAno.removeWhere((key, value) => value.isEmpty);

      final nuevoAspirante = AspiranteRecord(
        cedula: cedulaExtraida,
        notas: notasPorAno,
        createdAt: DateTime.now(),
      );

      return {
        'success': true,
        'aspirante': nuevoAspirante
      };

    } catch (e) {
      print("Error en el escaneo: $e");
      return {'success': false,"msg":"Error al escanear"};
    }

  
}