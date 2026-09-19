import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:udo_nvos_promedio_scanner/models/aspirante_record.dart';

class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notas_scanned.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabla NotasScanned según tus especificaciones
    await db.execute('''
    CREATE TABLE NotasScanned (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cedula INTEGER UNIQUE,
      notas TEXT,
      createdAt TEXT
    )
    ''');
  }

  Future<String> guardarOActualizarAspirante(AspiranteRecord nuevoEscaneo) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      'NotasScanned',
      where: 'cedula = ?',
      whereArgs: [nuevoEscaneo.cedula],
    );

    if (resultado.isNotEmpty) {

      print(resultado.first);

      final registroExistente = AspiranteRecord.fromMap(resultado.first);
      
      Map<int, List<int>> notasFusionadas = Map.from(registroExistente.notas);
      
      nuevoEscaneo.notas.forEach((anio, notasDelAnio) {
        notasFusionadas[anio] = notasDelAnio; 
      });

      final notasParaJson = notasFusionadas.map((key, value) => MapEntry(key.toString(), value));
      final notasString = jsonEncode(notasParaJson);

      await db.update(
        'NotasScanned',
        {
          'notas': notasString,
          'createdAt': DateTime.now().toIso8601String(), // Actualizamos la fecha para que salga de primero
        },
        where: 'cedula = ?',
        whereArgs: [nuevoEscaneo.cedula],
      );
      return ("Registro actualizado para la cédula ${nuevoEscaneo.cedula}");

    } else {
      final notasParaJson = nuevoEscaneo.notas.map((key, value) => MapEntry(key.toString(), value));
      
      await db.insert(
        'NotasScanned',
        {
          'cedula': nuevoEscaneo.cedula,
          'notas': jsonEncode(notasParaJson),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      return ("Nuevo registro insertado para la cédula ${nuevoEscaneo.cedula}");
    }
  }

  Future<List<AspiranteRecord>> obtenerTodos() async {
    final db = await instance.database;
    final result = await db.query('NotasScanned', orderBy: 'createdAt DESC');
    return result.map((json) => AspiranteRecord.fromMap(json)).toList();
  }

  Future<void> borrarTodo() async {

    final db = await instance.database;

    await db.delete(
      'NotasScanned',      
      where: '1 = 1',
    );

  }

  Future<void> borrarAspirante(int id) async {

    final db = await instance.database;

    await db.delete(
      'NotasScanned',      
      where: 'id = ?',
      whereArgs: [id],
    );

  }

}