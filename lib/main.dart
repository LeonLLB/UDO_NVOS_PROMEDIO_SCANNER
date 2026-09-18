import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';
import 'helpers/escanear.dart';

void main() {
  runApp(const EscanerNotasApp());
}

void escanearYGuardar(BuildContext context) async {
  final resultado = await irAEscanear();
  
  if (resultado['success'] == true) {
    AspiranteRecord aspirante = resultado['aspirante'];
    
    print(aspirante);
    
  } else {

    // 3. Manejo de nulos por si resultado["msg"] no existe
    final String text = resultado["msg"] ?? "No se pudo leer el documento correctamente.";
    
    // 4. Se eliminó el 'const' porque 'text' es dinámico
    final snackBar = SnackBar(content: Text(text)); 
    
    // 5. Buena práctica en Flutter: verificar si el widget sigue en pantalla después de un await
    if (!context.mounted) return; 
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

  }
}

class EscanerNotasApp extends StatelessWidget {
  const EscanerNotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner de Notas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final List<AspiranteRecord> registrosEscaneados = [
    AspiranteRecord(id: 1,cedula: 28724030, notas: {1:[16,18,16,19,20,21,20],2:[20,16,19,19,18,20,16],3:[20,16,19,19,18,20,16,19],4:[18,19,16,14,20,14,20]}, createdAt: DateTime(2026,2,2)),
    AspiranteRecord(id: 2,cedula: 26117705, notas: {1:[16,18,16,19,20,21,20],2:[20,16,19,19,18,20,16],3:[20,16,19,19,18,20,16,19],4:[18,19,16,14,20,14,20]}, createdAt: DateTime(2026,2,2)),
  ];

  bool _menuAbierto = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros Académicos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: registrosEscaneados.length,
        itemBuilder: (context, index) {
          final registro = registrosEscaneados[index];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.person),
              title: Text(
                'Cédula: V-${registro.cedula}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Lo que va dentro de 'children' es lo que se muestra al expandir
              children: [
                const Divider(),
                ...registro.notas.entries.map((nota) {
                  return ListTile(
                    dense: true,
                    title: Text('Nota de ${nota.key}° Año - Cant. ${nota.value.length} '),
                    trailing: Text(
                      nota.value.join(", ").toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      // El Floating Action Button (FAB)
     floatingActionButton: SpeedDial(
      icon: Icons.menu,              // Icono cuando está cerrado
      activeIcon: Icons.close,       // Icono cuando está abierto
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,           // Oscurece un poco el fondo al abrir
      spacing: 12,                   // Espacio entre los botones flotantes
      spaceBetweenChildren: 8,
      children: [
        // 1. Botón de Exportar CSV
        SpeedDialChild(
          child: const Icon(Icons.share, color: Colors.white),
          backgroundColor: Colors.green,
          label: 'Exportar CSV',
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: () {
            // _exportarCSV();
          },
        ),

        // 2. Botón de Limpiar Base de Datos
        SpeedDialChild(
          child: const Icon(Icons.delete_sweep, color: Colors.white),
          backgroundColor: Colors.redAccent,
          label: 'Limpiar Base de Datos',
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: () {
           // _confirmarLimpiarBaseDatos();
          },
        ),

        // 3. Botón de Escanear
        SpeedDialChild(
          child: const Icon(Icons.camera_alt, color: Colors.white),
          backgroundColor: Colors.blueAccent,
          label: 'Escanear',
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: () {
            escanearYGuardar(context);
          },
        ),
      ],
    ),
  );
  }
}