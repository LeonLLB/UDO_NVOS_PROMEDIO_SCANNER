// Archivo: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/aspirante_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Datos de prueba (dummy data) simulando lo que vendrá de SQLite
  final List<AspiranteRecord> _aspirantes = [
    AspiranteRecord(
      id: 1,
      cedula: 30123456,
      notas: {
        1: [18, 19, 20, 17],
        2: [17, 18, 19, 18, 20],
        3: [19, 20, 18],
        4: [18, 17, 19, 20],
      },
      createdAt: DateTime.now(),
    ),
    AspiranteRecord(
      id: 2,
      cedula: 29876543,
      notas: {
        1: [15, 14, 16],
        2: [16, 15, 15],
        3: [14, 16, 17],
        4: [16, 15, 14],
      },
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros Escaneados', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _aspirantes.isEmpty
          ? const Center(child: Text('No hay registros. ¡Escanea uno nuevo!'))
          : ListView.builder(
              itemCount: _aspirantes.length,
              itemBuilder: (context, index) {
                final aspirante = _aspirantes[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.person),
                    ),
                    title: Text(
                      'C.I: ${aspirante.cedula}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                    
                    // Aquí iteramos sobre los años para crear la lista interna
                    children: aspirante.notas.keys.map((anio) {
                      return Container(
                        color: Colors.grey.withOpacity(0.05), // Fondo sutil para diferenciar
                        child: ListTile(
                          title: Text('Año $anio de Bachillerato', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Notas: ${aspirante.notas[anio]?.join(', ')}'),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              'Notas: ${aspirante.notas.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            
      // Nuestro botón flotante (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Por ahora solo mostramos un mensaje, luego aquí llamaremos a la cámara
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abriendo cámara OCR... (Próximamente)')),
          );
        },
        icon: const Icon(Icons.document_scanner),
        label: const Text('Escanear Notas'),
      ),
    );
  }
}