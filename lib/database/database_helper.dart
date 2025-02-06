import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        cycleTime INTEGER NOT NULL,
        remainingTime INTEGER NOT NULL,
        timeUnit TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task.id,
        'title': task.title,
        'cycleTime': task.cycleTime,
        'remainingTime': task.remainingTime,
        'timeUnit': task.timeUnit.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');

    return maps.map((map) {
      return Task(
        id: map['id'],
        title: map['title'],
        // HAXX: amountを逆に推定
        amount: map['cycleTime'] ~/
            (map['timeUnit'] == 'TimeUnit.hour' ? 60 : 1440),
        timeUnit:
            map['timeUnit'] == 'TimeUnit.hour' ? TimeUnit.hour : TimeUnit.day,
      )..remainingTime = map['remainingTime'];
    }).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'title': task.title,
        'cycleTime': task.cycleTime,
        'remainingTime': task.remainingTime,
        'timeUnit': task.timeUnit.toString(),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
