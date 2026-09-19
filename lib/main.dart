import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';
import 'package:udo_nvos_promedio_scanner/providers/database.dart';

import 'helpers/escanear.dart';

void main() {
  runApp(const EscanerNotasApp());
}

String formatDate(DateTime date){
  return DateFormat.yMd().add_jm().format(date);
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
  List<AspiranteRecord> registrosEscaneados = [];

  bool _isScanning = false;

  Future<void> _cargarRegistrosDesdeBD() async {
    final datos = await DatabaseHelper.instance.obtenerTodos();
    setState(() {
      registrosEscaneados = datos;
    });
  }

  Future<void> escanearYGuardar(BuildContext context) async {
    setState(() {
      _isScanning = true;
    });

    try {
      final resultado = await irAEscanear();

      if (resultado['success'] == true) {
        AspiranteRecord aspirante = resultado['aspirante'];

        final String text = await DatabaseHelper.instance
            .guardarOActualizarAspirante(aspirante);

        await _cargarRegistrosDesdeBD();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      } else {
        final String text =
            resultado["msg"] ?? "No se pudo leer el documento correctamente.";

        final snackBar = SnackBar(content: Text(text));

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _confirmarLimpiarBaseDatos(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Base de Datos'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar TODOS los registros? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar Todo',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.borrarTodo();

      setState(() {
        registrosEscaneados = [];
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registros Eliminados')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 2. Al arrancar la pantalla, consultamos la BD
    _cargarRegistrosDesdeBD();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros Académicos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: registrosEscaneados.length,
            itemBuilder: (context, index) {
              final registro = registrosEscaneados[index];

              return Dismissible(
                key: Key(registro.id.toString()),
                direction: DismissDirection
                    .endToStart, 
                background: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ), 
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(
                      10,
                    ), 
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar eliminación'),
                        content: Text(
                          '¿Eliminar el registro de la cédula V-${registro.cedula}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },

                onDismissed: (direction) async {
                  final cedulaEliminada = registro.cedula;

                  await DatabaseHelper.instance.borrarAspirante(registro.id!);

                  setState(() {
                    registrosEscaneados.removeAt(index);
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registro V-$cedulaEliminada eliminado'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },

                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      'Cédula: V-${registro.cedula}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Registrado el ${ formatDate(registro.createdAt) }',
                    ), 
                    children: [
                      const Divider(),
                      ...registro.notas.entries.map((nota) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            'Nota de ${nota.key}° Año - Cant. ${nota.value.length} ',
                          ),
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
                ),
              );
            },
          ),
          if (_isScanning)
            Container(
              color: Colors.black.withValues(
                alpha: 0.5,
              ), 
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      floatingActionButton: _isScanning
          ? null
          : SpeedDial(
              icon: Icons.menu,
              activeIcon: Icons.close,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              overlayColor: Colors.black,
              overlayOpacity: 0.4,
              spacing: 12,
              spaceBetweenChildren: 8,

              children: [
                SpeedDialChild(
                  child: const Icon(Icons.upload, color: Colors.white),
                  backgroundColor: Colors.purple,
                  label: 'Subir Registros',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  onTap: () {
                    // _subirData();
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.share, color: Colors.white),
                  backgroundColor: Colors.green,
                  label: 'Exportar CSV',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  onTap: () {
                    // _exportarCSV();
                  },
                ),

                SpeedDialChild(
                  child: const Icon(Icons.delete_sweep, color: Colors.white),
                  backgroundColor: Colors.redAccent,
                  label: 'Limpiar Base de Datos',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  onTap: () {
                    _confirmarLimpiarBaseDatos(context);
                  },
                ),

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
